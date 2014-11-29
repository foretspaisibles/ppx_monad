# ppx_monad

ppx_monad is a monad syntax extension for OCaml, that provides two
major monad syntaxes: clean but incomplete Haskell-style monad syntax
and verbose but complete let monad syntax.

## Haskell-style monad syntax

To use this syntax, you need to wrap a sequence expression (i.e. `e1;
e2`) with `[%monad ...]` extension.

```OCaml
[%monad
  x <- [1; 2; 3];
  y <- [3; 4; 5];
  return (x + y) ]
```

`v <- e` binds a monadic value of `e` to a variable `v`.  Compared to
Haskell monad syntax, there is a serious limitation that you cannot
put a pattern in the place of `v`.

The following keywords also support sequence expressions in their
body.

* `begin`
* `fun`
* `function`
* Toplevel `let`

```OCaml
(* begin *)
begin%monad
  x <- [1; 2; 3];
  y <- [3; 4; 5];
  return (x + y)
end

(* fun *)
let f = fun%monad xs ys ->
  x <- xs;
  y <- ys;
  return (x + y)

(* function *)
let rec fibm = function%monad
  | 0 -> return 0
  | 1 -> return 1
  | n ->
    x <- fibm (n - 2);
    y <- fibm (n - 1);
    return (x + y)

(* Toplevel let *)
let%monad f xs ys =
  x <- xs;
  y <- ys;
  return (x + y)
```

The transformation rule is very natural as follows.

1. `e; ...` turns into `e >>= fun _ -> ...`
2. `v <- e; ...` turns into `e >>= fun v -> ...`

## Let monad syntax

This syntax is somewhat verbose than Haskell-style monad syntax but
complete: You can use patterns at the left hand side of `<-`.

To use this syntax, you need to wrap or annotate a `let` expression
with `[%monad ...]` extension.

Wrap version:

```OCaml
[%monad
  let a, b = [1, 2; 3, 4]
  and c, d = [5, 6; 7, 8]
  in return (a * c + b * d)]
```

Annotate version:

```OCaml
let%monad
  a, b = [1, 2; 3, 4] and
  c, d = [5, 6; 7, 8] in
return (a * c + b * d)
```

The transformation rule is trivial.

## License

MIT License
