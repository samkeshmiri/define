import CoreServices.DictionaryServices
import Foundation

struct DictionaryEntry {
    struct Meaning {
        let text: String
        let examples: [String]
    }

    struct Section {
        let title: String
        let meanings: [Meaning]
    }

    let headword: String
    let pronunciation: String?
    let sections: [Section]
    let rawText: String

    static func lookup(_ query: String) -> DictionaryEntry? {
        let text = query as CFString
        let range = CFRange(location: 0, length: CFStringGetLength(text))
        guard let definition = DCSCopyTextDefinition(nil, text, range)?.takeRetainedValue() else {
            return nil
        }
        return DictionaryEntry(definition as String)
    }

    init(_ raw: String) {
        rawText = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        // Apple exposes plain text, not a structured entry. Only split recognised
        // Oxford separators; keep the original text available if parsing fails.
        let header = rawText.components(separatedBy: " | ")
        guard header.count >= 3 else {
            headword = ""
            pronunciation = nil
            sections = []
            return
        }
        headword = header[0]
        pronunciation = header[1]
        let body = header.dropFirst(2).joined(separator: " | ")
        let notePattern = #" (?=PHRASAL VERBS |PHRASES |DERIVATIVES |USAGE |ORIGIN )"#
        let parts = Self.split(body, pattern: notePattern)
        let grammar = #"noun|verb|adjective|adverb|pronoun|preposition|conjunction|exclamation|interjection|determiner|article|prefix|suffix|combining form|abbreviation"#
        let pattern = #"(?<!\S)(?:"# + grammar + #")(?=\s)"#
        let text = parts[0]
        let regex = try! NSRegularExpression(pattern: pattern)
        let matches = regex.matches(in: text, range: NSRange(text.startIndex..., in: text)).filter {
            guard let range = Range($0.range, in: text) else { return false }
            let prefix = text[..<range.lowerBound]
            // Grammar labels inside bracketed usage notes are not new sections.
            return prefix.filter { $0 == "(" }.count == prefix.filter { $0 == ")" }.count
                && prefix.filter { $0 == "[" }.count == prefix.filter { $0 == "]" }.count
                && (prefix.trimmingCharacters(in: .whitespaces).hasSuffix(".")
                    || prefix.range(of: #"^(?:\([^)]*\)\s*)*$"#, options: .regularExpression) != nil)
        }
        sections = matches.enumerated().compactMap { index, match in
            guard let titleRange = Range(match.range, in: text) else { return nil }
            let end = index + 1 < matches.count
                ? Range(matches[index + 1].range, in: text)!.lowerBound : text.endIndex
            let content = String(text[titleRange.upperBound..<end]).trimmed
            guard !content.isEmpty else { return nil }
            // Sense numbers follow a sentence boundary. Numbers within examples
            // ("ran 42 marathons", "increased by 2 per cent") are ordinary text.
            let chunks = Self.split(content, pattern: #"(?<=\.)\s+(?=\d{1,2}\s)"#)
            let meanings = chunks.map { chunk in
                let primary = chunk.components(separatedBy: " • ")[0]
                    .replacingOccurrences(of: #"^((?:(?:\([^)]*\)|\[[^\]]*\])\s*)*)\d{1,2}\s+"#, with: "$1", options: .regularExpression)
                guard let separator = primary.range(of: ": ") else {
                    return Meaning(text: primary, examples: [])
                }
                return Meaning(
                    text: String(primary[..<separator.lowerBound]),
                    examples: String(primary[separator.upperBound...]).components(separatedBy: " | ").map {
                        // Usage labels are metadata, not part of the quoted example.
                        $0.replacingOccurrences(
                            of: #"^(?:(?:\[[^\]]*\]|\([^)]*\))\s*:?\s*|:\s*)+"#,
                            with: "", options: .regularExpression
                        )
                    }.filter { !$0.isEmpty }
                )
            }
            return Section(title: String(text[titleRange]), meanings: meanings)
        }
    }

    static func split(_ text: String, pattern: String) -> [String] {
        let regex = try! NSRegularExpression(pattern: pattern)
        var start = text.startIndex
        var parts: [String] = []
        for match in regex.matches(in: text, range: NSRange(text.startIndex..., in: text)) {
            let range = Range(match.range, in: text)!
            parts.append(String(text[start..<range.lowerBound]).trimmed)
            start = range.upperBound
        }
        parts.append(String(text[start...]).trimmed)
        return parts
    }
}

extension String {
    var trimmed: String { trimmingCharacters(in: .whitespacesAndNewlines) }
}
