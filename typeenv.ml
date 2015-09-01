open Types

(* type_environment *)
let empty = []

(* type_environment -> var_name -> type_struct -> type_environment *)
let rec add tyenv varnm tystr =
  match tyenv with
  | []               -> [(varnm, tystr)]
  | (vn, ts) :: tail ->
      if vn = varnm then (varnm, tystr) :: tail else (vn, ts) :: (add tail varnm tystr)

(* type_environment -> var_name -> type_struct *)
let rec find tyenv varnm =
  match tyenv with
  | []               -> raise Not_found
  | (vn, ts) :: tail -> if vn = varnm then ts else find tail varnm


let get_range_from_type tystr =
  match tystr with
  | IntType(rng)         -> rng
  | StringType(rng)      -> rng
  | BoolType(rng)        -> rng
  | UnitType(rng)        -> rng
  | TypeVariable(rng, _) -> rng
  | FuncType(rng, _, _)  -> rng
  | ListType(rng, _)     -> rng
  | RefType(rng, _)      -> rng
  | ProductType(rng, _)  -> rng
  | TypeEnvironmentType(rng, _) -> rng
  | ForallType(_, _)     -> (-31, 0, 0, 0)

let overwrite_range_of_type tystr rng =
  match tystr with
  | IntType(_)                -> IntType(rng)
  | StringType(_)             -> StringType(rng)
  | BoolType(_)               -> BoolType(rng)
  | UnitType(_)               -> UnitType(rng)
  | TypeVariable(_, tvid)     -> TypeVariable(rng, tvid)
  | FuncType(_, tydom, tycod) -> FuncType(rng, tydom, tycod)
  | ListType(_, tycont)       -> ListType(rng, tycont)
  | RefType(_, tycont)        -> RefType(rng, tycont)
  | ProductType(_, tylist)    -> ProductType(rng, tylist)
  | TypeEnvironmentType(_, tyenv)  -> TypeEnvironmentType(rng, tyenv)
  | ForallType(tvid, tycont)       -> ForallType(tvid, tycont)

let rec erase_range_of_type tystr =
  let dummy = (-2048, 0, 0, 0) in
    match tystr with
    | IntType(_)                -> IntType(dummy)
    | StringType(_)             -> StringType(dummy)
    | BoolType(_)               -> BoolType(dummy)
    | UnitType(_)               -> UnitType(dummy)
    | TypeVariable(_, tvid)     -> TypeVariable(dummy, tvid)
    | FuncType(_, tydom, tycod) -> FuncType(dummy, erase_range_of_type tydom, erase_range_of_type tycod)
    | ListType(_, tycont)       -> ListType(dummy, erase_range_of_type tycont)
    | RefType(_, tycont)        -> RefType(dummy, erase_range_of_type tycont)
    | ProductType(_, tylist)    -> ProductType(dummy, erase_range_of_type_list tylist)
    | TypeEnvironmentType(_, tyenv) -> TypeEnvironmentType(dummy, tyenv)
    | ForallType(tvid, tycont)      -> ForallType(tvid, erase_range_of_type tycont)
and erase_range_of_type_list tylist =
  match tylist with
  | []           -> []
  | head :: tail -> (erase_range_of_type head) :: (erase_range_of_type_list tail)


(* type_variable_id -> type_variable_id list -> bool *)
let rec find_in_list tvid lst =
  match lst with
  | []       -> false
  | hd :: tl -> if hd = tvid then true else find_in_list tvid tl

(* type_variable_id -> type_struct -> bool *)
let rec find_in_type_struct tvid tystr =
  match tystr with
  | TypeVariable(_, tvidx)    -> tvidx = tvid
  | FuncType(_, tydom, tycod) -> (find_in_type_struct tvid tydom) || (find_in_type_struct tvid tycod)
  | ListType(_, tycont)       -> find_in_type_struct tvid tycont
  | RefType(_, tycont)        -> find_in_type_struct tvid tycont
  | _                         -> false

(* type_variable_id -> type_environment -> bool *)
let rec find_in_type_environment tvid tyenv =
  match tyenv with
  | []                 -> false
  | (_, tystr) :: tail ->
      if find_in_type_struct tvid tystr then
        true
      else
        find_in_type_environment tvid tail


let unbound_id_list : type_variable_id list ref = ref []

(* type_struct -> type_environment -> (type_variable_id list) -> unit *)
let rec listup_unbound_id tystr tyenv =
  match tystr with
  | TypeVariable(_, tvid)     ->
      if find_in_type_environment tvid tyenv then ()
      else if find_in_list tvid !unbound_id_list then ()
      else unbound_id_list := tvid :: !unbound_id_list
  | FuncType(_, tydom, tycod) -> ( listup_unbound_id tydom tyenv ; listup_unbound_id tycod tyenv )
  | ListType(_, tycont)       -> listup_unbound_id tycont tyenv
  | RefType(_, tycont)        -> listup_unbound_id tycont tyenv
  | _                         -> ()

(* type_variable_id list -> type_struct -> type_struct *)
let rec add_forall_struct lst tystr =
  match lst with
  | []           -> tystr
  | tvid :: tail -> ForallType(tvid, add_forall_struct tail tystr)

(* type_struct -> type_environment -> type_struct *)
let make_forall_type tystr tyenv =
  unbound_id_list := [] ; listup_unbound_id tystr tyenv ;
  add_forall_struct (!unbound_id_list) tystr
