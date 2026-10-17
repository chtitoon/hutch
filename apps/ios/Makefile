# iOS tasks (AGENTS.md): setup, test, run, tokens. Each runs non-interactively and fails loudly.
# Pick a simulator by name with SIMULATOR="iPhone 17"; by default a booted iPhone, else the first available.
# Recipes start with `set -euo pipefail`: macOS ships GNU make 3.81, which ignores .SHELLFLAGS.
SHELL := /bin/bash

PROJECT := Hutch.xcodeproj
SCHEME := Hutch
DERIVED := build
APP := $(DERIVED)/Build/Products/Debug-iphonesimulator/Hutch.app
SIMULATOR ?=

.PHONY: setup test run tokens project

setup:
	@xcode-select -p >/dev/null || { echo "Xcode not found. Install it from the App Store, then run: sudo xcode-select -s /Applications/Xcode.app" >&2; exit 1; }
	@command -v xcodegen >/dev/null || { echo "XcodeGen not found. Install it with: brew install xcodegen" >&2; exit 1; }
	@xcodebuild -version | head -1
	@$(MAKE) --no-print-directory project

# Regenerates the project when project.yml or the source tree changes (XcodeGen's cache decides).
project:
	@xcodegen generate --use-cache --quiet

test: project
	@swift tokens.swift --check
	@set -euo pipefail; \
	sim=$$(./simulator.sh "$(SIMULATOR)"); udid=$${sim%% *}; name=$${sim#* }; \
	echo "Testing on $$name ($$udid)"; \
	xcodebuild test -quiet -project $(PROJECT) -scheme $(SCHEME) -derivedDataPath $(DERIVED) \
		-destination "id=$$udid"; \
	echo "Tests passed on $$name"

run: project
	@set -euo pipefail; \
	sim=$$(./simulator.sh "$(SIMULATOR)"); udid=$${sim%% *}; name=$${sim#* }; \
	echo "Running on $$name ($$udid)"; \
	xcodebuild build -quiet -project $(PROJECT) -scheme $(SCHEME) -derivedDataPath $(DERIVED) \
		-destination "id=$$udid"; \
	xcrun simctl boot "$$udid" 2>/dev/null || true; \
	open -b com.apple.iphonesimulator 2>/dev/null || echo "(Couldn't open the Simulator window; the app is running in the simulator anyway.)"; \
	xcrun simctl install "$$udid" $(APP); \
	xcrun simctl launch "$$udid" app.myhutch.ios

tokens:
	@swift tokens.swift
