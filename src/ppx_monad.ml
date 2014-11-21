let mapper _args =
  let open Asttypes in
  let open Parsetree in
  let open Longident in
  let open Ast_mapper in
  let open Ast_helper in
  let bind_exp = (Exp.ident { txt = Lident ">>="; loc = Location.none }) in
  let super = default_mapper in
  { super with
    expr =
      (fun this e ->
         match e.pexp_desc with
         | Pexp_extension ({ txt = "monad" }, PStr [{ pstr_desc = Pstr_eval (e, _) }]) ->
           begin match e.pexp_desc with
             | Pexp_sequence _ ->
               let rec loop e = match e.pexp_desc with
                 | Pexp_sequence ({ pexp_desc = Pexp_setinstvar (var, e1) }, e2) ->
                   Exp.apply
                     bind_exp
                     ["", e1; "", Exp.fun_ "" None (Pat.var var) (loop e2)]
                 | Pexp_sequence (e1, e2) ->
                   Exp.apply
                     bind_exp
                     ["", e1; "", Exp.fun_ "" None (Pat.any ()) (loop e2)]
                 | _ ->
                   super.expr this e
               in loop e
             | Pexp_let (_, bindings, e) ->
               List.fold_right
                 (fun { pvb_pat = pat; pvb_expr = expr } acc ->
                    Exp.apply
                      bind_exp
                      ["", expr; "", Exp.fun_ "" None pat acc])
                 bindings
                 e
             | _ ->
               super.expr this e
           end
         | _ ->
           super.expr this e) }

let () = Ast_mapper.run_main mapper
