MINTRUN = mint run
SWIFTFORMAT = $(MINTRUN) swiftformat
DGRAPH = $(MINTRUN) swift-dependencies-graph dgraph
LICENSE = $(MINTRUN) licensecli

.PHONY: setup
setup:
	brew install mint
	mint bootstrap

.PHONY: format
format:
	$(SWIFTFORMAT) .

.PHONY: dgraph
dgraph:
	$(DGRAPH) ./Packages/TaskTree

.PHONY: license
license:
	$(LICENSE) ./Packages/TaskTree/ ./Packages/TaskTree/Sources/Generated/

