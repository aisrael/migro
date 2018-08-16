CRYSTAL_BIN ?= $(shell which crystal)
SHARDS_BIN ?= $(shell which shards)
PREFIX ?= /usr/local
SHARD_BIN ?= ../../bin

build:
	$(SHARDS_BIN) build $(CRFLAGS)
clean:
	rm -f ./bin/migro ./bin/migro.dwarf
install: build
	mkdir -p $(PREFIX)/bin
	cp ./bin/migro $(PREFIX)/bin
bin: build
	mkdir -p $(SHARD_BIN)
	cp ./bin/migro $(SHARD_BIN)
test: build
	$(CRYSTAL_BIN) spec
	./bin/migro
