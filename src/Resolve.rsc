module Resolve

import AST;

/*
 * Name resolution for QL
 */ 


// modeling declaring occurrences of names
alias Def = rel[str name, loc def];

// modeling use occurrences of names
alias Use = rel[loc use, str name];

alias UseDef = rel[loc use, loc def];

// the reference graph
alias RefGraph = tuple[
  Use uses, 
  Def defs, 
  UseDef useDef
]; 

RefGraph resolve(AForm f) = <us, ds, us o ds>
  when Use us := uses(f), Def ds := defs(f);

Use uses(AForm f) {
  return {<var.src, var.name> | /ref(AId var) := f}; 
}

Def defs(AForm f) {
  return {<var.name, var.src> | /computedQ(str _, AId var, AType _, AExpr _) := f}
      +  {<var.name, var.src> | /Q(str _, AId var, AType _) := f}; 
}