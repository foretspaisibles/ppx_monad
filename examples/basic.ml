module List_monad = struct
  let return a = [a]
  let bind t f = List.concat (List.map f t)
end

let () =
  let result =
    let open List_monad in
    begin%monad
      a <-- [1; 2; 3];
      b <-- [3; 4; 5];
      return (a + b)
    end
  in
  List.iter
    (fun a -> Format.printf "%d@." a)
    result
