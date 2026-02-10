import Foundation
import Files

internal struct TextbundleContentFactory<Site: Website>: MarkdownContentFactory {
	internal init(
		parser: ParsleyMarkdownParser, 
		dateFormatter: DateFormatter,
		context: PublishingContext<Site>,
		targetFolderPath: Path? = nil
	) {
		self.parser = parser
		self.dateFormatter = dateFormatter
		self.context = context
		self.targetFolderPath = targetFolderPath
		self.parselyFactory = .init(parser: parser, dateFormatter: dateFormatter)
	}

	typealias ParsedStaticContentType = ParsedParselyOutput
    let parser: ParsleyMarkdownParser
    let dateFormatter: DateFormatter
	var context: PublishingContext<Site>
	var targetFolderPath: Path?
	var parselyFactory: ParsleyMarkdownContentFactory<Site>

	func makeIndex(fromFile folder: Folder, path: Path?) throws -> Content {
		let output = try makeContent(fromFile: folder)
		if let assetsFolder = try? folder.subfolder(named: "assets"){
			var outputPath: Path?
			if let targetFolderPath{
				outputPath = targetFolderPath
				if let path {
					outputPath = outputPath?.appendingComponent(path.string)
				}
			} else {
				outputPath = path
			}
			try context.copyFolderToOutput(assetsFolder, targetFolderPath: outputPath)
		}
		return output
	}
	func makeContent(fromFile folder: Folder) throws -> Content {
		let file = try folder.file(named: "text.md")
		return try parselyFactory.makeContent(fromFile: file)
	}
	func makeItem(fromFile folder: Folder, at path: Path, sectionID: Site.SectionID) throws -> Item<Site> {
		let file = try folder.file(named: "text.md")
		let output = try parselyFactory.makeItem(fromFile: file, at: path, sectionID: sectionID)
		if let assetsFolder = try? folder.subfolder(named: "assets") {
			try context.copyFolderToOutput(assetsFolder, targetFolderPath: targetFolderPath?.appendingComponent(output.path.string) ?? output.path)
		}
		return output
	}
	func makePage(fromFile folder: Folder, at path: Path) throws -> Page {
		let file = try folder.file(named: "text.md")
		let output = try parselyFactory.makePage(fromFile: file, at: path)
		if let assetsFolder = try? folder.subfolder(named: "assets") {
			try context.copyFolderToOutput(assetsFolder, targetFolderPath: targetFolderPath?.appendingComponent(output.path.string) ?? output.path)
		}
		return output
	}
}