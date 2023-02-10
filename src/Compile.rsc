module Compile

import AST;
import Resolve;
import IO;
import lang::html::AST; // see standard library
import lang::html::IO;
import Boolean;
import String;

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
    ], onload = "updateQL(document.forms[0])"),
    script([], src = f.src[extension="js"].file)
  ]);
}

/*Normal questions*/
list[HTMLElement] question2html(Q(str question, AId var, integer())) {
  return [div([  
            label([text(question)], \for = var.name), br(),
            input(\type = "number", class = var.name, name = var.name), br()
          ])];
}

list[HTMLElement] question2html(Q(str question, AId var, boolean())) {
  return [div([
            label([text(question)], \for = var.name), br(),
            label([\text("True")], \for = var.name),
            input(\type = "checkbox", class = var.name, name = var.name, \value = "true"), br()
          ])];
}

list[HTMLElement] question2html(Q(str question, AId var, string())) {
  return [div([
            label([text(question)], \for = var.name), br(),
            input(\type = "text", class = var.name, name = var.name), br()
          ])];
}

/*Computed questions*/
list[HTMLElement] question2html(computedQ(str question, AId var, integer(), AExpr e)) {
  return [div([
            label([text(question)], \for = var.name), br(),
            input(\type = "number", class = var.name, name = var.name, readonly = "true"), br()
          ])];
}

list[HTMLElement] question2html(computedQ(str question, AId var, boolean(), AExpr e)) {
  return [div([
            label([text(question)], \for = var.name), br(),
            label([\text("True")], \for = var.name),
            input(\type = "checkbox", class = var.name, name = var.name, \value = "true", readonly = "true"), br()
          ])];
}

list[HTMLElement] question2html(computedQ(str question, AId var, string(), AExpr e)) {
  return [div([
            label([text(question)], \for = var.name), br(),
            input(\type = "text", class = var.name, name = var.name, readonly = "true"), br()
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
  //src arrEquals: https://masteringjs.io/tutorials/fundamentals/compare-arrays
  return "function arrEquals(a,b) {
         '  return a.length === b.length &&
         '         a.every((val, index) =\> val === b[index]);
         '}
         '
         'function updateQL(form) {
         '  //get values from form
         '  let $f = new FormData(form);
         '  <variableAssignments2js(f)>
         '  
         '  //Recalculate values of computedQuestions
         '  let $prevComputed = [];
         '  do {
         '    $prevComputed = <computedQs2jsArr(f)>;
         '    <evalComputedQs2js(f.questions)>      
         '  }while(!arrEquals(<computedQs2jsArr(f)>, $prevComputed));
         '
         '  //Update form
         '  <updateFormVals2js(f)>
         '  <ifQ2js(f)>
         '}";
}

//Initialises variables from questions and gets values from HTML form.
str variableAssignments2js(AForm f) {
  str assignments = "";
  list[str] added = [];
  visit(f) {
    case Q(_,AId var, integer()): {
      if(var.name notin added) {
        assignments += "let <var.name> = ($f.has(\"<var.name>\") ? $f.getAll(\"<var.name>\")[$f.getAll(\"<var.name>\").length-1] : 0);\n";
        added += var.name;
      }
    }
    case Q(_,AId var, boolean()): {
      if(var.name notin added) {
        assignments += "let <var.name> = ($f.getAll(\"<var.name>\")[$f.getAll(\"<var.name>\").length-1] === \"true\");\n";
        added += var.name;
      }
    }
    case Q(_,AId var, string()): {
      if(var.name notin added) {
        assignments += "let <var.name> = ($f.has(\"<var.name>\") ? $f.getAll(\"<var.name>\")[$f.getAll(\"<var.name>\").length-1] : \"\");\n";
        added += var.name;
      }
    }
    case computedQ(_,AId var, integer(),_): {
      if(var.name notin added) {
        assignments += "let <var.name> = ($f.has(\"<var.name>\") ? $f.getAll(\"<var.name>\")[$f.getAll(\"<var.name>\").length-1] : 0);\n";
        added += var.name;
      }
    }
    case computedQ(_,AId var, boolean(),_): {
      if(var.name notin added) {
        assignments += "let <var.name> = ($f.getAll(\"<var.name>\")[$f.getAll(\"<var.name>\").length-1] === \"true\");\n";
        added += var.name;
      }
    }
    case computedQ(_,AId var, string(),_): {
      if(var.name notin added) {
        assignments += "let <var.name> = ($f.has(\"<var.name>\") ? $f.getAll(\"<var.name>\")[$f.getAll(\"<var.name>\").length-1] : \"\");\n";
        added += var.name;
      }
    }
  }
  return assignments;
}


/*Creates a Javascript array containing the values
  of the variables from the computed questions.*/
str computedQs2jsArr(AForm f) {
  list[str] vars = [];
  for(/computedQ(_,AId var,_,_) := f) {
    vars += var.name;
  }
  if(vars == []) {
    return "[]";
  }
  str res = "[";
  for(v <- vars) {
    res += v + ",";
  }
  res = replaceLast(res, ",", "]");
  return res;
}


/*Implements the recalculation of the values for the variables of the computed questions,
  if they are enabled. If a variable should be recalculated depends
  on the conditions in if and if/else statements.*/
str evalComputedQs2js(list[AQuestion] qs) {
  str evals = "";
  for(q <- qs) {
    switch(q) {
      case computedQ(_,AId var,_,AExpr e): 
        evals += "<var.name> = <expr2str(e)>;\n";
      case ifQ(AExpr condition, list[AQuestion] ifQuestions): {
        evals += "if(<expr2str(condition)>) {
                 '  <evalComputedQs2js(ifQuestions)>
                 '}\n";
      }
      case ifElseQ(AExpr condition, list[AQuestion] ifQuestions, list[AQuestion] elseQuestions): {
        evals += "if(<expr2str(condition)>) {
                 '  <evalComputedQs2js(ifQuestions)>
                 '}else {
                 '  <evalComputedQs2js(elseQuestions)>
                 '}\n";
      }
    }
  }
  return evals;
}


/*Creates lines for each computed question in the HTML form,
  in order to update its variables over all questions.*/
str updateFormVals2js(AForm f) {
  str lines = "let $qs;\n";
  visit(f) {
    case computedQ(_,AId var, boolean(),_):
      lines += "$qs = document.getElementsByClassName(\"<var.name>\");
               'for($q of $qs) {
               '  $q.checked = <var.name>;  
               '}\n";
    case computedQ(_,AId var,_,_):
      lines += "$qs = document.getElementsByClassName(\"<var.name>\");
               'for($q of $qs) {
               '  $q.value = <var.name>;  
               '}\n";
  }
  return lines;
}


str ifQ2js(AForm f) {
  str ifs = "";
  visit(f) {
    case q: ifQ(_,_):
      ifs += ifQ2js(q) + "\n";
    case q: ifElseQ(_,_,_):
      ifs += ifQ2js(q) + "\n";
  }
  return ifs;
}

/*Disables/enables <fieldset> HTML elements based on the condition.
  The fieldset contains the questions bound by the condition.*/
str ifQ2js(ifQ(AExpr condition, list[AQuestion] ifQuestions)) {
  return "if(<expr2str(condition)>) {
         '  let $qs = document.getElementsByClassName(\"<"ifQ:" + expr2str(condition)>\");
         '  for($q of $qs) {
         '    $q.removeAttribute(\"disabled\");
         '  }
         '}else {
         '  let $qs = document.getElementsByClassName(\"<"ifQ:" + expr2str(condition)>\");
         '  for($q of $qs) {
         '    $q.setAttribute(\"disabled\", \"true\");
         '  }
         '}";
}

/*Disables/enables <fieldset> HTML elements based on the condition.
  The fieldsets contain the questions bound by the condition.
  Both the ifQuestions and elseQuestions are contained in their own fieldset.*/
str ifQ2js(ifElseQ(AExpr condition, list[AQuestion] ifQuestions, list[AQuestion] elseQuestions)) {
  return "if(<expr2str(condition)>) {
         '  let $qs = document.getElementsByClassName(\"<"ifElseQ:"+expr2str(condition)+"_true">\");
         '  for($q of $qs) {
         '    $q.removeAttribute(\"disabled\");
         '  }
         '  $qs = document.getElementsByClassName(\"<"ifElseQ:"+expr2str(condition)+"_false">\");
         '  for($q of $qs) {
         '    $q.setAttribute(\"disabled\", \"true\");
         '  }
         '}else {
         '  let $qs = document.getElementsByClassName(\"<"ifElseQ:"+expr2str(condition)+"_true">\");
         '  for($q of $qs) {
         '    $q.setAttribute(\"disabled\", \"true\");
         '  }
         '  $qs = document.getElementsByClassName(\"<"ifElseQ:"+expr2str(condition)+"_false">\");
         '  for($q of $qs) {
         '    $q.removeAttribute(\"disabled\");
         '  }
         '}";
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