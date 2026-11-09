import Darwin
import Foundation

struct Options {
    var all = false
    var noColour = false
    var help = false
    var query = ""

    init(_ arguments: [String]) throws {
        var words: [String] = []
        var flags = true
        for argument in arguments {
            switch argument {
            case "--" where flags: flags = false
            case "--all" where flags, "-a" where flags: all = true
            case "--no-color" where flags: noColour = true
            case "--help" where flags, "-h" where flags: help = true
            default:
                if flags && argument.hasPrefix("-") {
                    throw UsageError(message: "Unknown option: \(argument)")
                }
                words.append(argument)
            }
        }
        query = words.joined(separator: " ").trimmed
        guard !query.unicodeScalars.contains(where: { CharacterSet.controlCharacters.contains($0) }) else {
            throw UsageError(message: "The lookup must not contain control characters.")
        }
        if query.isEmpty && !help { throw UsageError(message: "Please provide a word or phrase.") }
    }
}

struct UsageError: Error {
    let message: String
}

@main
enum DefineCommand {
    static let help = """
    Usage: define [--all] [--no-color] <word or phrase>
           define: [--all] [--no-color] <word or phrase>

    Look up a word using macOS's installed dictionaries, entirely offline.

      -a, --all      Show the complete entry, including secondary meanings.
      --no-color     Disable terminal colours (also respects NO_COLOR).
      -h, --help     Show this help.
      --            Treat remaining arguments as the lookup text.

    Examples:
      define snack
      define: serendipity
      define --all run
      define "break the ice"

    Setup: in Dictionary > Settings, enable an English dictionary and drag
    it above thesauruses. Downloaded dictionaries work offline. macOS may
    return a parent entry for phrases; these are shown in full.
    """

    static func main() {
        do {
            let options = try Options(Array(CommandLine.arguments.dropFirst()))
            if options.help { print(help); return }
            guard let entry = DictionaryEntry.lookup(options.query) else {
                fail("No local definition found for “\(options.query)”.\nIf common words also fail, check Dictionary > Settings and run outside a restricted sandbox.", code: 1)
            }
            print(TerminalRenderer.current(noColour: options.noColour).render(entry, query: options.query, all: options.all))
        } catch let error as UsageError {
            fail("\(error.message)\nUsage: define [--all] <word or phrase>\nTry 'define --help' for details.", code: 2)
        } catch {
            fail(error.localizedDescription, code: 1)
        }
    }

    private static func fail(_ message: String, code: Int32) -> Never {
        FileHandle.standardError.write(Data((message + "\n").utf8))
        exit(code)
    }
}
