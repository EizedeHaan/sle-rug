module Check

import AST;
import Resolve;
import Message; // see standard library
import Location;

data Type
  = tint()
  | tbool()
  | tstr()
  | tunknown()
  ;

Type convertAType(AType t) {
  switch(t) {
    case integer(): return tint();
    case boolean(): return tbool();
    case string(): return tstr();
    default: return tunknown();
  }
}

// the type environment consisting of defined questions in the form 
alias TEnv = rel[loc def, str name, str label, Type \type];

// To avoid recursively traversing the form, use the `visit` construct
// or deep match (e.g., `for (/question(...) := f) {...}` ) 
TEnv collect(AForm f) {
  TEnv env = {};
  visit(f) {
    case Q(str question, AId var, integer()): 
      env += {<var.src, var.name, question, tint()>};
    case Q(str question, AId var, boolean()): 
      env += {<var.src, var.name, question, tbool()>};
    case Q(str question, AId var, string()): 
      env += {<var.src, var.name, question, tstr()>};
    case Q(str question, AId var, AType _): 
      env += {<var.src, var.name, question, tunknown()>};
    case computedQ(str question, AId var, integer(), AExpr _): 
      env += {<var.src, var.name, question, tint()>};
    case computedQ(str question, AId var, boolean(), AExpr _): 
      env += {<var.src, var.name, question, tbool()>};
    case computedQ(str question, AId var, string(), AExpr _): 
      env += {<var.src, var.name, question, tstr()>};
    case computedQ(str question, AId var, AType _, AExpr _): 
      env += {<var.src, var.name, question, tunknown()>};
  }
  return env; 
}

set[Message] check(AForm f, TEnv tenv, UseDef useDef) {
  set[Message] msgs = {};
  for(AQuestion q <- f.questions) {
    msgs += check(q, tenv, useDef);
  };
  return msgs; 
}

// - produce an error if there are declared questions with the same name but different types.
// - duplicate labels should trigger a warning 
// - the declared type computed questions should match the type of the expression.
set[Message] check(AQuestion q, TEnv tenv, UseDef useDef) {
  set[Message] msgs = {};

  switch(q) {
    case ifElseQ(AExpr condition, list[AQuestion] ifQuestions, list[AQuestion] elseQuestions): {
      msgs += {error("Condition not boolean", condition.src) | typeOf(condition,tenv,useDef) != tbool()};
      msgs += check(condition,tenv,useDef);

      for(AQuestion ieq <- ifQuestions + elseQuestions) {
        msgs += check(ieq,tenv,useDef);
      }
    }

    case ifQ(AExpr condition, list[AQuestion] ifQuestions):{
      msgs += {error("Condition not boolean", condition.src) | typeOf(condition,tenv,useDef) != tbool()};
      msgs += check(condition,tenv,useDef);

      for(AQuestion iq <- ifQuestions) {
        msgs += check(iq,tenv,useDef);
      } 
    }

    case computedQ(str question, AId var, AType typ, AExpr expr): {
      msgs += {error("Question declared with different types", var.src)
        | <loc d, "<var>", str _, Type t2> <- tenv, d != var.src, convertAType(typ) != t2};

      msgs += {warning("Multiple questions with the same prompt", q.src)
        | <loc d, _, question, _> <- tenv, d != var.src};

      msgs += {warning("Different prompts used on the same variable", q.src)
        | <loc d, "<var>", str prompt, _> <- tenv, d != var.src, prompt != question};

      msgs += {error("Expression does not match variable type.", cover([var.src, expr.src]))
        | typeOf(expr,tenv,useDef) != convertAType(typ)};
      msgs += check(expr,tenv,useDef);
    }
      
    case Q(str question, AId var, AType typ): {
      msgs += {error("Question declared with different types", var.src)
        | <loc d, "<var>", str _, Type t2> <- tenv, d != var.src, convertAType(typ) != t2};

      msgs += {warning("Multiple questions with the same prompt", q.src)
        | <loc d, _, question, _> <- tenv, d != var.src};

      msgs += {warning("Different prompts used on the same variable", q.src)
        | <loc d, "<var>", str prompt, _> <- tenv, d != var.src, prompt != question};
    }
  }

  // msgs += {error("Question declared with different types", d)
  //   | <loc d, str name, str _, Type t1> <- tenv,
  //     <loc _, name, str _, Type t2> <- tenv, t1 != t2};

  // msgs += {warning("Multiple questions with the same prompt", d1)
  //   | <loc d1, _, str q, _> <- tenv,
  //     <loc d2, _, q, _> <- tenv, d1 != d2};
  return msgs; 
}

// Check operand compatibility with operators.
// E.g. for an addition node add(lhs, rhs), 
//   the requirement is that typeOf(lhs) == typeOf(rhs) == tint()
set[Message] check(AExpr e, TEnv tenv, UseDef useDef) {
  set[Message] msgs = {};
  
  switch (e) {
    case ref(AId x, src = loc u): {
      msgs += { error("Undeclared question", x.src) | useDef[x.src] == {} };
      msgs += { error("Question/variable used before declaration", x.src)
        | <u, loc d> <- useDef, beginsBefore(x.src, d)};
    }

    case not(AExpr expr): {
      if (typeOf(expr,tenv,useDef) != tbool()) {
        msgs += { error("Incompatible operand: must be boolean", expr.src)};
      }
      msgs += check(expr,tenv,useDef);
    }
    case mul(AExpr lhs, AExpr rhs): {
      if (typeOf(lhs,tenv,useDef) != tint()) {
        msgs += { error("Incompatible operand: must be integer", lhs.src)};
      }
      if (typeOf(rhs,tenv,useDef) != tint()) {
        msgs += { error("Incompatible operand: must be integer", rhs.src)};
      }
      msgs += check(lhs,tenv,useDef);
      msgs += check(rhs,tenv,useDef);
    }
    case div(AExpr lhs, AExpr rhs): {
      if (typeOf(lhs,tenv,useDef) != tint()) {
        msgs += { error("Incompatible operand: must be integer", lhs.src)};
      }
      if (typeOf(rhs,tenv,useDef) != tint()) {
        msgs += { error("Incompatible operand: must be integer", rhs.src)};
      }
      msgs += check(lhs,tenv,useDef);
      msgs += check(rhs,tenv,useDef);
    }
    case add(AExpr lhs, AExpr rhs): {
      if (typeOf(lhs,tenv,useDef) != tint()) {
        msgs += { error("Incompatible operand: must be integer", lhs.src)};
      }
      if (typeOf(rhs,tenv,useDef) != tint()) {
        msgs += { error("Incompatible operand: must be integer", rhs.src)};
      }
      msgs += check(lhs,tenv,useDef);
      msgs += check(rhs,tenv,useDef);
    }
    case sub(AExpr lhs, AExpr rhs): {
      if (typeOf(lhs,tenv,useDef) != tint()) {
        msgs += { error("Incompatible operand: must be integer", lhs.src)};
      }
      if (typeOf(rhs,tenv,useDef) != tint()) {
        msgs += { error("Incompatible operand: must be integer", rhs.src)};
      }
      msgs += check(lhs,tenv,useDef);
      msgs += check(rhs,tenv,useDef);
    }
    case less(AExpr lhs, AExpr rhs): {
      if (typeOf(lhs,tenv,useDef) != tint()) {
        msgs += { error("Incompatible operand: must be integer", lhs.src)};
      }
      if (typeOf(rhs,tenv,useDef) != tint()) {
        msgs += { error("Incompatible operand: must be integer", rhs.src)};
      }
      msgs += check(lhs,tenv,useDef);
      msgs += check(rhs,tenv,useDef);
    }
    case leq(AExpr lhs, AExpr rhs): {
      if (typeOf(lhs,tenv,useDef) != tint()) {
        msgs += { error("Incompatible operand: must be integer", lhs.src)};
      }
      if (typeOf(rhs,tenv,useDef) != tint()) {
        msgs += { error("Incompatible operand: must be integer", rhs.src)};
      }
      msgs += check(lhs,tenv,useDef);
      msgs += check(rhs,tenv,useDef);
    }
    case greater(AExpr lhs, AExpr rhs): {
      if (typeOf(lhs,tenv,useDef) != tint()) {
        msgs += { error("Incompatible operand: must be integer", lhs.src)};
      }
      if (typeOf(rhs,tenv,useDef) != tint()) {
        msgs += { error("Incompatible operand: must be integer", rhs.src)};
      }
      msgs += check(lhs,tenv,useDef);
      msgs += check(rhs,tenv,useDef);
    }
    case greq(AExpr lhs, AExpr rhs): {
      if (typeOf(lhs,tenv,useDef) != tint()) {
        msgs += { error("Incompatible operand: must be integer", lhs.src)};
      }
      if (typeOf(rhs,tenv,useDef) != tint()) {
        msgs += { error("Incompatible operand: must be integer", rhs.src)};
      }
      msgs += check(lhs,tenv,useDef);
      msgs += check(rhs,tenv,useDef);
    }
    case eq(AExpr lhs, AExpr rhs): {
      if (typeOf(lhs,tenv,useDef) != tint()) {
        msgs += { error("Incompatible operand: must be integer", lhs.src)};
      }
      if (typeOf(rhs,tenv,useDef) != tint()) {
        msgs += { error("Incompatible operand: must be integer", rhs.src)};
      }
      msgs += check(lhs,tenv,useDef);
      msgs += check(rhs,tenv,useDef);
    }
    case neq(AExpr lhs, AExpr rhs): {
      if (typeOf(lhs,tenv,useDef) != tint()) {
        msgs += { error("Incompatible operand: must be integer", lhs.src)};
      }
      if (typeOf(rhs,tenv,useDef) != tint()) {
        msgs += { error("Incompatible operand: must be integer", rhs.src)};
      }
      msgs += check(lhs,tenv,useDef);
      msgs += check(rhs,tenv,useDef);
    }
    case and(AExpr lhs, AExpr rhs): {
      if (typeOf(lhs,tenv,useDef) != tbool()) {
        msgs += { error("Incompatible operand: must be boolean", lhs.src)};
      }
      if (typeOf(rhs,tenv,useDef) != tbool()) {
        msgs += { error("Incompatible operand: must be boolean", rhs.src)};
      }
      msgs += check(lhs,tenv,useDef);
      msgs += check(rhs,tenv,useDef);
    }
    case or(AExpr lhs, AExpr rhs): {
      if (typeOf(lhs,tenv,useDef) != tbool()) {
        msgs += { error("Incompatible operand: must be boolean", lhs.src)};
      }
      if (typeOf(rhs,tenv,useDef) != tbool()) {
        msgs += { error("Incompatible operand: must be boolean", rhs.src)};
      }
      msgs += check(lhs,tenv,useDef);
      msgs += check(rhs,tenv,useDef);
    }
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
    case strLit(_): return tstr();
    case intLit(_): return tint();
    case boolLit(_): return tbool();
    case parenthesis(AExpr expr): return typeOf(expr, tenv, useDef);
    case not(AExpr _): return tbool();
    case mul(AExpr _, AExpr _): return tint();
    case div(AExpr _, AExpr _): return tint();
    case add(AExpr _, AExpr _): return tint();
    case sub(AExpr _, AExpr _): return tint();
    case less(AExpr _, AExpr _): return tbool();
    case leq(AExpr _, AExpr _): return tbool();
    case greater(AExpr _, AExpr _): return tbool();
    case greq(AExpr _, AExpr _): return tbool();
    case eq(AExpr _, AExpr _): return tbool();
    case neq(AExpr _, AExpr _): return tbool();
    case and(AExpr _, AExpr _): return tbool();
    case or(AExpr _, AExpr _): return tbool();
    default: return tunknown();
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
 
 

