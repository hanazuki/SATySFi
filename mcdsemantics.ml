(* module Mcdsemantics *)
  open Types

  type location = abstract_tree ref
  type var_environment = (var_name, location) Assoclist.t
  type macro_environment = (macro_name, macro_location) Assoclist.t
  and function_spec = DummyFunc | Func of (var_name list) * abstract_tree * abstract_tree * macro_environment * var_environment
  and macro_location = function_spec ref

  let report_error errmsg =
    print_string ("[ERROR IN SEMANTICS] " ^ errmsg ^ ".") ;
    print_newline ()

  (* for test *)
  let print_process stat =
    (* enable below in order to see the process of interpretation *)
  (*
    print_string stat ; print_newline () ;
  *)
    ()

  let loc_indent : location = ref EmptyAbsBlock

  let replace_list : ((literal_name * letter, letter) Assoclist.t) ref = ref Assoclist.empty
  let prefix_list : ((literal_name, abstract_tree) Assoclist.t) ref = ref Assoclist.empty
  let postfix_list : ((literal_name, abstract_tree) Assoclist.t) ref = ref Assoclist.empty

  (* abstract_tree -> abstract_tree *)
  let rec semantics abstr =
    print_process "[BEGIN SEMANTICS]" ;
    loc_indent := Output("") ;
    let loc_deepen : macro_location = ref DummyFunc in
    let loc_shallow : macro_location = ref DummyFunc in
    let loc_ifempty : macro_location = ref DummyFunc in
    let loc_ifsame : macro_location = ref DummyFunc in
    let loc_replace : macro_location = ref DummyFunc in
    let loc_prefix : macro_location = ref DummyFunc in
    let loc_postfix : macro_location = ref DummyFunc in
    let menv_main : macro_environment ref = ref Assoclist.empty in
    let venv_main : var_environment ref = ref Assoclist.empty in
      venv_main := (Assoclist.add "~indent" loc_indent !venv_main) ;
      menv_main := (Assoclist.add "\\deepen" loc_deepen !menv_main) ;
      menv_main := (Assoclist.add "\\shallow" loc_shallow !menv_main) ;
      menv_main := (Assoclist.add "\\ifempty" loc_ifempty !menv_main) ;
      menv_main := (Assoclist.add "\\ifsame" loc_ifsame !menv_main) ;
      menv_main := (Assoclist.add "\\replace" loc_replace !menv_main) ;
      menv_main := (Assoclist.add "\\prefix" loc_prefix !menv_main) ;
      menv_main := (Assoclist.add "\\postfix" loc_postfix !menv_main) ;
      loc_deepen := Func([], DeepenIndent, EmptyAbsBlock, !menv_main, !venv_main) ;
      loc_shallow := Func([], ShallowIndent, EmptyAbsBlock, !menv_main, !venv_main) ;
      loc_ifempty := Func(["~subj"; "~tru"; "~fls"],
                       PrimitiveIfEmpty(ContentOf("~subj"), ContentOf("~tru"), ContentOf("~fls")),
                       EmptyAbsBlock, !menv_main, !venv_main
                     ) ;
      loc_ifsame := Func(["~subj1"; "~subj2"; "~tru"; "~fls"],
                       PrimitiveIfSame(ContentOf("~subj1"), ContentOf("~subj2"), ContentOf("~tru"), ContentOf("~fls")),
                       EmptyAbsBlock, !menv_main, !venv_main
                     ) ;
      loc_replace := Func(["~name"; "~before"; "~after"],
                       PrimitiveReplace(ContentOf("~name"), ContentOf("~before"), ContentOf("~after")),
                       EmptyAbsBlock, !menv_main, !venv_main
                     ) ;
      loc_prefix := Func(["~name"; "~prefix"],
                       PrimitivePrefix(ContentOf("~name"), ContentOf("~prefix")),
                       EmptyAbsBlock, !menv_main, !venv_main
                     ) ;
      loc_postfix := Func(["~name"; "~postfix"],
                       PrimitivePostfix(ContentOf("~name"), ContentOf("~postfix")),
                       EmptyAbsBlock, !menv_main, !venv_main
                     ) ;
      interpret menv_main venv_main abstr

  (* (macro_environment ref) -> (var_environment ref) -> abstract_tree -> abstract_tree *)
  and interpret menv venv abstr =

    match abstr with

      PrimitiveIfEmpty(abstr_subj, abstr_tru, abstr_fls) -> (
          let value_subj = interpret menv venv abstr_subj in
          let value_tru = interpret menv venv abstr_tru in
          let value_fls = interpret menv venv abstr_fls in
            match value_subj with
              EmptyAbsBlock -> value_tru
            | _ -> value_fls
        )

    | PrimitiveIfSame(abstr_subj1, abstr_subj2, abstr_tru, abstr_fls) -> (
    	    print_process "$PrimitiveIfSame" ;
    	    let str_subj1 = (
    	      try Mcdout.mcdout (interpret menv venv abstr_subj1) with
    	        IllegalOut -> ( report_error "illegal argument of \\ifsame" ; "" )
    	    ) in
    	    let str_subj2 = (
    	      try Mcdout.mcdout (interpret menv venv abstr_subj2) with
    	        IllegalOut -> ( report_error "illegal argument of \\ifsame" ; "" )
    	    ) in (
    	      if (compare str_subj1 str_subj2) == 0 then (
    	        print_process ("$true [" ^ str_subj1 ^ "]") ;
    	        interpret menv venv abstr_tru
    	      ) else (
    	        print_process ("$false [" ^ str_subj1 ^ "][" ^ str_subj2 ^ "]") ;
    	        interpret menv venv abstr_fls
    	      )
    	    )
        )

    | PrimitiveReplace(abstr_name, abstr_before, abstr_after) -> (
          print_process "$PrimitiveReplace" ;
          let str_name = (
            try Mcdout.mcdout (interpret menv venv abstr_name) with
              IllegalOut -> ( report_error "illegal first argument of \\replace" ; "" )
          ) in
          let str_before = (
            try Mcdout.mcdout (interpret menv venv abstr_before) with
              IllegalOut -> ( report_error "illegal second argument of \\replace" ; "" )
          ) in
          let str_after = (
            try Mcdout.mcdout (interpret menv venv abstr_after) with
              IllegalOut -> ( report_error "illegal third argument of \\replace" ; "" )
          ) in
            replace_list := Assoclist.add (str_name, str_before) str_after !replace_list ;
            EmptyAbsBlock
        )

    | PrimitivePrefix(abstr_name, abstr_prefix) -> (
          print_process "$PrimitivePrefix" ;
          let str_name = (
            try Mcdout.mcdout (interpret menv venv abstr_name) with
              IllegalOut -> ( report_error "illegal first argument of \\prefix" ; "" )
          ) in
          let value_prefix = interpret menv venv abstr_prefix in
            prefix_list := Assoclist.add str_name value_prefix !prefix_list ;
            EmptyAbsBlock
        )

    | PrimitivePostfix(abstr_name, abstr_postfix) -> (
          print_process "$PrimitivePrefix" ;
          let str_name = (
            try Mcdout.mcdout (interpret menv venv abstr_name) with
              IllegalOut -> ( report_error "illegal first argument of \\postfix" ; "" )
          ) in
          let value_postfix = interpret menv venv abstr_postfix in
            postfix_list := Assoclist.add str_name value_postfix !postfix_list ;
            EmptyAbsBlock
        )

    | DeepenIndent -> (
          print_process "$DeepenIndent" ;
          (
            match !loc_indent with
              Output(indent_str) -> loc_indent := Output(indent_str ^ "  ")
            | _ -> report_error "illegal DeepenIndent"
          ) ;
          EmptyAbsBlock
        )

    | ShallowIndent -> (
          print_process "$ShallowIndent" ;
          (
            match !loc_indent with
              Output(indent_str) ->
                let len = String.length indent_str in
                  if len >= 2 then loc_indent := Output(String.sub indent_str 0 (len - 2))
                  else ()
            | _ -> report_error "illegal ShallowIndent"
          ) ;
          EmptyAbsBlock
        )

    | EmptyAbsBlock -> (
          print_process "$EmptyAbsBlock" ;
          EmptyAbsBlock
        )

    | AbsBlock(abstr_head, abstr_tail) -> (
          print_process "$AbsBlock 2" ;
          let value_head = interpret menv venv abstr_head in
          let value_tail = interpret menv venv abstr_tail in
            match value_head with
              EmptyAbsBlock -> value_tail
            | _ -> (
                  match value_tail with
                    EmptyAbsBlock -> value_head
                  | _ -> AbsBlock(value_head, value_tail)
                )
        )

    | Output(c) -> (
          print_process ("$Output: " ^ c) ;
          Output(c)
        )

    | ContentOf(v) -> (
          print_process ("$ContentOf: " ^ v) ;
          try
            interpret menv venv !(Assoclist.get_value (!venv) v)
        (*  !(Assoclist.get_value (!venv) v) *)
          with
            ValueNotFound -> (
                report_error ("undefined variable '" ^ v ^ "'") ;
                Invalid
              )
        )

    | Separated(abstr_former, abstr_latter) -> (
          print_process "$Separated" ;
          let value_former = interpret menv venv abstr_former in
          let value_latter = interpret menv venv abstr_latter in
            Separated(value_former, value_latter)
        )

    | Pop(u, v, abstr_rawlist, abstr_content) -> (
          let value_rawlist = interpret menv venv abstr_rawlist in
            match value_rawlist with
              EmptyAbsBlock -> (
                  print_process "$Pop (Empty)" ;
                  EmptyAbsBlock
                )
            | _ -> (
                  match pop_from_separated_tree value_rawlist UnderConstruction with
                    (value_former, value_latter) -> (
                        print_process "Pop (Content)" ;
                        let loc_former : location = ref value_former in
                        let loc_latter : location = ref value_latter in
                        let venv_content = ref (Assoclist.add v loc_latter (Assoclist.add u loc_former !venv)) in
                          interpret menv venv_content abstr_content
                      )
                )
        )

    | Macro(f, var_list, abstr_noid, abstr_id) -> (
          print_process "$Macro" ;
          let loc : macro_location = ref DummyFunc in (* dummy *)
          let menv_new = ref (Assoclist.add f loc !menv) in
          (* menv{ f|->loc } *)
          let value = Func(var_list, abstr_noid, abstr_id, !menv_new, !venv) in
            ( loc := value ; menv := !menv_new ; EmptyAbsBlock )
        )

    | Apply(f, NoID, param_list) -> (
          print_process "$Apply (NoID)" ;
          let spec_f =
            try
              !(Assoclist.get_value (!menv) f)
            with
              ValueNotFound -> (
                  report_error ("undefined control sequence '" ^ f ^ "'") ;
                  DummyFunc
                )
          in
            match spec_f with (* !(menv(f)) *)
              Func(var_list, abstr_noid, abstr_id, cont_menv_f, cont_venv_f) -> (
                  let value_list = interpret_list menv venv param_list in
                  let loc_list : location list = ref_list value_list in
                  let menv_new = ref cont_menv_f in
                  let venv_new =
                    try
                      ref (Assoclist.add_list var_list loc_list cont_venv_f)
                    with
                      IncorrespondenceOfLength -> (
                          report_error "wrong number of arguments" ;
                          ref cont_venv_f
                        )
                  in
                    (* venv_f{ v_1|->l_1, ..., v_n|->l_n } *)
                    interpret menv venv_new abstr_noid
                      (* modify 'menv_new' to 'menv' in order to make f globally defined *)
                      (* modify 'menv' to 'menv_new' in order to make f locally defined *)
                )
            | DummyFunc -> Invalid
        )
    | Apply(f, RealID(i), param_list) -> (
          print_process "$Apply (ID)" ;
          let spec_f =
            try
              !(Assoclist.get_value (!menv) f)
            with
              ValueNotFound -> (
                  report_error ("undefined control sequence '" ^ f ^ "'") ;
                  DummyFunc
                )
          in
            match spec_f with (* !(menv(f)) *)
              Func(var_list, abstr_noid, abstr_id, cont_menv_f, cont_venv_f) -> (
                  let value_list = interpret_list menv venv param_list in
                  let loc_list : location list = ref_list value_list in
                  let loc_id : location = ref (id_to_abstract_tree i) in
                  let menv_new = ref cont_menv_f in
                  let venv_new =
                    try
                      ref (Assoclist.add "@id" loc_id (Assoclist.add_list var_list loc_list cont_venv_f))
                    with
                      IncorrespondenceOfLength -> (
                          report_error "wrong number of argument" ;
                          ref cont_venv_f
                        )
                  in
                  (* venv_f{ v_1|->l_1, ..., v_n|->l_n, @id|->loc_id } *)
                    interpret menv venv_new abstr_id
                      (* modify 'menv_new' to 'menv' in order to make f globally defined *)
                      (* modify 'menv' to 'menv_new' in order to make f locally defined *)
                )
            | DummyFunc -> (
                report_error "illegal Apply of DummyFunc" ;
                Invalid
              )
        )

    | LiteralBlock(lb, abstr_lb) -> (
          print_process "$LiteralBlock" ;
          let abstr_prefix =
            try Assoclist.get_value !prefix_list lb with
              ValueNotFound -> EmptyAbsBlock
          in
          let abstr_postfix =
            try Assoclist.get_value !postfix_list lb with
              ValueNotFound -> EmptyAbsBlock
          in
            AbsBlock(
              abstr_prefix,
              AbsBlock(
                make_literal_legitimate lb abstr_lb,
                abstr_postfix
              )
            )
        )

    | _ -> Invalid

  (* macro_environment -> var_environment -> (abstract_tree list) -> (abstract_tree list) *)
  and interpret_list menv venv abstr_list =
    match abstr_list with
      [] -> []
    | abstr_head :: abstr_tail -> (
          let intrprtd_head = interpret menv venv abstr_head in
          let intrprtd_tail = interpret_list menv venv abstr_tail in
            intrprtd_head :: intrprtd_tail
        )

  (* abstract_tree list -> location list *)
  and ref_list value_list =
    match value_list with
      [] -> []
    | value_head :: value_tail -> (ref value_head) :: (ref_list value_tail)

  and id_to_abstract_tree id = Output((String.sub id 1 ((String.length id) - 1)))
    (* eliminate '#' *)

  (* abstract_tree -> abstract_tree -> (abstract_tree * abstract_tree) *)
  and pop_from_separated_tree abstr_in abstr_constr =
    match abstr_in with
      Separated(abstr_former, abstr_latter) -> (
          match abstr_former with
            Separated(a, b) -> (
              pop_from_separated_tree abstr_former (compensate abstr_constr (Separated(UnderConstruction, abstr_latter)))
            )
          | _ -> (abstr_former, compensate abstr_constr abstr_latter)
        )
    | _ -> (abstr_in, EmptyAbsBlock)

  (* abstract_tree -> abstract_tree -> abstract_tree *)
  and compensate abstr_under_constr abstr_cmpnstd =
    match abstr_under_constr with
      Separated(abstr_former, abstr_latter)
        -> Separated((compensate abstr_former abstr_cmpnstd), (compensate abstr_latter abstr_cmpnstd))
    | UnderConstruction -> abstr_cmpnstd
    | abstr_other -> abstr_other

  and make_literal_legitimate lb abstr =
    match abstr with
      AbsBlock(abstr_former, abstr_latter) -> (
          AbsBlock(make_literal_legitimate lb abstr_former, make_literal_legitimate lb abstr_latter)
        )
    | OutputOfLiteral(c) ->
        let value_after = (
          try Assoclist.get_value !replace_list (lb, c) with
            ValueNotFound -> c
        ) in
          Output(value_after)

    | _ -> (
        report_error "illegal token in literal block" ;
        Invalid
      )
