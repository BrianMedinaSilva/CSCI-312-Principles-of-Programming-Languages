/* REFERENCE: K&R APPENDIX A */
%{
#include <stdio.h>

#define DUMP(class) printf("%s\t%s\n", class, yytext)

/* There are six classes of tokens: identifiers, keywords, constants, string literals, operators, and other separators. */
long num_identifiers = 0;
long num_keywords = 0;
long num_constants = 0;
long num_string_literals = 0;
long num_operators = 0;
long num_other_separators = 0;

long num_comments = 0;
long num_directives = 0;
%}

%option yylineno
%x COMMENT

/* An identifier is a sequence of letters and digits. The first character must be a letter; the underscore counts as a letter. Identifiers may have any length. */
IDENTIFIER              [[:alpha:]_][[:alnum:]_]*

/* The following identifiers are reserved for use as keywords, and may not be used otherwise. */
STORAGE_CLASS_SPECIFIER auto|extern|register|static|typedef
TYPE_SPECIFIER          char|double|enum|float|int|long|short|signed|struct|union|unsigned|void
TYPE_QUALIFIER          const|volatile
LABEL                   case|default
SELECTION_STATEMENT     if|else|switch
ITERATION_STATEMENT     do|for|while
JUMP_STATEMENT          goto|continue|break|return
STATEMENT               {SELECTION_STATEMENT}|{ITERATION_STATEMENT}|{JUMP_STATEMENT}
KEYWORD                 {STORAGE_CLASS_SPECIFIER}|{TYPE_SPECIFIER}|{TYPE_QUALIFIER}|{LABEL}|{STATEMENT}

/* An integer constant consisting of a sequence of digits is taken to be octal if it begins with 0, decimal otherwise. */
OCTAL_CONSTANT          0[0-7]+
DECIMAL                 0|[1-9][[:xdigit:]]*
/* A sequence of digits preceded by 0x or 0X is taken to be a hexadecimal integer. */
HEXADECIMAL_INTEGER     0[xX][0-9a-fA-F]+
/* An integer constant may be suffixed by the letter u or U (to specify that it is unsigned) or by the letter l or L (to specify that it is long). */
INTEGER_CONSTANT        ({OCTAL_CONSTANT}|{DECIMAL}|{HEXADECIMAL_INTEGER}([uU]([lL]{1,2})?|([lL]{1,2})[uU]?)?
/* To represent character constants, and certain other characters, the following escape sequences may be used. There is no limit on the number of digits. */
ESCAPE_SEQUENCE         \\([ntvbrfa\\?'"]|[0-7]{1,3}|x[[:xdigit:]]+)
/* A character constant is a sequence of one or more characters enclosed in single quotes, as in 'x'. Character constants do not contain ' or newlines. */
CHARACTER_CONSTANT      '({ESCAPE_SEQUENCE}|[^\\'\n])'
/* A floating constant consists of an integer part, a decimal point, a fraction part, (the integer and fraction parts both consist of a sequence of digits) ... */
FRACTION                ([[:digit:]]+\.[[:digit:]]*|[[:digit:]]*\.[[:digit:]]+)
/* ... an e or E, an optionally signed integer exponent ... */
EXPONENT                [eE][-+]?[[:digit:]]+
/* ... and an optional type suffix, one of f, F, l, or L. Either the integer part or the fraction part (not both) may be missing; either the decimal point or the e and the exponent (not both) may be missing. */
FLOATING_CONSTANT       ({FRACTION}{EXPONENT}?|[[:digit:]]+{EXPONENT})[fFlL]?
CONSTANT                {INTEGER_CONSTANT}|{CHARACTER_CONSTANT}|{FLOATING_CONSTANT}

/* A string literal, also called a string constant, is a sequence of characters surrounded by double quotes, as in "...". */
STRING_LITERAL          \"([^\n\\"]|{ESCAPE_SEQUENCE})*\"

OPERATOR_3              "<<="|">>="
OPERATOR_2              "++"|"--"|"<<"|">>"|"<="|">="|"=="|"!="|"&&"|"||"|"*="|"/="|"%="|"+="|"-="|"&="|"^="|"|="|"->"
OPERATOR_1              [+*/%<>=!&^~]
OPERATOR                {OPERATOR_3}|{OPERATOR_2}|{OPERATOR_1}

OTHER_SEPARATOR         [()\[\]{},;:]

DIRECTIVE               ^[[:space:]]*#[[:space:]]*.*

%%

{DIRECTIVE}             { puts("DIRECTIVE"); num_directives++; }

 /* \/\/ introduces a comment that includes all multibyte characters up to, but not including, the next new-line character. */
\/\/.*                  { puts("COMMENT"); num_comments++; }
 /* \/\* introduces a comment, which terminates with \*\/. Comments do not nest, and they do not occur within string or character literals. */
\/\*                    { BEGIN(COMMENT); puts("COMMENT"); num_comments++; }
<COMMENT>\*\/           BEGIN(INITIAL);
<COMMENT>\n             ;
<COMMENT>.              ;

{IDENTIFIER}            { DUMP("IDENTIFIER"); num_identifiers++; }

{STRING_LITERAL}        { puts("STRING_LITERAL"); num_string_literals++; }

{KEYWORD}               { DUMP("KEYWORD"); num_keywords++; }

{CONSTANT}              { DUMP("CONSTANT"); num_constants++; }

{OPERATOR_3}            { DUMP("OPERATOR"); num_operators++; }
{OPERATOR_2}            { DUMP("OPERATOR"); num_operators++; }
{OPERATOR_1}            { DUMP("OPERATOR"); num_operators++; }

{OTHER_SEPARATOR}       { DUMP("OTHER_SEPARATOR"); num_other_separators++; }

 /* Blanks, horizontal and vertical tabs, newlines, and formfeeds (collectively, "white space") are ignored except as they separate tokens. */
[[:space:]]+            { /* ignore whitespace */ }

.                       printf("Unrecognized character on line %d: %s\n", yylineno, yytext);

%%

int yywrap(){}

int main(int argc, char *argv[])
{
    yylex();

    FILE *fp;
    char *fname = "frequency-classes.tsv";

    if ((fp = fopen(fname, "w")) == NULL) {
        fprintf(stderr, "%s: can't open %s\n", __func__, fname);
        exit(1);
    }

    fprintf(fp, "IDENTIFIERS:\t%ld\n", num_identifiers);
    fprintf(fp, "KEYWORDS:\t%ld\n", num_keywords);
    fprintf(fp, "CONSTANTS:\t%ld\n", num_constants);
    fprintf(fp, "STRING_LITERALS:\t%ld\n", num_string_literals);
    fprintf(fp, "OPERATORS:\t%ld\n", num_operators);
    fprintf(fp, "OTHER_SEPARATORS:\t%ld\n", num_other_separators);
    fprintf(fp, "COMMENTS:\t%ld\n", num_comments);
    fprintf(fp, "DIRECTIVES:\t%ld\n", num_directives);

    fclose(fp);

    return 0;
}
