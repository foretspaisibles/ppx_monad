module List_monad = struct
  let return a = [a]
  let (>>=) t f = List.concat (List.map f t)
end

let () =
  let output a = Format.printf "%d@." a in
  let open List_monad in
  List.iter
    output
    [%monad
      a <- [1; 2; 3];
      b <- [3; 4; 5];
      return (a + b) ];
  List.iter
    output
    ((fun%monad () ->
        a <- [1; 2; 3];
        b <- [3; 4; 5];
        return (a + b)) ());
  List.iter
    output
    ((function%monad () ->
        a <- [1; 2; 3];
        b <- [3; 4; 5];
        return (a + b)) ());
  List.iter
    output
    (let%monad
      a, b = [1, 2; 3, 4] and
      c, d = [5, 6; 7, 8] in
     return (a * c + b * d))
