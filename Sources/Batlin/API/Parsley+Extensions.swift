import Parsley
import Files
import Foundation

public struct ParsleyMarkdownParser: StaticContentParser {
	public typealias Modifier = (String) -> String
	var preInputModifiers: [Modifier] = []

	public mutating func addPreInputModifier(modifier: @escaping Modifier) {
		preInputModifiers.append(modifier)
	}

	func parse(_ input: String) -> ParsedParselyOutput {
		do {
			var modifiedInput = input
			for modifier in preInputModifiers {
				modifiedInput = modifier(modifiedInput)
			}
			let parsed = try Parsley.parse(modifiedInput, options: [.hardBreaks, .unsafe])
			return .init(html: parsed.body, metadata: parsed.metadata, title: parsed.title)
		} catch {
			return ParsedParselyOutput(html: "", metadata: [:])
		}
	}
}

struct ParsedParselyOutput: ParsedStaticContent {
    var html: String

    var metadata: [String : String]

    var title: String?

}

internal struct ParsleyMarkdownContentFactory<Site: Website>: MarkdownContentFactory {
    typealias ParsedStaticContentType = ParsedParselyOutput
    let parser: ParsleyMarkdownParser
    let dateFormatter: DateFormatter

    func makeContent(fromFile file: File) throws -> Content {
        let markdown = try parser.parse(file.readAsString())
        let decoder = makeMetadataDecoder(for: markdown)
        return try makeContent(fromStaticContent: markdown, file: file, decoder: decoder)
    }

    func makeItem(fromFile file: File,
                  at path: Path,
                  sectionID: Site.SectionID) throws -> Item<Site> {
        let markdown = try parser.parse(file.readAsString())
        let decoder = makeMetadataDecoder(for: markdown)

        let metadata = try Site.ItemMetadata(from: decoder)
        let path = try decoder.decodeIfPresent("path", as: Path.self) ?? path
        let tags = try decoder.decodeIfPresent("tags", as: [Tag].self)
        let content = try makeContent(fromStaticContent: markdown, file: file, decoder: decoder)
        let rssProperties = try decoder.decodeIfPresent("rss", as: ItemRSSProperties.self)

        return Item(
            path: path,
            sectionID: sectionID,
            metadata: metadata,
            tags: tags ?? [],
            content: content,
            rssProperties: rssProperties ?? .init()
        )
    }

    func makePage(fromFile file: File, at path: Path) throws -> Page {
        let markdown = try parser.parse(file.readAsString())
        let decoder = makeMetadataDecoder(for: markdown)
        let content = try makeContent(fromStaticContent: markdown, file: file, decoder: decoder)
        return Page(path: path, content: content)
    }

}