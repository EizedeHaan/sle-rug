module Syntax

extend lang::std::Layout;
extend lang::std::Id;

/*
 * Concrete syntax of QL
 */

start syntax Form 
  = "form" Id name "{" Question* questions "}"; 

// TODO: question, computed question, block, if-then-else, if-then
syntax Question 
  = "if" "(" Expr ")" "{" Question* ifQuestions "}" "else" "{" Question* elseQuestions "}"
  | "if" "(" Expr ")" "{" Question* ifQuestions "}"
  | Str question Id var ":" Type "=" Expr
  | Str question Id var ":" Type;

// TODO: +, -, *, /, &&, ||, !, >, <, <=, >=, ==, !=, literals (bool, int, str)
// Think about disambiguation using priorities and associativity
// and use C/Java style precedence rules (look it up on the internet)
syntax Expr 
  = left "(" Expr ")"
  > right "!" Expr
  > left Expr "*" Expr
  | left Expr "/" Expr 
  > left Expr "+" Expr
  | left Expr "-" Expr
  > left Expr "\<" Expr
  | left Expr "\<=" Expr
  | left Expr "\>" Expr
  | left Expr "\>=" Expr
  > left Expr "==" Expr
  | left Expr "!=" Expr
  > left Expr "&&" Expr
  > left Expr "||" Expr
  | "(" (Bool | Int | Str) ")"
  | Bool //does this belong to Expr?
  | Int
  | Id var \ "true" \ "false" // true/false are reserved keywords.
  ;
  
syntax Type 
= "integer"
| "boolean"
| "string";

lexical Str = [\"][a-zA-Z0-9?~!@#$%€^&*()_\-+=:;.,/ \ ]+[\"];

lexical Int 
  = [\-]?[0-9]+;

lexical Bool 
= "true"
| "false";



