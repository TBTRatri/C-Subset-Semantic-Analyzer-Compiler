%{

#include "symbol_table.h"
#include <cstring>
#include <iostream>
#include <vector>
#include <string>

#define YYSTYPE symbol_info*

using namespace std;

extern FILE *yyin;
int yyparse(void);
int yylex(void);
extern YYSTYPE yylval;

// symbol table instance
symbol_table *table;

// global variables for tracking state
string current_type;
vector<pair<string, string>> current_func_params;

int lines = 1;
ofstream outlog;

void yyerror(const char *s)
{
    outlog << "Error at line " << lines << ": " << s << endl << endl;
}

// Fixed: Directly pass the string name to lookup
bool is_function_declared(string name) {
    symbol_info* result = table->lookup(name); 
    return (result != nullptr && result->get_is_function());
}

// Fixed: Directly pass the string name to local lookup
bool is_variable_declared_current_scope(string name) {
    symbol_info* result = table->lookup_current_scope(name);
    return (result != nullptr);
}

%}

%token IF ELSE FOR WHILE DO BREAK INT CHAR FLOAT DOUBLE VOID RETURN SWITCH CASE DEFAULT CONTINUE PRINTLN ADDOP MULOP INCOP DECOP RELOP ASSIGNOP LOGICOP NOT LPAREN RPAREN LCURL RCURL LTHIRD RTHIRD COMMA SEMICOLON CONST_INT CONST_FLOAT ID

%nonassoc LOWER_THAN_ELSE
%nonassoc ELSE

%%

start : program
    {
        outlog << "At line no: " << lines << " start : program " << endl << endl;
    }
    ;

program : program unit
    {
        outlog << "At line no: " << lines << " program : program unit " << endl << endl;
        $$ = new symbol_info($1->getname() + "\n" + $2->getname(), "program");
    }
    | unit
    {
        outlog << "At line no: " << lines << " program : unit " << endl << endl;
        $$ = new symbol_info($1->getname(), "program");
    }
    ;

unit : var_declaration | func_definition ;

func_definition : type_specifier ID LPAREN parameter_list RPAREN 
        {
            // Insert function into current (global) scope
            if(!is_function_declared($2->getname())){
                symbol_info* func = new symbol_info($2->getname(), "ID", $1->getname());
                func->set_as_function($1->getname(), current_func_params);
                table->insert(func); 
            }
        } 
        compound_statement
        {   
            outlog << "At line no: " << lines << " func_definition : type_specifier ID LPAREN parameter_list RPAREN compound_statement " << endl << endl;
            $$ = new symbol_info($1->getname() + " " + $2->getname() + "(" + $4->getname() + ")" + $7->getname(), "func_def");    
            current_func_params.clear();
        }
        ;

parameter_list : parameter_list COMMA type_specifier ID
        {
            $$ = new symbol_info($1->getname() + "," + $3->getname() + " " + $4->getname(), "param_list");
            current_func_params.push_back({$3->getname(), $4->getname()});
        }
        | type_specifier ID
        {
            $$ = new symbol_info($1->getname() + " " + $2->getname(), "param_list");
            current_func_params.push_back({$1->getname(), $2->getname()});
        }
        | type_specifier 
        { 
            $$ = new symbol_info($1->getname(), "param_list"); 
            current_func_params.push_back({$1->getname(), ""});
        }
        | { $$ = new symbol_info("", "param_list"); }
        ;

compound_statement : LCURL 
    {
        table->enter_scope(); 
        outlog << "New scope entered with ID " << table->get_current_scope_id() << endl;
        
        for(auto p : current_func_params) {
            if(p.second != "") {
                table->insert(new symbol_info(p.second, "ID", p.first));
            }
        }
    } 
    statements RCURL
    { 
        outlog << "At line no: " << lines << " compound_statement : LCURL statements RCURL " << endl << endl;
        table->print_all_scopes(outlog); 
        outlog << "Scope with ID " << table->get_current_scope_id() << " removed" << endl;
        table->exit_scope(); 
        $$ = new symbol_info("{\n" + $3->getname() + "\n}", "comp_stmnt");
    }
    | LCURL { 
        table->enter_scope(); 
    } RCURL
    {
        table->print_all_scopes(outlog);
        table->exit_scope();
        $$ = new symbol_info("{}", "comp_stmnt");
    }
    ;

var_declaration : type_specifier declaration_list SEMICOLON
         {
            outlog << "At line no: " << lines << " var_declaration : type_specifier declaration_list SEMICOLON " << endl << endl;
            $$ = new symbol_info($1->getname() + " " + $2->getname() + ";", "var_dec");
         }
         ;

type_specifier : INT   { $$ = new symbol_info("int", "type"); current_type = "int"; }
               | FLOAT { $$ = new symbol_info("float", "type"); current_type = "float"; }
               | VOID  { $$ = new symbol_info("void", "type"); current_type = "void"; }
               ;

declaration_list : declaration_list COMMA ID
          {
            if(!is_variable_declared_current_scope($3->getname())) {
                table->insert(new symbol_info($3->getname(), "ID", current_type));
            }
            $$ = new symbol_info($1->getname() + "," + $3->getname(), "decl_list");
          }
          | declaration_list COMMA ID LTHIRD CONST_INT RTHIRD
          {
            if(!is_variable_declared_current_scope($3->getname())) {
                symbol_info* s = new symbol_info($3->getname(), "ID", current_type);
                s->set_array_size(stoi($5->getname()));
                table->insert(s);
            }
            $$ = new symbol_info($1->getname() + "," + $3->getname() + "[" + $5->getname() + "]", "decl_list");
          }
          | ID
          {
            if(!is_variable_declared_current_scope($1->getname())) {
                table->insert(new symbol_info($1->getname(), "ID", current_type));
            }
            $$ = new symbol_info($1->getname(), "decl_list");
          }
          | ID LTHIRD CONST_INT RTHIRD
          {
            if(!is_variable_declared_current_scope($1->getname())) {
                symbol_info* s = new symbol_info($1->getname(), "ID", current_type);
                s->set_array_size(stoi($3->getname()));
                table->insert(s);
            }
            $$ = new symbol_info($1->getname() + "[" + $3->getname() + "]", "decl_list");
          }
          ;

statements : statement { $$ = new symbol_info($1->getname(), "stmnts"); }
           | statements statement { $$ = new symbol_info($1->getname() + "\n" + $2->getname(), "stmnts"); }
           ;

statement : var_declaration | expression_statement | compound_statement | RETURN expression SEMICOLON 
          { 
              $$ = new symbol_info("return " + $2->getname() + ";", "stmnt"); 
          }
          | IF LPAREN expression RPAREN statement %prec LOWER_THAN_ELSE
          {
              $$ = new symbol_info("if(" + $3->getname() + ")\n" + $5->getname(), "stmnt");
          }
          | WHILE LPAREN expression RPAREN statement
          {
              $$ = new symbol_info("while(" + $3->getname() + ")\n" + $5->getname(), "stmnt");
          }
          | FOR LPAREN expression_statement expression_statement expression RPAREN statement
          {
              $$ = new symbol_info("for(" + $3->getname() + $4->getname() + $5->getname() + ")\n" + $7->getname(), "stmnt");
          }
          ;

expression_statement : SEMICOLON { $$ = new symbol_info(";", "expr_stmt"); }
                     | expression SEMICOLON { $$ = new symbol_info($1->getname() + ";", "expr_stmt"); }
                     ;

expression : logic_expression { $$ = new symbol_info($1->getname(), "expr"); }
           | variable ASSIGNOP logic_expression { $$ = new symbol_info($1->getname() + "=" + $3->getname(), "expr"); }
           ;

logic_expression : rel_expression { $$ = new symbol_info($1->getname(), "lgc_expr"); }
                 ;

rel_expression : simple_expression { $$ = new symbol_info($1->getname(), "rel_expr"); }
               | simple_expression RELOP simple_expression { $$ = new symbol_info($1->getname() + $2->getname() + $3->getname(), "rel_expr"); }
               ;

simple_expression : term { $$ = new symbol_info($1->getname(), "simp_expr"); }
                  | simple_expression ADDOP term { $$ = new symbol_info($1->getname() + $2->getname() + $3->getname(), "simp_expr"); }
                  ;

term : unary_expression { $$ = new symbol_info($1->getname(), "term"); }
     | term MULOP unary_expression { $$ = new symbol_info($1->getname() + $2->getname() + $3->getname(), "term"); }
     ;

unary_expression : factor { $$ = new symbol_info($1->getname(), "un_expr"); }
                 | ADDOP unary_expression { $$ = new symbol_info($1->getname() + $2->getname(), "un_expr"); }
                 | NOT unary_expression { $$ = new symbol_info("!" + $2->getname(), "un_expr"); }
                 ;

factor : variable { $$ = new symbol_info($1->getname(), "fctr"); }
       | CONST_INT { $$ = new symbol_info($1->getname(), "fctr"); }
       | CONST_FLOAT { $$ = new symbol_info($1->getname(), "fctr"); }
       | LPAREN expression RPAREN { $$ = new symbol_info("(" + $2->getname() + ")", "fctr"); }
       | ID LPAREN argument_list RPAREN { $$ = new symbol_info($1->getname() + "(" + $3->getname() + ")", "fctr"); }
       | variable INCOP { $$ = new symbol_info($1->getname() + "++", "fctr"); }
       | variable DECOP { $$ = new symbol_info($1->getname() + "--", "fctr"); }
       ;

argument_list : arguments { $$ = new symbol_info($1->getname(), "arg_list"); }
              | { $$ = new symbol_info("", "arg_list"); }
              ;

arguments : arguments COMMA logic_expression
          {
              $$ = new symbol_info($1->getname() + "," + $3->getname(), "arg");
          }
          | logic_expression
          {
              $$ = new symbol_info($1->getname(), "arg");
          }
          ;

variable : ID { $$ = new symbol_info($1->getname(), "varbl"); }
         | ID LTHIRD expression RTHIRD { $$ = new symbol_info($1->getname() + "[" + $3->getname() + "]", "varbl"); }
         ;

%%

int main(int argc, char *argv[])
{
    if(argc != 2) 
    {
        cout << "Usage: ./a.out <input_file>" << endl;
        return 0;
    }
    yyin = fopen(argv[1], "r");
    outlog.open("22101869_log.txt", ios::trunc); 
    
    if(yyin == NULL)
    {
        cout << "Couldn't open file" << endl;
        return 0;
    }

    table = new symbol_table(10); 
    yyparse();
    
    outlog << endl << "Total lines: " << lines << endl;
    
    delete table;
    outlog.close();
    fclose(yyin);
    
    return 0;
}
