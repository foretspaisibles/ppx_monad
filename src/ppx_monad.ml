module Option = struct
  let map f = function
    | None -> None
    | Some a -> Some (f a)
end

module String = struct
  include String

  let is_prefix s t =
    length t >= length s && sub t 0 (length s) = s

  let suffix offset t =
    sub t offset (length t - offset)

  let split ~with_ t =
    let rec loop i =
      try
        let j = index_from t i with_ in
        sub t i (j - i) :: loop (j + 1)
      with Not_found ->
        [sub t i (length t - i)]
    in loop 0
end

let monad_extension_tag = "monad"

let is_monad_extension_id id =
  id = monad_extension_tag ||
  String.is_prefix (monad_extension_tag ^ ".") id

let parse_monad_extension_id id =
  let open Longident in
  let prefix = monad_extension_tag ^ "." in
  if String.is_prefix prefix id
  then
    let names = String.split ~with_:'.' (String.suffix (String.length prefix) id) in
    let lid =
      List.fold_left
        (fun acc name -> Ldot (acc, name))
        (Lident (List.hd names))
        (List.tl names)
    in Some lid
  else None

let mapper args =
  let strict_sequence = not (List.mem "--no-strict-sequence" args) in
  let open Asttypes in
  let open Parsetree in
  let open Longident in
  let open Ast_mapper in
  let open Ast_helper in
  let with_monad_extension id f =
    match parse_monad_extension_id id with
    | None ->
      f ()
    | Some lid ->
      Exp.let_
        Nonrecursive
        [Vb.mk
           (Pat.var { txt = ">>="; loc = Location.none })
           (Exp.ident { txt = Ldot (lid, ">>="); loc = Location.none });
         Vb.mk
           (Pat.var { txt = "return"; loc = Location.none })
           (Exp.ident { txt = Ldot (lid, "return"); loc = Location.none })]
        (f ())
  in
  let bind e0 e1 =
    Exp.apply
      (Exp.ident { txt = Lident ">>="; loc = Location.none })
      ["", e0; "", e1]
  in
  let super = default_mapper in
  let rec compile_sequence this e = match e.pexp_desc with
    | Pexp_sequence ({ pexp_desc = Pexp_setinstvar (var, e0) }, e1) ->
      bind
        (this.expr this e0)
        (Exp.fun_ "" None (Pat.var var) (compile_sequence this e1))
    | Pexp_sequence (e0, e1) ->
      bind
        (this.expr this e0)
        (Exp.fun_ "" None
           (if strict_sequence
            then Pat.construct { txt = Lident "()"; loc = Location.none } None
            else Pat.any ())
           (compile_sequence this e1))
    | Pexp_let (rec_flag, bindings, e) ->
      { e with
        pexp_desc = Pexp_let (rec_flag,
                              List.map (this.value_binding this) bindings,
                              compile_sequence this e) }
    | Pexp_letmodule (name, me, e) ->
      { e with
        pexp_desc = Pexp_letmodule (name, this.module_expr this me,
                                    compile_sequence this e) }
    | Pexp_open (override_flag, name, e) ->
      { e with
        pexp_desc = Pexp_open (override_flag, name, compile_sequence this e) }
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
  let compile_case this case =
    { case with
      pc_guard = Option.map (this.expr this) case.pc_guard;
      pc_rhs = compile_sequence this case.pc_rhs }
  in
  { super with
    expr =
      (fun this e ->
         match e.pexp_desc with
         | Pexp_extension ({ txt = id }, PStr [{ pstr_desc = Pstr_eval (e, _) }])
           when is_monad_extension_id id ->
           with_monad_extension id begin fun () ->
             match e.pexp_desc with
               | Pexp_sequence _ ->
                 compile_sequence this e
               | Pexp_let (_, bindings, e) ->
                 List.fold_right
                   (fun { pvb_pat = pat; pvb_expr = pe } acc ->
                      bind
                        (this.expr this pe)
                        (Exp.fun_ "" None pat acc))
                   bindings
                   (this.expr this e)
               | Pexp_fun _ ->
                 compile_fun_seq this e
               | Pexp_function cases ->
                 { e with
                   pexp_desc = Pexp_function (List.map (compile_case this) cases) }
               | Pexp_match (e, cases) ->
                 { e with
                   pexp_desc = Pexp_match (this.expr this e, List.map (compile_case this) cases) }
               | _ ->
                 this.expr this e
           end
         | _ ->
           super.expr this e);
    structure_item =
      (fun this s ->
         match s.pstr_desc with
         | Pstr_extension (({ txt = id }, PStr [{ pstr_desc = Pstr_value (rec_flag, bindings) }]), _)
           when is_monad_extension_id id ->
           let bindings =
             List.map
               (fun b -> { b with pvb_expr = with_monad_extension id (fun () -> compile_fun_seq this b.pvb_expr) })
               bindings
           in
           { s with
             pstr_desc = Pstr_value (rec_flag, bindings) }
         | _ ->
           super.structure_item this s)
  }

let () = if not !Sys.interactive then Ast_mapper.run_main mapper
