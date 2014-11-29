.PHONY: all
all: src/ppx_monad.native

.PHONY: test
test: run-examples

.PHONY: run-examples
run-examples: src/ppx_monad.native
	ocaml -ppx src/ppx_monad.native examples/basic.ml

.PHONY: install
install: src/ppx_monad.native
	ocamlfind install ppx_monad META src/ppx_monad.native

.PHONY: uninstall
uninstall:
	ocamlfind remove ppx_monad

src/ppx_monad.native: src/ppx_monad.ml
	ocamlfind ocamlopt -package compiler-libs.common -linkpkg -o $@ $<
