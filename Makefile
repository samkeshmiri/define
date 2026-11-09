PREFIX ?= $(HOME)/.local

.PHONY: build test install uninstall

build:
	swift build -c release

test:
	swift test

install: build
	install -d "$(PREFIX)/bin"
	install -m 755 .build/release/define "$(PREFIX)/bin/define"
	ln -sf define "$(PREFIX)/bin/define:"

uninstall:
	rm -f "$(PREFIX)/bin/define" "$(PREFIX)/bin/define:"
