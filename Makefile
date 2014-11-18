.PHONY: all
all: src/ppx_monad.native

.PHONY: test
test: examples/basic.byte
	examples/basic.byte

src/ppx_monad.native: src/ppx_monad.ml
	ocamlfind ocamlopt -package compiler-libs.common -linkpkg -o $@ $<

examples/basic.byte: examples/basic.ml src/ppx_monad.native
	ocamlc -ppx src/ppx_monad.native -o $@ $<
