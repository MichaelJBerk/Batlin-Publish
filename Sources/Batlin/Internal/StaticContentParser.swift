import Ink

///Protocol adopted by types that can parse content used for a website
protocol StaticContentParser {
	///The type of `ParsedStaticContent` that will be produced by this object 
	associatedtype ParsedStaticContentType: ParsedStaticContent
	//Parse a string into a ParsedStaticContent value, which contains both the HTML representation of the given string, and also any metadata values found within it.
	func parse(_ input: String) -> ParsedStaticContentType
	///Convert a string into HTML, discarding any metadata found in the process. To preserve the metadata, use the parse method instead.
	func html(from input: String) -> String
}

extension StaticContentParser {
	func html(from input: String) -> String {
		parse(input).html
	}
}

///A value containing content parsed for a site, containing the rendered HTML, as well as any metadata found in the document.
protocol ParsedStaticContent {
	///The HTML representation of the content, ready to be rendered in a web browser.
	var html: String { get }
	//TODO: Update README
	///Any metadata values found within the document. See this project’s README for more information.
	var metadata: [String: String] { get }
	//The inferred title of the document found when parsing.
	var title: String? { get }
}

extension Ink.Markdown: ParsedStaticContent {}
extension Ink.MarkdownParser : StaticContentParser {}