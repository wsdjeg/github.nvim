.PHONY: test test-all test-verbose clean install-deps help

# Default target
help:
	@echo "Available targets:"
	@echo "  test            - Run all tests (or specific tests with PATTERN=...)"
	@echo "  clean           - Clean test cache files"
	@echo "  install-deps    - Download test dependencies (luaunit)"
	@echo ""
	@echo "Examples:"
	@echo "  make test                               # Run all tests"
	@echo "  make test PATTERN=issues                # Match test/**/*issues*_spec.lua"
	@echo "  make test PATTERN=test/util_spec.lua    # Full path"

# Install all test dependencies (cross-platform, uses Lua)
install-deps:
	@nvim --headless -c "lua dofile('test/install_deps.lua')" -c "qa!"

# Run tests with nvim headless
# Supports PATTERN parameter to run specific test file(s)
test: install-deps
	@echo "Running tests with nvim --headless..."
	@nvim --headless -u test/minimal_init.lua \
		-c "lua _G.TEST_PATTERN = '$(PATTERN)'" \
		-c "lua dofile('test/run.lua')" \
		-c "qa!"

# Clean generated files
clean:
	@echo "Cleaning up..."
	@rm -rf test/.deps
	@rm -rf test/*.lua~
	@rm -rf test/*.out
	@rm -rf *.swp

