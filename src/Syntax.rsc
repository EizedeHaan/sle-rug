module Syntax

extend lang::std::Layout;
extend lang::std::Id;

/*
 * Concrete syntax of QL
 */

start syntax Form 
  = "form" Id "{" Question* "}"; 

// TODO: question, computed question, block, if-then-else, if-then
syntax Question
  = "\""Str"\"" Id":" Type "=" Expr			//computed question
  | "\""Str"\"" Id":" Type					//normal question
  | "if" "(" Expr ")" Block "else" Block	//if-then-else
  > "if" "(" Expr ")" Block					//if-then
  ; 
  
syntax Block
  = "{" Question* "}";

// TODO: +, -, *, /, &&, ||, !, >, <, <=, >=, ==, !=, literals (bool, int, str)
// Think about disambiguation using priorities and associativity
// and use C/Java style precedence rules (look it up on the internet)
syntax Expr 
  = left "(" Expr ")"
  > right "!"Expr
  > left Expr "*" Expr
  > left Expr "/" Expr
  > left Expr "+" Expr
  > left Expr "-" Expr
  > left Expr "\<" Expr
  > left Expr "\<=" Expr
  > left Expr "\>" Expr
  > left Expr "\>=" Expr
  > left Expr "==" Expr
  > left Expr "!=" Expr
  > left Expr "&&" Expr
  > left Expr "||" Expr
  > Int
  | Bool
  | Id \ "true" \ "false" // true/false are reserved keywords.
  ;
  
syntax Type
  = "integer"
  | "double"
  | "string"
  | "boolean"
  ;  
  
lexical Str = [a-zA-Z0-9?~`!@#$%^&*()\-_+=:;.,/ \ ]+;

lexical Int 
  = [\-]?[0-9]+;

lexical Bool = "true" | "false";



