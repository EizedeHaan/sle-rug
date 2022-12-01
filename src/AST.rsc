module AST

/*
 * Define Abstract Syntax for QL
 *
 * - complete the following data types
 * - make sure there is an almost one-to-one correspondence with the grammar
 */

data AForm(loc src = |tmp:///|)
  = form(str name, list[AQuestion] questions)
  ; 

data AQuestion(loc src = |tmp:///|)
  = ifElseQ(AExpr condition, list[AQuestion] ifQuestions, list[AQuestion] elseQuestions)
  | ifQ(AExpr condition, list[AQuestion] ifQuestions)
  | computedQ(str question, AId var, AType typ, AExpr expr)
  | Q(str question, AId var, AType typ)
  ; 

data AExpr(loc src = |tmp:///|)
  = parenthesis(AExpr expr)
  | not(AExpr expr)
  | mul(AExpr lhs, AExpr rhs)
  | div(AExpr lhs, AExpr rhs)
  | add(AExpr lhs, AExpr rhs)
  | sub(AExpr lhs, AExpr rhs)
  | less(AExpr lhs, AExpr rhs)
  | leq(AExpr lhs, AExpr rhs)
  | greater(AExpr lhs, AExpr rhs)
  | greq(AExpr lhs, AExpr rhs)
  | eq(AExpr lhs, AExpr rhs)
  | neq(AExpr lhs, AExpr rhs)
  | and(AExpr lhs, AExpr rhs)
  | or(AExpr lhs, AExpr rhs)
  | boolean(bool b)
  | integer(int i)
  | string(str s)
  | ref(AId id)
  ;


data AId(loc src = |tmp:///|)
  = id(str name);

data AType(loc src = |tmp:///|)
  = typ(str typ);