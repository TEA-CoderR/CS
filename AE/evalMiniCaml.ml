(* Linguaggio *)
type ide = string;;  (* identificatore *)

type exp = 
		| CstInt of int (* costante intera *)
		| CstTrue (* costante booleana true *)
		| CstFalse (* costante booleana false *)
		| Den of ide (* sostituisce a ide il suo valore *)
		| Sum of exp * exp (* somma tra interi *)
		| Sub of exp * exp (* sottrazione tra interi *)
		| Times of exp * exp (* moltiplicazione tra *)
		| Ifthenelse of exp * exp * exp (* operatore ternario ifthenelse *)
		| Eq of exp * exp (* equivalenza tra ide *)
		| Let of ide * exp * exp (* assegnamento *)
		| Fun of ide * exp (* funzione unaria non ricorsiva *)
		| Letrec of ide * ide * exp * exp (* funzione unaria ricorsiva *)
		| Apply of exp * exp (* applicazione di funzione *)
;;

(* Ambiente polimorfo *)
type 'v env = (string * 'v) list;; 
type evT = (* tipi esprimibili *)
		| Int of int 
		| Bool of bool 
		| Closure of ide * exp * evT env  (* chiusura *)
		| RecClosure of ide * ide * exp * evT env (* chiusura ricorsiva *)
		| Unbound;;
let emptyEnv  = [ ("", Unbound)] ;;
let bind (s: evT env) (i:string) (x:evT) = ( i, x ) :: s;; (* binding *)
let rec lookup (s:evT env) (i:string) = match s with (* ricerca i nell'ambiente s *)
		| [] ->  Unbound
		| (j,v)::sl when j = i -> v
		| _::sl -> lookup sl i
;;

let typecheck (x, y) = match x with	(* typechecker *)
		| "int" -> 
				(match y with 
										| Int(u) -> true
										| _ -> false)
		
		| "bool" -> 
				(match y with 
										| Bool(u) -> true
										| _ -> false)
		
		| _ -> failwith ("not a valid type")
;;

(* operazioni primitive *)
let int_eq(x,y) =
	match (typecheck("int",x), typecheck("int",y), x, y) with
		| (true, true, Int(v), Int(w)) -> Bool(v = w)
		| (_,_,_,_) -> failwith("run-time error ")
;;
       
 let int_plus(x, y) =
	match(typecheck("int",x), typecheck("int",y), x, y) with
		| (true, true, Int(v), Int(w)) -> Int(v + w)
		| (_,_,_,_) -> failwith("run-time error ")
;;

let int_sub(x, y) =
	match(typecheck("int",x), typecheck("int",y), x, y) with
		| (true, true, Int(v), Int(w)) -> Int(v - w)
		| (_,_,_,_) -> failwith("run-time error ")
;;

let int_times(x, y) =
	match(typecheck("int",x), typecheck("int",y), x, y) with
		| (true, true, Int(v), Int(w)) -> Int(v * w)
		| (_,_,_,_) -> failwith("run-time error ")
;;

(* interprete *)

let rec eval1  (e:exp) (s:evT env) =
	match e with
		| CstInt(n) -> Int(n)
		| CstTrue -> Bool(true)
		| CstFalse -> Bool(false)
		| Eq(e1, e2) ->
				int_eq((eval e1 s), (eval e2 s))
		| Times(e1,e2) ->
				int_times((eval e1 s), (eval e2 s))
		| Sum(e1, e2) ->
				int_plus((eval e1 s), (eval e2 s))
		| Sub(e1, e2) ->
				int_sub((eval e1 s), (eval e2 s))
		| Ifthenelse(e1,e2,e3) ->
				let g = eval e1 s in
					(match (typecheck("bool", g), g) with
						| (true, Bool(true)) ->
								eval e2 s
						| (true, Bool(false)) ->
								eval e3 s
						| (_, _) -> failwith ("nonboolean guard"))
		| Den(i) ->
				lookup s i
		| Let(i, e, ebody) ->
				eval ebody (bind s i (eval e s))
		| Fun(arg, ebody) ->
				Closure(arg,ebody,s)
		| Letrec(f, arg, fBody, letBody) ->
				let benv = bind (s) (f) (RecClosure(f, arg, fBody,s)) in eval letBody benv
		| Apply(eF, eArg) ->
				let fclosure = eval eF s in 
					(match fclosure with 
						| Closure(arg, fbody, fDecEnv) ->
								let aVal = eval eArg s in
									let aenv = bind fDecEnv arg aVal in eval fbody aenv
		| RecClosure(f, arg, fbody, fDecEnv) ->
				let aVal = eval eArg s in
					let rEnv = bind fDecEnv f fclosure in
						let aenv = bind rEnv arg aVal in eval fbody aenv
		| _ -> failwith("non functional value"));;