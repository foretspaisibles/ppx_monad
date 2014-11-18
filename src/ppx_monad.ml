let mapper _args =
  let open Asttypes in
  let open Parsetree in
  let open Longident in
  let open Ast_mapper in
  let open Ast_helper in
  let super = default_mapper in
  { super with
    expr =
      (fun this e ->
         match e.pexp_desc with
         | Pexp_extension ({ txt = "monad" }, PStr [{ pstr_desc = Pstr_eval (e, _) }]) ->
           let rec loop e = match e.pexp_desc with
             | Pexp_sequence ({ pexp_desc =
                                  Pexp_apply ({ pexp_desc = Pexp_ident { txt = Lident "<--" } },
                                              [_, { pexp_desc = Pexp_ident { txt = Lident v } }; _, e1]) },
                              e2) ->
               Exp.apply
                 (Exp.ident { txt = Lident "bind"; loc = Location.none })
                 ["", e1; "", Exp.fun_ "" None (Pat.var { txt = v; loc = Location.none }) (loop e2)]
             | Pexp_sequence (e1, e2) ->
               Exp.apply
                 (Exp.ident { txt = Lident "bind"; loc = Location.none })
                 ["", e1; "", Exp.fun_ "" None (Pat.any ()) (loop e2)]
             | _ -> e
           in loop e
         | _ ->
           super.expr this e) }

let () = Ast_mapper.run_main mapper
