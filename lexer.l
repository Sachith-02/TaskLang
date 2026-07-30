%{
#include "parser.tab.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

int yyline = 1;
int lex_error_count = 0;

#define MAX_IDENTIFIER_LENGTH 127
#define MAX_STRING_LENGTH     255

static void lex_error(const char *msg, const char *text);
void skip_to_line_end(void);
%}

%option noyywrap
%option nounput

/* Shared patterns. TIME accepts only 00:00 through 23:59. */
DIGIT       [0-9]
LETTER      [a-zA-Z]
IDENT_CHAR  [a-zA-Z0-9_]
IDENT       ({LETTER}|_){IDENT_CHAR}*
TIME        ([01][0-9]|2[0-3]):[0-5][0-9]
BAD_TIME    [0-9]{1,2}:[0-9]{1,2}
STRING      \"[^"\n]*\"
WS          [ \t]+

%%

 /* Comments */
"#"[^\n]*               { }

 /* Keywords: keep before IDENT so reserved words are not task or event names. */
"TASK"                  { return TASK;    }
"RUN"                   { return RUN;     }
"EVERY"                 { return EVERY;   }
"DAY"                   { return DAY;     }
"WEEK"                  { return WEEK;    }
"ON"                    { return ON;      }
"AT"                    { return AT;      }
"AFTER"                 { return AFTER;   }
"BEFORE"                { return BEFORE;  }
"DEPENDS"               { return DEPENDS; }
"IF"                    { return IF;      }
"WHEN"                  { return WHEN;    }
"success"               { return SUCCESS; }
"failure"               { return FAILURE; }

 /* Day-name keywords for weekly schedules. */
"MONDAY"                { return MONDAY;    }
"TUESDAY"               { return TUESDAY;   }
"WEDNESDAY"             { return WEDNESDAY; }
"THURSDAY"              { return THURSDAY;  }
"FRIDAY"                { return FRIDAY;    }
"SATURDAY"              { return SATURDAY;  }
"SUNDAY"                { return SUNDAY;    }

 /* Literals */
{TIME}                  {
                            yylval.str = strdup(yytext);
                            return TIME_VAL;
                        }

{BAD_TIME}              {
                            lex_error("Invalid time format", yytext);
                            return INVALID_TIME;
                        }

{STRING}                {
                            int len = strlen(yytext) - 2;
                            if (len > MAX_STRING_LENGTH)
                                lex_error("String literal exceeds maximum "
                                          "length of 255 characters", yytext);
                            yylval.str = strndup(yytext + 1, len);
                            return STRING_LIT;
                        }

 /* Identifiers are used for task names and event names such as WHEN push. */
{IDENT}                 {
                            if (yyleng > MAX_IDENTIFIER_LENGTH)
                                lex_error("Identifier exceeds maximum length "
                                          "of 127 characters", yytext);
                            yylval.str = strdup(yytext);
                            return IDENTIFIER;
                        }

 /* Punctuation */
"{"                     { return LBRACE; }
"}"                     { return RBRACE; }

 /* Whitespace */
\r?\n                   { yyline++; }

{WS}                    { }

 /* Lexical errors */
\"[^"\n]*               {
                            lex_error("Unterminated string literal", yytext);
                            yylval.str = strdup(yytext + 1);
                            return STRING_LIT;
                        }

.                       {
                            char msg[64];
                            snprintf(msg, sizeof msg,
                                     "Unexpected character '%s'", yytext);
                            lex_error(msg, yytext);
                        }

%%

static void lex_error(const char *msg, const char *text)
{
    fprintf(stderr, "[Lexical Error] Line %d: %s (got: '%s')\n",
            yyline, msg, text);
    lex_error_count++;
}

void skip_to_line_end(void)
{
    int c;

    while ((c = input()) != 0) {
        if (c == '\n') {
            yyline++;
            break;
        }
    }
}
