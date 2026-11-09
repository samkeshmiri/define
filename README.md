# define

An offline macOS dictionary for the terminal, using Apple's installed dictionaries.
Written in Swift with no third-party dependencies.

## Install

Requires macOS 13+ and Swift 6+ (Xcode Command Line Tools).

```sh
git clone https://github.com/samkeshmiri/define.git
cd define
make install
```

Ensure `~/.local/bin` is on your `PATH`. In **Dictionary → Settings**, enable an
English dictionary and place it above thesauruses. Download it once if needed;
lookups then work offline.

## Usage

```sh
define snack
define: serendipity
define --all run
```

Example: `define: serendipity`

```text
serendipity
/ˌsɛr(ə)nˈdɪpɪti/

noun

  1. [mass noun] the occurrence and development of events by chance in a happy
     or beneficial way
     “a fortunate stroke of serendipity”
     “a series of small serendipities.”

Use --all for the complete dictionary entry.
```
