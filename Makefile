
linux:
	flutter build linux --obfuscate --split-debug-info build/linux/x64/release/

windows:
	flutter build windows --obfuscate --split-debug-info build/windows/x64/x64/Release

.PHONY: linux windows