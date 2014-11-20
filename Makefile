.PHONY: all
all: src/ppx_monad.native

.PHONY: test
test: examples/basic.byte
	examples/basic.byte

.PHONY: install
install: src/ppx_monad.native
	ocamlfind install ppx_monad META src/ppx_monad.native

.PHONY: uninstall
uninstall:
	ocamlfind remove ppx_monad

src/ppx_monad.native: src/ppx_monad.ml
	ocamlfind ocamlopt -package compiler-libs.common -linkpkg -o $@ $<

examples/basic.byte: examples/basic.ml src/ppx_monad.native
	ocamlc -ppx src/ppx_monad.native -o $@ $<
