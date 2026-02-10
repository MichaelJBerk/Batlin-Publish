install:
	swift build -c release
	install .build/release/batlin-cli /usr/local/bin/batlin
