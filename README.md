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
* `match`
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
  let z = x + y in
  return z

(* function *)
let rec fibm = function%monad
  | 0 -> return 0
  | 1 -> return 1
  | n ->
    x <- fibm (n - 2);
    y <- fibm (n - 1);
    return (x + y)

(* match *)
let rec fibm n = match%monad n with
  | 0 -> return 0
  | 1 -> return 1
  | _ ->
    x <- fibm (n - 2);
    y <- fibm (n - 1);
    return (x + y)

(* Toplevel let *)
let%monad f xs ys =
  let open List in
  x <- xs;
  y <- ys;
  return (x + y)
```

The transformation function `f` transform sequence expressions as
follows:

1. `e0; e1` to `e0 >>= fun _ -> e1'` where `e1'` = `f e1`
2. `v <- e0; e1` to `e >>= fun v -> e1'` where `e1'` = `f e1`
3. `let ... in e` to `let ... in e'` where `e'` = `f e`

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

## Shorthand for local open

You can use arbitrary monad modules without `open ...` or `let open
... in`, by appending monad module name after `%monad`.

For example, the following code

```OCaml
begin%monad.List
  x <- [1; 2; 3];
  y <- [3; 4; 5];
  return (x + y)
end
```

will be tranformed into

```OCaml
let (>>=) = List.(>>=)
and return = List.return
in
[1; 2; 3]
>>= fun x -> [3; 4; 5]
>>= fun y -> return (x + y)
```

## Examples

See `examples` directory.

## License

MIT License
