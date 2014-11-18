# ppx_monad

ppx_monad is Haskell-style monad syntax extension for OCaml.

With ppx_monad, sequence expressions (i.e. `e1; e2`) with
`[%monad ...]` extension will be transformed according to the
following rules:

1. `e; ...` turns into `bind e (fun _ -> ...)`
2. `v <-- e; ...` turns into `bind e (fun v -> ...)`

For example, the following expression

```OCaml
[%monad a <- f (); g a]
```

will be transformed into

```OCaml
bind (f ()) (fun a -> g a)
```

OCaml keywords below with `%monad` extension will also be transformed
in a natural manner.

* `begin`

## Example

In a list monad, the following code

```OCaml
begin%monad
  a <-- [1; 2; 3];
  b <-- [3; 4; 5];
  return (a + b)
end
```

outputs

```
4
5
6
5
6
7
6
7
8
```

## License

MIT License
