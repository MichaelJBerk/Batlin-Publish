import Files
import CollectionConcurrencyKit

internal struct TextbundleFileHandler<Site: Website> {
    func addTextbundles(
        in folder: Folder,
        to context: inout PublishingContext<Site>,
        targetFolderPath: Path? = nil
    ) async throws {
        let factory = context.makeTextbundleContentFactory(context: context, targetFolderPath: targetFolderPath)

        if let indexBundle = try? folder.subfolder(named: "index.textbundle") {
            do {
                context.index.content = try factory.makeIndex(fromFile: indexBundle, path: context.index.path)
            } catch {
                throw self.wrap(error, forPath: "\(folder.path)index.textbundle")
            }
        }

        let folderResults: [FolderResult] = try await folder.subfolders.concurrentMap { subfolder in
            guard let sectionID = Site.SectionID(rawValue: subfolder.name.lowercased()) else {
                return try await .pages(makePagesForTextbundles(
                    inFolder: subfolder,
                    recursively: true,
                    parentPath: Path(subfolder.name),
                    factory: factory
                ))
            }

            var sectionContent: Content?
            var sectionIndexAssets: Folder?
            
            let items: [Item<Site>] = try await subfolder.subfolders.recursive.concurrentCompactMap { subfolder2 in
                guard subfolder2.isTextbundle else { return nil }

                if subfolder2.nameExcludingExtension == "index", subfolder2.parent == subfolder {
                    sectionContent = try factory.makeContent(fromFile: subfolder2)
                    sectionIndexAssets = try? subfolder2.subfolder(named: "assets")
                    return nil
                }

                do {
                    let fileName = subfolder2.nameExcludingExtension
                    let path: Path

                    if let parentPath = subfolder2.parent?.path(relativeTo: subfolder) {
                        path = Path(parentPath).appendingComponent(fileName)
                    } else {
                        path = Path(fileName)
                    }

                    return try factory.makeItem(
                        fromFile: subfolder2,
                        at: path,
                        sectionID: sectionID
                    )
                } catch {
                    let path = Path(subfolder2.path(relativeTo: folder))
                    throw wrap(error, forPath: path)
                }
            }

            return .section(id: sectionID, content: sectionContent, assets: sectionIndexAssets, items: items)
        }

        for result in folderResults {
            switch result {
            case .pages(let pages):
                for page in pages {
                    context.addPage(page)
                }
            case .section(let id, let content, let assets, let items):
                if let content = content {
                    context.sections[id].content = content
                }

                for item in items {
                    context.addItem(item)
                }
                if let assets {
                    let sectionPath = context.sections[id].path
                    var outputPath: Path?
                    if let targetFolderPath {
                        outputPath = targetFolderPath.appendingComponent(sectionPath.string)
                    } else {
                        outputPath = sectionPath
                    }
                    try context.copyFolderToOutput(assets, targetFolderPath: outputPath)

                }
            }
        }

        let rootPages = try await makePagesForTextbundles(
            inFolder: folder,
            recursively: false,
            parentPath: "",
            factory: factory
        )

        for page in rootPages {
            context.addPage(page)
        }
    }
}

private extension TextbundleFileHandler {
    enum FolderResult {
        case pages([Page])
        case section(id: Site.SectionID, content: Content?, assets: Folder?, items: [Item<Site>])
    }

    func makePagesForTextbundles(
        inFolder folder: Folder,
        recursively: Bool,
        parentPath: Path,
        factory: TextbundleContentFactory<Site>
    ) async throws -> [Page] {
        let pages: [Page] = try await folder.subfolders.concurrentCompactMap { subfolder in
            guard subfolder.isTextbundle else { return nil }

            if subfolder.nameExcludingExtension == "index", !recursively {
                return nil
            }

            let pagePath = parentPath.appendingComponent(subfolder.nameExcludingExtension)
            return try factory.makePage(fromFile: subfolder, at: pagePath)
        }

        guard recursively else {
            return pages
        }

        return try await pages + folder.subfolders.concurrentFlatMap { subfolder -> [Page] in
            let parentPath = parentPath.appendingComponent(subfolder.name)

            return try await makePagesForTextbundles(
                inFolder: subfolder,
                recursively: true,
                parentPath: parentPath,
                factory: factory
            )
        }
    }

    func wrap(_ error: Error, forPath path: Path) -> Error {
        if error is FilesError<ReadErrorReason> {
            return FileIOError(path: path, reason: .fileCouldNotBeRead)
        } else if let error = error as? DecodingError {
            switch error {
            case .keyNotFound(_, let context),
                 .valueNotFound(_, let context):
                return ContentError(
                    path: path,
                    reason: .markdownMetadataDecodingFailed(
                        context: context,
                        valueFound: false
                    )
                )
            case .typeMismatch(_, let context),
                 .dataCorrupted(let context):
                return ContentError(
                    path: path,
                    reason: .markdownMetadataDecodingFailed(
                        context: context,
                        valueFound: true
                    )
                )
            @unknown default:
                return ContentError(
                    path: path,
                    reason: .markdownMetadataDecodingFailed(
                        context: nil,
                        valueFound: true
                    )
                )
            }
        } else {
            return error
        }
    }
}

private extension Folder {
    private static let textbundleExtensions: Set<String> = [
        "textbundle"
    ]

    var isTextbundle: Bool {
        self.extension.map(Folder.textbundleExtensions.contains) ?? false
    }
}
