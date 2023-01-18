module Eval

import AST;
import Resolve;

/*
 * Implement big-step semantics for QL
 */
 
// NB: Eval may assume the form is type- and name-correct.


// Semantic domain for expressions (values)
data Value
  = vint(int n)
  | vbool(bool b)
  | vstr(str s)
  ;

// The value environment
alias VEnv = map[str name, Value \value];

// Modeling user input
data Input
  = input(str question, Value \value);
  
// produce an environment which for each question has a default value
// (e.g. 0 for int, "" for str etc.)
VEnv initialEnv(AForm f) {
  return (var.name : vint(0) | /Q(str _, AId var, integer()) := f)
      +  (var.name : vbool(false) | /Q(str _, AId var, boolean()) := f)
      +  (var.name : vstr("") | /Q(str _, AId var, string()) := f)
      +  (var.name : vint(0) | /computedQ(str _, AId var, integer(), AExpr _) := f)
      +  (var.name : vbool(false) | /computedQ(str _, AId var, boolean(), AExpr _) := f)
      +  (var.name : vstr("") | /computedQ(str _, AId var, string(), AExpr _) := f)
      +  ("<condition>" : vbool(false) | /ifElseQ(AExpr condition, _, _) := f)
      +  ("<condition>" : vbool(false) | /ifQ(AExpr condition, _) := f)
    ;
}


// Because of out-of-order use and declaration of questions
// we use the solve primitive in Rascal to find the fixpoint of venv.
VEnv eval(AForm f, Input inp, VEnv venv) {
  return solve (venv) {
    venv = evalOnce(f, inp, venv);
  }
}

VEnv evalOnce(AForm f, Input inp, VEnv venv) {
  for(q <- f.questions) {
    venv = eval(q, inp, venv);
  }
  return venv;
}

VEnv eval(AQuestion q, Input inp, VEnv venv) {
  // evaluate conditions for branching,
    //ifQ
    //ifElseQ
  // evaluate inp and computed questions to return updated VEnv
  switch (q) {
    case ifQ(AExpr condition, list[AQuestion] ifQuestions): {
      venv["<condition>"] = eval(condition, venv);
      venv = evalOnce(form("",ifQuestions), inp, venv);//bit of a trick
    }
    case ifElseQ(AExpr condition, list[AQuestion] ifQuestions, list[AQuestion] elseQuestions): {
      venv["<condition>"] = eval(condition, venv);
      venv = evalOnce(form("",ifQuestions), inp, venv);
      venv = evalOnce(form("",elseQuestions), inp, venv);
    }
    case computedQ(_, AId var, _, AExpr expr): 
      venv[var.name] = eval(expr, venv);
    case Q( _, AId var, _):
      if(inp.question == var.name) venv[var.name] = inp.\value;
  }
  return venv; 
}

Value eval(AExpr e, VEnv venv) {
  switch (e) {
    case ref(id(str x)): return venv[x];
    case boolLit(bool b): return vbool(b);
    case intLit(int n): return vint(n);
    case strLit(str s): return vstr(s);
    case parenthesis(AExpr expr): return eval(expr, venv);
    case not(AExpr expr): {
      if(vbool(bool b) := eval(expr, venv)) return vbool(!b);
      throw "Incompatible return type";
    }
    case mul(AExpr lhs, AExpr rhs): {
      if(vint(int l) := eval(lhs, venv) && vint(int r) := eval(rhs, venv)) return vint(l * r);
      throw "Incompatible return types";
    }
    case div(AExpr lhs, AExpr rhs): {
      if(vint(int l) := eval(lhs, venv) && vint(int r) := eval(rhs, venv)) return vint(l / r);
      throw "Incompatible return types";
    }
    case add(AExpr lhs, AExpr rhs): {
      if(vint(int l) := eval(lhs, venv) && vint(int r) := eval(rhs, venv)) return vint(l + r);
      throw "Incompatible return types";
    }
    case sub(AExpr lhs, AExpr rhs): {
      if(vint(int l) := eval(lhs, venv) && vint(int r) := eval(rhs, venv)) return vint(l - r);
      throw "Incompatible return types";
    }
    case less(AExpr lhs, AExpr rhs): {
      if(vint(int l) := eval(lhs, venv) && vint(int r) := eval(rhs, venv)) return vbool(l < r);
      throw "Incompatible return types";
    }
    case leq(AExpr lhs, AExpr rhs): {
      if(vint(int l) := eval(lhs, venv) && vint(int r) := eval(rhs, venv)) return vbool(l <= r);
      throw "Incompatible return types";
    }
    case greater(AExpr lhs, AExpr rhs): {
      if(vint(int l) := eval(lhs, venv) && vint(int r) := eval(rhs, venv)) return vbool(l > r);
      throw "Incompatible return types";
    }
    case greq(AExpr lhs, AExpr rhs): {
      if(vint(int l) := eval(lhs, venv) && vint(int r) := eval(rhs, venv)) return vbool(l >= r);
      throw "Incompatible return types";
    }
    case eq(AExpr lhs, AExpr rhs): {
      if(vint(int l) := eval(lhs, venv) && vint(int r) := eval(rhs, venv)) return vbool(l == r);
      throw "Incompatible return types";
    }
    case neq(AExpr lhs, AExpr rhs): {
      if(vint(int l) := eval(lhs, venv) && vint(int r) := eval(rhs, venv)) return vbool(l != r);
      throw "Incompatible return types";
    }
    case and(AExpr lhs, AExpr rhs): {
      if(vbool(bool l) := eval(lhs, venv) && vbool(bool r) := eval(rhs, venv)) return vbool(l && r);
      throw "Incompatible return types";
    }
    case or(AExpr lhs, AExpr rhs): {
      if(vbool(bool l) := eval(lhs, venv) && vbool(bool r) := eval(rhs, venv)) return vbool(l || r);
      throw "Incompatible return types";
    }
    
    default: throw "Unsupported expression <e>";
  }
}