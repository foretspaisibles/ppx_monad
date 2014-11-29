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
    | Pexp_sequence ({ pexp_desc = Pexp_setinstvar (var, e0) }, e1) ->
      Exp.apply
        bind_exp
        ["", this.expr this e0;
         "", Exp.fun_ "" None (Pat.var var) (compile_sequence this e1)]
    | Pexp_sequence (e0, e1) ->
      Exp.apply
        bind_exp
        ["", this.expr this e0;
         "", Exp.fun_ "" None (Pat.any ()) (compile_sequence this e1)]
    | _ ->
      this.expr this e
  in
  let rec compile_fun_seq this e = match e.pexp_desc with
    | Pexp_fun (l, e0, pat, e1) ->
      { e with
        pexp_desc = Pexp_fun (l, Option.map (this.expr this) e0,
                              this.pat this pat, compile_fun_seq this e1) }
    | _ ->
      compile_sequence this e
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
                 (fun { pvb_pat = pat; pvb_expr = pe } acc ->
                    Exp.apply
                      bind_exp
                      ["", this.expr this pe;
                       "", Exp.fun_ "" None pat acc])
                 bindings
                 (this.expr this e)
             | Pexp_fun _ ->
               compile_fun_seq this e
             | Pexp_function cases ->
               { e with
                 pexp_desc = Pexp_function
                     (List.map
                        (fun case -> { case with
                                       pc_guard = Option.map (this.expr this) case.pc_guard;
                                       pc_rhs = compile_sequence this case.pc_rhs })
                        cases) }
             | _ ->
               this.expr this e
           end
         | _ ->
           super.expr this e);
    structure_item =
      (fun this s ->
         match s.pstr_desc with
         | Pstr_extension (({ txt = "monad" }, PStr [{ pstr_desc = Pstr_value (rec_flag, bindings) }]), _) ->
           let bindings =
             List.map
               (fun b -> { b with pvb_expr = compile_fun_seq this b.pvb_expr })
               bindings
           in
           { s with
             pstr_desc = Pstr_value (rec_flag, bindings) }
         | _ ->
           super.structure_item this s)
  }

let () = Ast_mapper.run_main mapper
