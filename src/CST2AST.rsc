module CST2AST

import Syntax;
import AST;

import String;
import Boolean;
import Location;
import ParseTree;

/*
 * Implement a mapping from concrete syntax trees (CSTs) to abstract syntax trees (ASTs)
 *
 * - Use switch to do case distinction with concrete patterns (like in Hack your JS) 
 * - Map regular CST arguments (e.g., *, +, ?) to lists 
 *   (NB: you can iterate over * / + arguments using `<-` in comprehensions or for-loops).
 * - Map lexical nodes to Rascal primitive types (bool, int, str)
 * - See the ref example on how to obtain and propagate source locations.
 */

AForm cst2ast(start[Form] sf) {
  Form f = sf.top; // remove layout before and after form
  return form("<f.name>", [ cst2ast(q) | q <- f.questions ], src=f.src);
}

AQuestion cst2ast(q:(Question)`if ( <Expr condition> ) { <Question* ifQuestions> } else { <Question* elseQuestions> }`) {
  return ifElseQ(cst2ast(condition), [cst2ast(qi) | qi <- ifQuestions], [cst2ast(qi) | qi <- elseQuestions], src=q.src);
}

AQuestion cst2ast(q:(Question)`if ( <Expr condition> ) { <Question* ifQuestions> }`) {
  return ifQ(cst2ast(condition), [cst2ast(qi) | qi <- ifQuestions], src=q.src);
}

AQuestion cst2ast(q:(Question)`<Str question> <Id var> : <Type resType> = <Expr computation>`) {
  return computedQ("<question>", cst2ast(var), cst2ast(resType), cst2ast(computation), src=q.src);
}

default AQuestion cst2ast(Question q) {
  return Q("<q.question>", cst2ast(q.var), cst2ast(q.resType), src=q.src);
}

AExpr cst2ast(Expr e) {
  switch (e) {
    case (Expr)`( <Expr expr> )`: return parenthesis(cst2ast(expr), src=expr.src);
    case (Expr)`! <Expr expr>`: return not(cst2ast(expr), src=expr.src);
    case (Expr)`<Expr lhs> * <Expr rhs>`: return mul(cst2ast(lhs), cst2ast(rhs), src=cover([lhs.src,rhs.src]));
    case (Expr)`<Expr lhs> / <Expr rhs>`: return div(cst2ast(lhs), cst2ast(rhs), src=cover([lhs.src,rhs.src]));
    case (Expr)`<Expr lhs> + <Expr rhs>`: return add(cst2ast(lhs), cst2ast(rhs), src=cover([lhs.src,rhs.src]));
    case (Expr)`<Expr lhs> - <Expr rhs>`: return sub(cst2ast(lhs), cst2ast(rhs), src=cover([lhs.src,rhs.src]));
    case (Expr)`<Expr lhs> \< <Expr rhs>`: return less(cst2ast(lhs), cst2ast(rhs), src=cover([lhs.src,rhs.src]));
    case (Expr)`<Expr lhs> \<= <Expr rhs>`: return leq(cst2ast(lhs), cst2ast(rhs), src=cover([lhs.src,rhs.src]));
    case (Expr)`<Expr lhs> \> <Expr rhs>`: return greater(cst2ast(lhs), cst2ast(rhs), src=cover([lhs.src,rhs.src]));
    case (Expr)`<Expr lhs> \>= <Expr rhs>`: return greq(cst2ast(lhs), cst2ast(rhs), src=cover([lhs.src,rhs.src]));
    case (Expr)`<Expr lhs> == <Expr rhs>`: return eq(cst2ast(lhs), cst2ast(rhs), src=cover([lhs.src,rhs.src]));
    case (Expr)`<Expr lhs> != <Expr rhs>`: return neq(cst2ast(lhs), cst2ast(rhs), src=cover([lhs.src,rhs.src]));
    case (Expr)`<Expr lhs> && <Expr rhs>`: return and(cst2ast(lhs), cst2ast(rhs), src=cover([lhs.src,rhs.src]));
    case (Expr)`<Expr lhs> || <Expr rhs>`: return or(cst2ast(lhs), cst2ast(rhs), src=cover([lhs.src,rhs.src]));
    case (Expr)`<Bool b>`: return boolean(fromString("<b>"), src=b.src);
    case (Expr)`<Int i>`: return integer(toInt("<i>"), src=i.src);
    case (Expr)`<Str s>`: return string("<s>", src=s.src);
    case (Expr)`<Id x>`: return ref(cst2ast(x), src=x.src);
    default: throw "Unhandled expression: <e>";
  }
}

default AType cst2ast(Type t) {
  throw "Not yet implemented <t>";
}

//new
default AId cst2ast(Id x) {
  return id("<x>", src=x.src);
}
