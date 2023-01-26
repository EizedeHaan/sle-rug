module Compile

import AST;
import Resolve;
import IO;
import lang::html::AST; // see standard library
import lang::html::IO;
import Boolean;

/*
 * Implement a compiler for QL to HTML and Javascript
 *
 * - assume the form is type- and name-correct
 * - separate the compiler in two parts form2html and form2js producing 2 files
 * - use string templates to generate Javascript
 * - use the HTMLElement type and the `str writeHTMLString(HTMLElement x)` function to format to string
 * - use any client web framework (e.g. Vue, React, jQuery, whatever) you like for event handling
 * - map booleans to checkboxes, strings to textfields, ints to numeric text fields
 * - be sure to generate uneditable widgets for computed questions!
 * - if needed, use the name analysis to link uses to definitions
 */

void compile(AForm f) {
  writeFile(f.src[extension="js"].top, form2js(f));
  writeFile(f.src[extension="html"].top, writeHTMLString(form2html(f)));
}

/**********Compile HTML**********/
HTMLElement form2html(AForm f) {
  list[HTMLElement] qList = [];
  for(q <- f.questions) {
    qList += question2html(q);
  }
  return html([
    head([
      title([text(f.name)])
      ]),
    body([
      h2([text(f.name)]),
      form(qList, onchange = "updateQL(this)")
    ])
  ]);
}

/*Normal questions*/
list[HTMLElement] question2html(Q(str question, AId var, integer())) {
  return [div([  
            label([text(question)], \for = var.name), br(),
            input(\type = "number", id = var.name, name = var.name), br()
          ])];
}

list[HTMLElement] question2html(Q(str question, AId var, boolean())) {
  return [div([
            label([text(question)]), br(),
            label([\text("True")], \for = var.name + "_true"),
            input(\type = "radio", id = var.name + "_true", name = var.name, \value = "true"), br(),
            label([\text("False")], \for = var.name + "_false"), 
            input(\type = "radio", id = var.name + "_false", name = var.name, \value = "false"), br()
          ])];
}

list[HTMLElement] question2html(Q(str question, AId var, string())) {
  return [div([
            label([text(question)], \for = var.name), br(),
            input(\type = "text", id = var.name, name = var.name), br()
          ])];
}

/*Computed questions*/
list[HTMLElement] question2html(computedQ(str question, AId var, integer(), AExpr e)) {
  return [div([
            label([text(question)], \for = var.name), br(),
            input(\type = "number", id = var.name, name = var.name, readonly = "true"), br()
          ])];
}

list[HTMLElement] question2html(computedQ(str question, AId var, boolean(), AExpr e)) {
  return [div([
            label([text(question)]), br(),
            label([\text("True")], \for = var.name + "_true"),
            input(\type = "radio", id = var.name + "_true", name = var.name, \value = "true", readonly = "true"), br(),
            label([\text("False")], \for = var.name + "_false"), 
            input(\type = "radio", id = var.name + "_false", name = var.name, \value = "false", readonly = "true"), br()
          ])];
}

list[HTMLElement] question2html(computedQ(str question, AId var, string(), AExpr e)) {
  return [div([
            label([text(question)], \for = var.name), br(),
            input(\type = "text", id = var.name, name = var.name, readonly = "true"), br()
          ])];
}

/*If statement questions*/
list[HTMLElement] question2html(ifQ(AExpr condition, list[AQuestion] ifQuestions)) {
  list[HTMLElement] combinedQuestions = [];
  for(q <- ifQuestions) {
    combinedQuestions += question2html(q);
  }
  return [fieldset(combinedQuestions, class = "ifQ:" + expr2str(condition))];
}

list[HTMLElement] question2html(ifElseQ(AExpr condition, list[AQuestion] ifQuestions, list[AQuestion] elseQuestions)) {
  list[HTMLElement] combinedIfQuestions = [];
  for(q <- ifQuestions) {
    combinedIfQuestions += question2html(q);
  }
  list[HTMLElement] combinedElseQuestions = [];
  for(q <- elseQuestions) {
    combinedElseQuestions += question2html(q);
  }
  return [fieldset([fieldset(combinedIfQuestions, class = "ifElseQ:" + expr2str(condition) + "_true"),
                    fieldset(combinedElseQuestions, class = "ifElseQ:" + expr2str(condition) + "_false")])];
}


/**********Compile Javascript**********/
str form2js(AForm f) {
  return "function updateQL(form) {
         '  //insert vars, update computedQs
         '  let f = new FormData(form);
         '  <variableAssignments2js(f.questions)>
          <for(q <- f.questions) {> 
            <if(ifQ(_,_) := q || ifElseQ(_,_,_) := q) {>
            '  <ifQ2js(q)>   
            <}><}>
         '}";
}

str ifQ2js(ifQ(AExpr condition, _)) {
  return "if(<expr2str(condition)>) {
         '  let qs = document.getElementsByClassName(\"<"ifQ:" + expr2str(condition)>\");
         '  for(q of qs) {
         '    q.removeAttribute(\"disabled\");
         '  }
         '} else {
         '  let qs = document.getElementsByClassName(\"<"ifQ:" + expr2str(condition)>\");
         '  for(q of qs) {
         '    q.setAttribute(\"disabled\", \"true\");
         '  }
         '}";
}

str ifQ2js(ifElseQ(AExpr condition, _, _)) {
  return "if(<expr2str(condition)>) {
         '  let qs = document.getElementsByClassName(\"<"ifElseQ:"+expr2str(condition)+"_true">\");
         '  for(q of qs) {
         '    q.removeAttribute(\"disabled\");
         '  }
         '  qs = document.getElementsByClassName(\"<"ifElseQ:"+expr2str(condition)+"_false">\");
         '  for(q of qs) {
         '    q.setAttribute(\"disabled\", \"true\");
         '  }
         '} else {
         '  let qs = document.getElementsByClassName(\"<"ifElseQ:"+expr2str(condition)+"_true">\");
         '  for(q of qs) {
         '    q.setAttribute(\"disabled\", \"true\");
         '  }
         '  qs = document.getElementsByClassName(\"<"ifElseQ:"+expr2str(condition)+"_false">\");
         '  for(q of qs) {
         '    q.removeAttribute(\"disabled\");
         '  }
         '}";
}

str variableAssignments2js(list[AQuestion] qs) {
  return "<for(q <- qs) {> <if(computedQ(_,_,_,_) !:= q) {> 
              '<assignVariable2js(q)><}><}>";
}

str assignVariable2js(Q(_,AId var, integer())) {
  return "let <var.name> = (f.has(\"<var.name>\") ? f.get(\"var.name\") : 0);";
}
str assignVariable2js(Q(_,AId var, boolean())) {
  return "let <var.name> = (f.get(\"<var.name>\") === \"true\");";
}
str assignVariable2js(Q(_,AId var, string())) {
  return "let <var.name> = (f.has(\"<var.name>\") ? f.get(\"var.name\") : \"\");";
}
str assignVariable2js(ifQ(_,list[AQuestion] ifQuestions)) {
  return variableAssignments2js(ifQuestions);
}
str assignVariable2js(ifElseQ(_,list[AQuestion] ifQuestions, list[AQuestion] elseQuestions)) {
  return variableAssignments2js(ifQuestions) + variableAssignments2js(elseQuestions);
}

//converts AExpr to JS expression in string form
str expr2str(AExpr e) {
  switch(e) {
    case parenthesis(AExpr expr): return "(" + expr2str(expr) + ")";
    case not(AExpr expr): return "!" + expr2str(expr);
    case mul(AExpr lhs, AExpr rhs): return expr2str(lhs) + "*" + expr2str(rhs);
    case div(AExpr lhs, AExpr rhs): return expr2str(lhs) + "/" + expr2str(rhs);
    case add(AExpr lhs, AExpr rhs): return expr2str(lhs) + "+" + expr2str(rhs);
    case sub(AExpr lhs, AExpr rhs): return expr2str(lhs) + "-" + expr2str(rhs);
    case less(AExpr lhs, AExpr rhs): return expr2str(lhs) + "\<" + expr2str(rhs);
    case leq(AExpr lhs, AExpr rhs): return expr2str(lhs) + "\<=" + expr2str(rhs);
    case greater(AExpr lhs, AExpr rhs): return expr2str(lhs) + "\>" + expr2str(rhs);
    case greq(AExpr lhs, AExpr rhs): return expr2str(lhs) + "\>=" + expr2str(rhs);
    case eq(AExpr lhs, AExpr rhs): return expr2str(lhs) + "===" + expr2str(rhs); //equal value and equal type operator
    case neq(AExpr lhs, AExpr rhs): return expr2str(lhs) + "!=" + expr2str(rhs);
    case and(AExpr lhs, AExpr rhs): return expr2str(lhs) + "&&" + expr2str(rhs);
    case or(AExpr lhs, AExpr rhs): return expr2str(lhs) + "||" + expr2str(rhs);
    case boolLit(bool b): return toString(b);
    case intLit(int i): return "<i>";
    case strLit(str s): return s;
    case ref(AId var): return var.name;
  }
  return "";
}