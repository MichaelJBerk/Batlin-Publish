import HighlightJS
import Ink
import Batlin

public extension Plugin {
    static func highlightJS() -> Self {
        Plugin(name: "HighlightJS") { context in
            context.markdownParser.addModifier(
                .highlightCodeBlocks()
            )
            context.parsleyParser.addPreInputModifier(modifier: parselyHighlightCodeBlocks(input:))
        }
    }
    
    fileprivate static func parselyHighlightCodeBlocks(input: String) -> String {
        var modifiedInput = input
        let highlighter = HighlightJS()
        do {
            let regex = try Regex(
                #"```[ \t]*([a-zA-Z0-9_-]*)\n([\s\S]*?)```"#,
                as: (Substring,Substring, Substring).self)
            modifiedInput = modifiedInput.replacing(regex) { match in
                let language = String(match.output.1)
                let entireMatch = String(match.output.0)
                guard language != "no-highlight" else {
                    return entireMatch
                }
                let contents = String(match.output.2)

                let highlighted = highlighter.highlight(contents, as: language)
                return String("<pre data-language=\"\(highlighted.language)\" class=\"hljs\"><code>\(highlighted.value)\n</code></pre>")
            }
        } catch {
            print(error)
        }

        return modifiedInput
    }
}

public extension Modifier {
    static func highlightCodeBlocks() -> Self {
        let highlighter = HighlightJS()

        return Self(target: .codeBlocks) { html, markdown in
            let begin = markdown.components(separatedBy: .newlines).first ?? "```"
            let language = begin.dropFirst("```".count)

            guard language != "no-highlight" else {
                return html
            }

            let code = markdown
                .dropFirst()
                .drop(while: { !$0.isNewline })
                .dropLast("\n```".count)

            let highlighted = highlighter.highlight(String(code),
                                                    as: String(language))
            return "<pre data-language=\"\(highlighted.language)\" class=\"hljs\"><code>\(highlighted.value)\n</code></pre>"
        }
    }
}
