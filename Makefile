LINUX_BUILD_DIR := build/linux
LINUX_BUNDLE_DIR := ${LINUX_BUILD_DIR}/x64/release/bundle

linux:
	flutter build linux --obfuscate --split-debug-info ${LINUX_BUILD_DIR}/x64/release/

appimage: ${LINUX_BUILD_DIR}/Flow.AppImage

${LINUX_BUILD_DIR}/Flow.AppImage: ${LINUX_BUNDLE_DIR}/flow ${LINUX_BUNDLE_DIR}/lib/libapp.so
	@rm -rf -- ${LINUX_BUILD_DIR}/Flow.AppDir
	@cp -r linux/Flow.AppDir ${LINUX_BUILD_DIR}
	@cp -r ${LINUX_BUNDLE_DIR} ${LINUX_BUILD_DIR}/Flow.AppDir
	@appimagetool ${LINUX_BUILD_DIR}/Flow.AppDir/ $@

windows:
	flutter build windows --obfuscate --split-debug-info build/windows/x64/x64/Release

.PHONY: linux windows
