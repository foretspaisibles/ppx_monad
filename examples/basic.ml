module List_monad = struct
  let return x = [x]
  let (>>=) t f = List.concat (List.map f t)
end

let output xs =
  print_endline
    (String.concat
       ", "
       (List.map string_of_int xs))

(* basic *)
let () =
  let open List_monad in
  output
    [%monad
      x <- [1; 2; 3];
      y <- [3; 4; 5];
      return (x + y) ]

(* begin ... end *)
let () =
  let open List_monad in
  output
    begin%monad
      x <- [1; 2; 3];
      y <- [3; 4; 5];
      return (x + y)
    end

(* fun *)
let () =
  let open List_monad in
  let f = fun%monad xs ys ->
    x <- xs;
    y <- ys;
    return (x + y)
  in
  output (f [1; 2; 3] [3; 4; 5])

(* function *)
let () =
  let open List_monad in
  let rec fibm = function%monad
    | 0 -> return 0
    | 1 -> return 1
    | n ->
      x <- fibm (n - 2);
      y <- fibm (n - 1);
      return (x + y)
  in
  output (fibm 10)

(* Toplevel let *)
module M = struct
  open List_monad

  let%monad f xs ys =
    x <- xs;
    y <- ys;
    return (x + y)

  let () =
    output (f [1; 2; 3] [3; 4; 5])
end
