module Option = struct
  let map f = function
    | None -> None
    | Some a -> Some (f a)
end

let mapper _args =
  let open Asttypes in
  let open Parsetree in
  let open Longident in
  let open Ast_mapper in
  let open Ast_helper in
  let bind_exp = (Exp.ident { txt = Lident ">>="; loc = Location.none }) in
  let super = default_mapper in
  let rec compile_sequence this e = match e.pexp_desc with
    | Pexp_sequence ({ pexp_desc = Pexp_setinstvar (var, e1) }, e2) ->
      Exp.apply
        bind_exp
        ["", e1; "", Exp.fun_ "" None (Pat.var var) (compile_sequence this e2)]
    | Pexp_sequence (e1, e2) ->
      Exp.apply
        bind_exp
        ["", e1; "", Exp.fun_ "" None (Pat.any ()) (compile_sequence this e2)]
    | _ ->
      this.expr this e
  in
  { super with
    expr =
      (fun this e ->
         match e.pexp_desc with
         | Pexp_extension ({ txt = "monad" }, PStr [{ pstr_desc = Pstr_eval (e, _) }]) ->
           begin match e.pexp_desc with
             | Pexp_sequence _ ->
               compile_sequence this e
             | Pexp_let (_, bindings, e) ->
               List.fold_right
                 (fun { pvb_pat = pat; pvb_expr = expr } acc ->
                    Exp.apply
                      bind_exp
                      ["", expr; "", Exp.fun_ "" None pat acc])
                 bindings
                 e
             | Pexp_fun (l, e0, pat, e) ->
               { e with
                 pexp_desc = Pexp_fun (l, Option.map (this.expr this) e0, pat, compile_sequence this e) }
             | Pexp_function cases ->
               { e with
                 pexp_desc = Pexp_function
                     (List.map
                        (fun case -> { case with pc_rhs = compile_sequence this case.pc_rhs })
                        cases) }
             | _ ->
               this.expr this e
           end
         | _ ->
           super.expr this e) }

let () = Ast_mapper.run_main mapper
