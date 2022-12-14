module Check

import AST;
import Resolve;
import Message; // see standard library

data Type
  = tint()
  | tbool()
  | tstr()
  | tunknown()
  ;

// the type environment consisting of defined questions in the form 
alias TEnv = rel[loc def, str name, str label, Type \type];

// To avoid recursively traversing the form, use the `visit` construct
// or deep match (e.g., `for (/question(...) := f) {...}` ) 
TEnv collect(AForm f) {
  TEnv env = {};
  visit(f) {
    case Q(str question, AId var, integer()): 
      env + {<var.src, var.name, question, tint()>};
    case Q(str question, AId var, boolean()): 
      env + {<var.src, var.name, question, tbool()>};
    case Q(str question, AId var, string()): 
      env + {<var.src, var.name, question, tstr()>};
    case Q(str question, AId var, AType _): 
      env + {<var.src, var.name, question, tunknown()>};
    case computedQ(str question, AId var, integer(), AExpr _): 
      env + {<var.src, var.name, question, tint()>};
    case computedQ(str question, AId var, boolean(), AExpr _): 
      env + {<var.src, var.name, question, tbool()>};
    case computedQ(str question, AId var, string(), AExpr _): 
      env + {<var.src, var.name, question, tstr()>};
    case computedQ(str question, AId var, AType _, AExpr _): 
      env + {<var.src, var.name, question, tunknown()>};
  }
  return env; 
}

set[Message] check(AForm f, TEnv tenv, UseDef useDef) {
  return {}; 
}

// - produce an error if there are declared questions with the same name but different types.
// - duplicate labels should trigger a warning 
// - the declared type computed questions should match the type of the expression.
set[Message] check(AQuestion q, TEnv tenv, UseDef useDef) {
  set[Message] msgs = {};

  msgs += {error("Question declared with different types", d)
    | <loc d, str name, str _, Type t1> <- tenv,
      <loc _, name, str _, Type t2> <- tenv, t1 != t2};

  msgs += {warning("Multiple questions with the same prompt", d1)
    | <loc d1, _, str q, _> <- tenv,
      <loc d2, _, q, _> <- tenv, d1 != d2};
  return msgs; 
}

// Check operand compatibility with operators.
// E.g. for an addition node add(lhs, rhs), 
//   the requirement is that typeOf(lhs) == typeOf(rhs) == tint()
set[Message] check(AExpr e, TEnv tenv, UseDef useDef) {
  set[Message] msgs = {};
  
  switch (e) {
    case ref(AId x):
      msgs += { error("Undeclared question", x.src) | useDef[x.src] == {} };

    // etc.
  }
  
  return msgs; 
}

Type typeOf(AExpr e, TEnv tenv, UseDef useDef) {
  switch (e) {
    case ref(id(_, src = loc u)):  
      if (<u, loc d> <- useDef, <d, x, _, Type t> <- tenv) {
        return t;
      }
    // etc.
  }
  return tunknown(); 
}

/* 
 * Pattern-based dispatch style:
 * 
 * Type typeOf(ref(id(_, src = loc u)), TEnv tenv, UseDef useDef) = t
 *   when <u, loc d> <- useDef, <d, x, _, Type t> <- tenv
 *
 * ... etc.
 * 
 * default Type typeOf(AExpr _, TEnv _, UseDef _) = tunknown();
 *
 */
 
 

