import Testing
@testable import Define

struct DefineTests {
    // Synthetic fixtures model the plain-text layout returned by Oxford on macOS.
    let fixture = """
    nibble | ˈnɪb(ə)l | noun 1 a small bite: she took a nibble | a second nibble. • a small portion: a nibble of cake. 2 a tentative interest: the offer attracted a nibble. verb [with object] 1 bite gently: the rabbit nibbled a leaf. • consume gradually: nibble at the budget. 2 eat small amounts: he nibbled 2 biscuits. ORIGIN A synthetic origin note.
    """

    @Test func separatesDefinitionsExamplesAndPartsOfSpeech() {
        let entry = DictionaryEntry(fixture)
        #expect(entry.headword == "nibble")
        #expect(entry.pronunciation == "ˈnɪb(ə)l")
        #expect(entry.sections.map(\.title) == ["noun", "verb"])
        #expect(entry.sections[0].meanings.count == 2)
        #expect(entry.sections[0].meanings[0].text == "a small bite")
        #expect(entry.sections[0].meanings[0].examples == ["she took a nibble", "a second nibble."])
        #expect(entry.sections[1].meanings[1].examples == ["he nibbled 2 biscuits."])
    }

    @Test func grammarNotesAndNumbersDoNotCreateFalseSectionsOrSenses() {
        let entry = DictionaryEntry("test | tɛst | noun [mass noun] a description of a verb: a test of 42 items. 2 another meaning: 2 items in a test.")
        #expect(entry.sections.count == 1)
        #expect(entry.sections[0].meanings.count == 2)
        #expect(entry.sections[0].meanings[0].text == "[mass noun] a description of a verb")
        #expect(entry.sections[0].meanings[0].examples == ["a test of 42 items."])
    }

    @Test func missingExampleIsExplicit() {
        let entry = DictionaryEntry("cafe | ˈkafeɪ | (also café) noun a small restaurant.")
        let output = TerminalRenderer(width: 80, colour: false).render(entry, query: "café", all: false)
        #expect(output.contains("No example supplied by the dictionary."))
        #expect(!output.contains("macOS returned"))
    }

    @Test func grammarLabelsStayOutsideExampleQuotes() {
        let entry = DictionaryEntry("chance | tʃɑːns | noun a possibility: a small chance | [count noun] : two chances | (as modifier) : chance encounters.")
        #expect(entry.sections[0].meanings[0].examples == ["a small chance", "two chances", "chance encounters."])
    }

    @Test func fullEntryPreservesSecondarySensesAndOrigin() {
        let entry = DictionaryEntry(fixture)
        let output = TerminalRenderer(width: 80, colour: false).render(entry, query: "nibble", all: true)
        let words = { (text: String) in text.split(whereSeparator: \.isWhitespace).map(String.init) }
        #expect(output.contains("• a small portion"))
        #expect(output.contains("ORIGIN A synthetic origin note."))
        #expect(words(output).dropFirst(2) == words(fixture).dropFirst(4))
    }

    @Test func unrecognisedFormatFallsBackWithoutLosingText() {
        let raw = "An unfamiliar dictionary format: an example, without pronunciation."
        let output = TerminalRenderer(width: 80, colour: false).render(DictionaryEntry(raw), query: "word", all: false)
        #expect(output.contains(raw))
    }

    @Test func phraseReturningParentEntryShowsFullContent() {
        let raw = "ice | ʌɪs | noun frozen water. PHRASES break the ice start a conversation. ORIGIN An origin note."
        let output = TerminalRenderer(width: 80, colour: false).render(DictionaryEntry(raw), query: "break the ice", all: false)
        #expect(output.contains("macOS returned this entry"))
        #expect(output.contains("break the ice start a conversation."))
    }

    @Test func compactViewHasLimitAndFullViewKeepsRemainingSenses() {
        let entry = DictionaryEntry("word | wɜːd | noun 1 first. 2 second. 3 third. 4 fourth.")
        let renderer = TerminalRenderer(width: 80, colour: false)
        #expect(!renderer.render(entry, query: "word", all: false).contains("fourth"))
        #expect(renderer.render(entry, query: "word", all: true).contains("fourth"))
    }

    @Test func narrowTerminalRetainsWordsAndWrapsLongTokens() {
        let renderer = TerminalRenderer(width: 20, colour: false)
        let text = "an extraordinarilylongunbrokenword followed by café"
        let lines = renderer.wrapped(text, indent: "  ")
        #expect(lines.allSatisfy { $0.count <= 20 })
        #expect(lines.joined().filter { !$0.isWhitespace } == text.filter { !$0.isWhitespace })
    }

    @Test func optionsSupportPhrasesAndLiteralFlags() throws {
        let phrase = try Options(["break", "the", "ice"])
        let all = try Options(["--all", "snack"])
        let literal = try Options(["--", "--all"])
        let help = try Options(["--help"])
        #expect(phrase.query == "break the ice")
        #expect(all.all)
        #expect(!literal.all)
        #expect(literal.query == "--all")
        #expect(help.help)
        #expect(throws: UsageError.self) { _ = try Options([]) }
        #expect(throws: UsageError.self) { _ = try Options(["--unknown"]) }
        #expect(throws: UsageError.self) { _ = try Options(["snack\u{001B}[31m"]) }
    }
}
