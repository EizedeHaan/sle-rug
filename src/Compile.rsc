module Compile

import AST;
import Resolve;
import IO;
import lang::html::AST; // see standard library
import lang::html::IO;

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

HTMLElement form2html(AForm f) {
  return html([
    head([
      title([text(f.name)])
      ]),
    body([
      h2([text(f.name)]),
      form([])
    ])
  ]);
}

/*Normal questions*/
list[HTMLElement] question2html(Q(str question, AId var, integer())) {
  return [label([text(question)], \for = var.name), br(),
          input(\type = "number", id = var.name, name = var.name), br()];
}

list[HTMLElement] question2html(Q(str question, AId var, boolean())) {
  return [label([text(question)]), br(),
          label([\text("True")]), input(\type = "radio", id = var.name, name = var.name, \value = "true"), br(),
          label([\text("False")]), input(\type = "radio", id = var.name, name = var.name, \value = "false"), br()];
}

list[HTMLElement] question2html(Q(str question, AId var, string())) {
  return [label([text(question)], \for = var.name), br(),
          input(\type = "text", id = var.name, name = var.name), br()];
}

/*Computed questions*/
list[HTMLElement] question2html(computedQ(str question, AId var, integer(), AExpr e)) {
  return [label([text(question)], \for = var.name), br(),
          input(\type = "number", id = var.name, name = var.name, readonly = "true"), br()];
}

list[HTMLElement] question2html(computedQ(str question, AId var, boolean(), AExpr e)) {
  return [label([text(question)]), br(),
          label([\text("True")]), input(\type = "radio", id = var.name, name = var.name, \value = "true", readonly = "true"), br(),
          label([\text("False")]), input(\type = "radio", id = var.name, name = var.name, \value = "false", readonly = "true"), br()];
}

list[HTMLElement] question2html(computedQ(str question, AId var, string(), AExpr e)) {
  return [label([text(question)], \for = var.name), br(),
          input(\type = "text", id = var.name, name = var.name, readonly = "true"), br()];
}

/*If statement questions*/
list[HTMLElement] question2html(ifQ(AExpr condition, list[AQuestion] ifQuestions)) {
  list[HTMLElement] combinedQuestions = [];
  for(q <- ifQuestions) {
    combinedQuestions += question2html(q);
  }
  return [fieldset(combinedQuestions)];
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
  return [fieldset([fieldset(combinedIfQuestions),fieldset(combinedElseQuestions)])];
}

str form2js(AForm f) {
  return "";
}
