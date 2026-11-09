import Darwin
import Foundation

struct TerminalRenderer {
    let width: Int
    let colour: Bool

    static func current(noColour: Bool) -> TerminalRenderer {
        var size = winsize()
        let terminal = isatty(STDOUT_FILENO) != 0
        let hasSize = terminal && ioctl(STDOUT_FILENO, TIOCGWINSZ, &size) == 0 && size.ws_col > 0
        let env = ProcessInfo.processInfo.environment
        return TerminalRenderer(
            width: hasSize ? Int(size.ws_col) : 80,
            colour: terminal && !noColour && env["NO_COLOR"] == nil && env["TERM"] != "dumb"
        )
    }

    func render(_ entry: DictionaryEntry, query: String, all: Bool) -> String {
        let headword = entry.headword.isEmpty ? query : entry.headword
        var lines = [""] + wrapped(headword, indent: "", code: "1;36")
        if let pronunciation = entry.pronunciation {
            lines += wrapped("/\(pronunciation)/", indent: "", code: "2")
        }
        let comparableHeadword = entry.headword.replacingOccurrences(of: #" \d+$"#, with: "", options: .regularExpression)
        let parentEntry = !entry.headword.isEmpty
            && comparableHeadword.compare(query, options: [.caseInsensitive, .diacriticInsensitive]) != .orderedSame
        if parentEntry {
            lines += [""] + wrapped("Looked up “\(query)”; macOS returned this entry.", indent: "", code: "2")
        }
        if all || parentEntry || entry.sections.isEmpty {
            // Full mode retains every character of the source's body, including
            // secondary senses, phrase entries, usage notes and etymology.
            let body = entry.rawText.components(separatedBy: " | ").dropFirst(2).joined(separator: " | ")
            let content = body.isEmpty ? entry.rawText : body
            let paragraphs = DictionaryEntry.split(
                content,
                pattern: #"\s+(?=• |\d{1,2} |PHRASAL VERBS |PHRASES |DERIVATIVES |USAGE |ORIGIN )"#
            )
            for paragraph in paragraphs { lines += [""] + wrapped(paragraph, indent: "  ") }
        } else {
            for section in entry.sections {
                lines += ["", style(section.title, "1")]
                for (index, meaning) in section.meanings.prefix(3).enumerated() {
                    let prefix = "  \(index + 1). "
                    lines += [""] + wrapped(meaning.text, indent: prefix, continuation: String(repeating: " ", count: prefix.count))
                    if meaning.examples.isEmpty {
                        lines += wrapped("No example supplied by the dictionary.", indent: "     ", code: "2")
                    } else {
                        for example in meaning.examples {
                            lines += wrapped("“\(example)”", indent: "     ", code: "2")
                        }
                    }
                }
            }
            lines += [""] + wrapped("Use --all for the complete dictionary entry.", indent: "", code: "2")
        }
        lines += [""]
        return lines.joined(separator: "\n")
    }

    func wrapped(_ text: String, indent: String, continuation: String? = nil, code: String? = nil) -> [String] {
        let nextIndent = continuation ?? indent
        // Retain useful content on very narrow terminals, reducing indentation.
        let firstIndent = String(indent.prefix(max(0, width - 2)))
        let restIndent = String(nextIndent.prefix(max(0, width - 2)))
        var prefix = firstIndent
        var line = ""
        var result: [String] = []
        for word in text.split(whereSeparator: { $0.isWhitespace }) {
            var remaining = String(word)
            if !line.isEmpty, prefix.count + line.count + 1 + remaining.count > width {
                result.append(prefix + line)
                prefix = restIndent
                line = ""
            }
            // Long words must wrap too; never lose text at the right edge.
            while remaining.count > max(1, width - prefix.count) {
                let count = max(1, width - prefix.count)
                result.append(prefix + remaining.prefix(count))
                remaining.removeFirst(count)
                prefix = restIndent
            }
            line += (line.isEmpty ? "" : " ") + remaining
        }
        if !line.isEmpty { result.append(prefix + line) }
        return result.map { line in
            guard let code else { return line }
            return style(line, code)
        }
    }

    private func style(_ text: String, _ code: String) -> String {
        colour ? "\u{001B}[\(code)m\(text)\u{001B}[0m" : text
    }
}
