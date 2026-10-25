# iOS tasks (AGENTS.md): setup, test, run, tokens, plus snapshots and catalog. Each runs non-interactively and fails loudly.
# Tests run on one simulator by name, so snapshot images stay comparable: SIMULATOR="iPhone 17" picks another.
# The simulator window is DeviceHub from Xcode 27 on (Simulator before).
# Recipes start with `set -euo pipefail`: macOS ships GNU make 3.81, which ignores .SHELLFLAGS.
SHELL := /bin/bash

PROJECT := Hutch.xcodeproj
SCHEME := Hutch
DERIVED := build
APP := $(DERIVED)/Build/Products/Debug-iphonesimulator/Hutch.app
SIMULATOR ?= iPhone 17 Pro

CATALOG_TOOLS := ../../tools/catalog-index

.PHONY: setup test run tokens snapshots catalog project lint

setup:
	@xcode-select -p >/dev/null || { echo "Xcode not found. Install it from the App Store, then run: sudo xcode-select -s /Applications/Xcode.app" >&2; exit 1; }
	@command -v xcodegen >/dev/null || { echo "XcodeGen not found. Install it with: brew install xcodegen" >&2; exit 1; }
	@xcodebuild -version | head -1
	@$(MAKE) --no-print-directory project

# Regenerates the project when project.yml or the source tree changes (XcodeGen's cache decides).
project:
	@xcodegen generate --use-cache --quiet

# App code uses tokens, never raw colors or sizes (apps/ios/DESIGN.md).
lint:
	@./lint.sh

test: project lint
	@swift tokens.swift --check
	@set -euo pipefail; \
	sim=$$(./simulator.sh "$(SIMULATOR)"); udid=$${sim%% *}; name=$${sim#* }; \
	echo "Testing on $$name ($$udid)"; \
	xcodebuild test -quiet -project $(PROJECT) -scheme $(SCHEME) -derivedDataPath $(DERIVED) \
		-destination "id=$$udid"; \
	echo "Tests passed on $$name"

# Re-records every snapshot image. Only on purpose, and say why in the PR (AGENTS.md).
snapshots: project
	@set -euo pipefail; \
	sim=$$(./simulator.sh "$(SIMULATOR)"); udid=$${sim%% *}; name=$${sim#* }; \
	echo "Recording snapshots on $$name ($$udid)"; \
	xcodebuild build-for-testing -quiet -project $(PROJECT) -scheme $(SCHEME) -derivedDataPath $(DERIVED) -destination "id=$$udid"; \
	TEST_RUNNER_SNAPSHOT_TESTING_RECORD=all xcodebuild test -quiet -project $(PROJECT) -scheme $(SCHEME) \
		-derivedDataPath $(DERIVED) -destination "id=$$udid" -only-testing:HutchTests || true; \
	echo "Recorded. Check the images in HutchTests/__Snapshots__, then run make test."

run: project
	@set -euo pipefail; \
	sim=$$(./simulator.sh "$(SIMULATOR)"); udid=$${sim%% *}; name=$${sim#* }; \
	echo "Running on $$name ($$udid)"; \
	xcodebuild build -quiet -project $(PROJECT) -scheme $(SCHEME) -derivedDataPath $(DERIVED) \
		-destination "id=$$udid"; \
	xcrun simctl boot "$$udid" 2>/dev/null || true; \
	open "$$(xcode-select -p)/../Applications/DeviceHub.app" 2>/dev/null || open -b com.apple.iphonesimulator 2>/dev/null \
		|| echo "(Couldn't open DeviceHub or Simulator; the app is running in the simulator anyway.)"; \
	xcrun simctl install "$$udid" $(APP); \
	xcrun simctl launch "$$udid" app.myhutch.ios

tokens:
	@swift tokens.swift

# Builds the product catalog and its Core ML image encoder into Hutch/Catalog/ (X5), then
# regenerates the project so the app bundles them. Not committed: about 100 MB, and the first
# run downloads SigLIP 2 (1.5 GB). Without it, the app works with Apple Intelligence alone.
catalog:
	@set -euo pipefail; \
	cd $(CATALOG_TOOLS); \
	[[ -x .venv/bin/python ]] || { python3 -m venv .venv && .venv/bin/python -m pip install -q -r requirements.txt; }; \
	TOKENIZERS_PARALLELISM=false .venv/bin/python -I build.py
	@xcodegen generate --quiet
