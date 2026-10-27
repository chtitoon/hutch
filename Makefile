# Runs each app's tasks from the top of the repo (AGENTS.md).
.PHONY: setup test tokens ios-setup ios-test ios-run ios-tokens web-setup web-test web-run web-tokens

setup: ios-setup web-setup
test: ios-test web-test
tokens: ios-tokens web-tokens

ios-setup ios-test ios-run ios-tokens:
	@$(MAKE) --no-print-directory -C apps/ios $(@:ios-%=%)

web-setup web-test web-run web-tokens:
	@cd apps/web && npm run $(@:web-%=%)
