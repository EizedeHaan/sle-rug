module Transform

import Syntax;
import Resolve;
import AST;
import ParseTree;

/* 
 * Transforming QL forms
 */
 
 
/* Normalization:
 *  wrt to the semantics of QL the following
 *     q0: "" int; 
 *     if (a) { 
 *        if (b) { 
 *          q1: "" int; 
 *        } 
 *        q2: "" int; 
 *      }
 *
 *  is equivalent to
 *     if (true) q0: "" int;
 *     if (true && a && b) q1: "" int;
 *     if (true && a) q2: "" int;
 *
 * Write a transformation that performs this flattening transformation.
 *
 */
 
AForm flatten(AForm f) {
  list[AQuestion] qs = flatten(f.questions, boolLit(true));  
  return form(f.name, qs); 
}

list[AQuestion] flatten(list[AQuestion] qs, AExpr currentCondition) {
  list[AQuestion] result = [];
  for(q <- qs) {
    switch (q) {
      case ifQ(AExpr condition, list[AQuestion] ifQuestions): 
        result += flatten(ifQuestions, and(currentCondition, parenthesis(condition)));
      case ifElseQ(AExpr condition, list[AQuestion] ifQuestions, list[AQuestion] elseQuestions): {
        result += flatten(ifQuestions, and(currentCondition, parenthesis(condition)));
        result += flatten(elseQuestions, and(currentCondition, not(parenthesis(condition))));
      }
      case computedQ(_, _, _, _): 
        result += ifQ(currentCondition, [q]);
      case Q( _, _, _):
        result += ifQ(currentCondition, [q]);
    }
  }
  return result;
}

/* Rename refactoring:
 *
 * Write a refactoring transformation that consistently renames all occurrences of the same name.
 * Use the results of name resolution to find the equivalence class of a name.
 *
 */
 
start[Form] rename(start[Form] f, loc useOrDef, str newName, UseDef useDef) {
  set[loc] toRename = {};
  if(useOrDef in useDef<1>) {
    //we have a definition
    toRename += {useOrDef};
    toRename += { u | <u, useOrDef> <- useDef};
  }else if(useOrDef in useDef<0>) {
    //we have a use occurrence
    if(<useOrDef, loc d> <- useDef) {
      toRename += {d};
      toRename += { u | <u, d> <- useDef};
    }
  }else {
    return f;
  }
  return visit(f) {
    case Id x => [Id]newName
      when x.src in toRename
  }
} 
 
 
 

