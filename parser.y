%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define MAX_TASKS   64
#define MAX_DEPS    16
#define MAX_NAME    128
#define MAX_SCRIPT  256
#define MAX_SCHED   160
#define MAX_COND    64

typedef struct {
    char name[MAX_NAME];
    char script[MAX_SCRIPT];
    char schedule[MAX_SCHED];
    char depends_on[MAX_DEPS][MAX_NAME];
    int  dep_count;
    char before_tasks[MAX_DEPS][MAX_NAME];
    int  before_count;
    char condition[MAX_COND];
    int  visited;
    int  in_stack;
} Task;

static Task  tasks[MAX_TASKS];
static int   task_count = 0;
static int   parse_errors = 0;

static char  cur_name[MAX_NAME];
static char  cur_script[MAX_SCRIPT];
static int   cur_run_seen;
static char  cur_schedule[MAX_SCHED];
static char  cur_deps[MAX_DEPS][MAX_NAME];
static int   cur_dep_count;
static char  cur_before[MAX_DEPS][MAX_NAME];
static int   cur_before_count;
static char  cur_condition[MAX_COND];

void yyerror(const char *msg);
int  yylex(void);
extern int yyline;
extern int lex_error_count;
void skip_to_line_end(void);

static void begin_task(const char *name);
static void end_task(void);
static void set_script(const char *s);
static void set_schedule(const char *s);
static void add_dependency(const char *dep);
static void add_before_task(const char *task_name);
static void set_condition(const char *cond);

static int  find_task(const char *name);
static int  current_dependency_exists(const char *dep);
static int  current_before_exists(const char *task_name);
static int  add_dependency_to_task(Task *task, const char *dep);
static void apply_before_dependencies(void);
static void validate_condition_dependencies(void);
static void run_simulation(void);
static void print_task(const Task *t);
%}

%union {
    char *str;
}

%destructor { free($$); } <str>

%token YYEOF 0 "end of file"
%token TASK RUN EVERY DAY WEEK ON AFTER BEFORE DEPENDS IF WHEN
%token SUCCESS FAILURE LBRACE RBRACE
%token MONDAY TUESDAY WEDNESDAY THURSDAY FRIDAY SATURDAY SUNDAY
%token INVALID_TIME

%token <str> IDENTIFIER STRING_LIT TIME_VAL

%type <str> day_of_week schedule_expr condition_clause

%precedence DAY_ONLY
%precedence AT

%define parse.error verbose

%%

program
    : task_list
    | %empty
        {
            fprintf(stderr,
                "[Syntax Error] Empty input. Expected at least one task.\n");
            parse_errors++;
        }
    ;

task_list
    : task_definition
    | task_list task_definition
    ;

task_definition
    : TASK IDENTIFIER LBRACE
        { begin_task($2); }
      task_body
      RBRACE
        { end_task(); free($2); }

    | TASK error RBRACE
        {
            fprintf(stderr,
                "[Syntax Error] Line %d: Malformed task definition. "
                "Expected: TASK <name> { ... }\n", yyline);
            parse_errors++;
            yyclearin;
            yyerrok;
        }
    ;

task_body
    : statement_list
    | %empty
    ;

statement_list
    : statement
    | statement_list statement
    ;

statement
    : run_statement
    | schedule_statement
    | dependency_statement
    | condition_statement
    | error
        {
            if (yychar == YYEOF) {
                fprintf(stderr,
                    "[Syntax Error] Line %d: Missing closing brace '}' "
                    "before end of file in task '%s'.\n", yyline, cur_name);
                parse_errors++;
                YYABORT;
            }
            fprintf(stderr,
                "[Syntax Error] Line %d: Unrecognised statement inside "
                "task body.\n", yyline);
            parse_errors++;
            if (yychar != RBRACE && yychar != YYEOF) {
                skip_to_line_end();
                yyclearin;
            }
            yyerrok;
        }
    ;

run_statement
    : RUN STRING_LIT
        { set_script($2); free($2); }
    | RUN error
        {
            fprintf(stderr,
                "[Syntax Error] Line %d: RUN requires a quoted string, "
                "e.g.  RUN \"script.py\"\n", yyline);
            parse_errors++;
            if (yychar != RBRACE && yychar != YYEOF) {
                skip_to_line_end();
                yyclearin;
            }
            yyerrok;
        }
    ;

schedule_statement
    : schedule_expr
        { set_schedule($1); free($1); }
    ;

schedule_expr
    : EVERY DAY AT TIME_VAL
        {
            char buf[MAX_SCHED];
            snprintf(buf, sizeof buf, "EVERY DAY AT %s", $4);
            free($4);
            $$ = strdup(buf);
        }

    | EVERY DAY %prec DAY_ONLY
        {
            $$ = strdup("EVERY DAY");
        }

    | EVERY WEEK ON day_of_week AT TIME_VAL
        {
            char buf[MAX_SCHED];
            snprintf(buf, sizeof buf, "EVERY WEEK ON %s AT %s", $4, $6);
            free($4); free($6);
            $$ = strdup(buf);
        }

    | AT TIME_VAL
        {
            char buf[MAX_SCHED];
            snprintf(buf, sizeof buf, "AT %s", $2);
            free($2);
            $$ = strdup(buf);
        }

    | WHEN IDENTIFIER
        {
            char buf[MAX_SCHED];
            snprintf(buf, sizeof buf, "WHEN %s", $2);
            free($2);
            $$ = strdup(buf);
        }

    | WHEN error
        {
            fprintf(stderr,
                "[Syntax Error] Line %d: WHEN requires an event name, "
                "e.g. WHEN push.\n", yyline);
            parse_errors++;
            if (yychar != RBRACE && yychar != YYEOF) {
                skip_to_line_end();
                yyclearin;
            }
            yyerrok;
            $$ = strdup("(invalid schedule)");
        }

    | EVERY error
        {
            fprintf(stderr,
                "[Syntax Error] Line %d: Invalid EVERY schedule. "
                "Use: EVERY DAY, EVERY DAY AT HH:MM, "
                "or EVERY WEEK ON <day> AT HH:MM\n",
                yyline);
            parse_errors++;
            if (yychar != RBRACE && yychar != YYEOF) {
                skip_to_line_end();
                yyclearin;
            }
            yyerrok;
            $$ = strdup("(invalid schedule)");
        }

    | EVERY DAY AT INVALID_TIME
        {
            fprintf(stderr,
                "[Syntax Error] Line %d: Invalid time in daily schedule. "
                "Use HH:MM from 00:00 to 23:59.\n", yyline);
            parse_errors++;
            $$ = strdup("(invalid schedule)");
        }

    | EVERY WEEK ON day_of_week AT INVALID_TIME
        {
            fprintf(stderr,
                "[Syntax Error] Line %d: Invalid time in weekly schedule. "
                "Use HH:MM from 00:00 to 23:59.\n", yyline);
            free($4);
            parse_errors++;
            $$ = strdup("(invalid schedule)");
        }

    | AT INVALID_TIME
        {
            fprintf(stderr,
                "[Syntax Error] Line %d: Invalid time. "
                "Use HH:MM from 00:00 to 23:59.\n", yyline);
            parse_errors++;
            $$ = strdup("(invalid schedule)");
        }
    ;

day_of_week
    : MONDAY    { $$ = strdup("MONDAY");    }
    | TUESDAY   { $$ = strdup("TUESDAY");   }
    | WEDNESDAY { $$ = strdup("WEDNESDAY"); }
    | THURSDAY  { $$ = strdup("THURSDAY");  }
    | FRIDAY    { $$ = strdup("FRIDAY");    }
    | SATURDAY  { $$ = strdup("SATURDAY");  }
    | SUNDAY    { $$ = strdup("SUNDAY");    }
    ;

dependency_statement
    : AFTER IDENTIFIER
        { add_dependency($2); free($2); }

    | BEFORE IDENTIFIER
        { add_before_task($2); free($2); }

    | DEPENDS IDENTIFIER
        { add_dependency($2); free($2); }

    | DEPENDS ON IDENTIFIER
        { add_dependency($3); free($3); }

    | AFTER error
        {
            fprintf(stderr,
                "[Syntax Error] Line %d: AFTER requires a task name "
                "identifier.\n", yyline);
            parse_errors++;
            if (yychar != RBRACE && yychar != YYEOF) {
                skip_to_line_end();
                yyclearin;
            }
            yyerrok;
        }

    | BEFORE error
        {
            fprintf(stderr,
                "[Syntax Error] Line %d: BEFORE requires a task name "
                "identifier.\n", yyline);
            parse_errors++;
            if (yychar != RBRACE && yychar != YYEOF) {
                skip_to_line_end();
                yyclearin;
            }
            yyerrok;
        }

    | DEPENDS error
        {
            fprintf(stderr,
                "[Syntax Error] Line %d: DEPENDS requires a task name "
                "identifier, optionally written as DEPENDS ON <task>.\n",
                yyline);
            parse_errors++;
            if (yychar != RBRACE && yychar != YYEOF) {
                skip_to_line_end();
                yyclearin;
            }
            yyerrok;
        }
    ;

condition_statement
    : IF condition_clause
        { set_condition($2); free($2); }

    | IF error
        {
            fprintf(stderr,
                "[Syntax Error] Line %d: IF requires a condition keyword "
                "(success or failure).\n", yyline);
            parse_errors++;
            if (yychar != RBRACE && yychar != YYEOF) {
                skip_to_line_end();
                yyclearin;
            }
            yyerrok;
        }
    ;

condition_clause
    : SUCCESS { $$ = strdup("success"); }
    | FAILURE { $$ = strdup("failure"); }
    ;

%%

static void begin_task(const char *name)
{
    strncpy(cur_name, name, MAX_NAME - 1);
    cur_name[MAX_NAME - 1] = '\0';
    cur_script[0]   = '\0';
    cur_run_seen    = 0;
    cur_schedule[0] = '\0';
    cur_dep_count   = 0;
    cur_before_count = 0;
    cur_condition[0] = '\0';
}

static void end_task(void)
{
    if (find_task(cur_name) >= 0) {
        fprintf(stderr,
            "[Semantic Error] Duplicate task name: '%s'. "
            "Task names must be unique.\n", cur_name);
        parse_errors++;
        return;
    }

    if (!cur_run_seen) {
        fprintf(stderr,
            "[Semantic Error] Task '%s' is missing a RUN statement.\n",
            cur_name);
        parse_errors++;
    }

    if (task_count >= MAX_TASKS) {
        fprintf(stderr, "[Internal Error] Too many tasks (max %d).\n",
                MAX_TASKS);
        exit(1);
    }

    Task *t = &tasks[task_count++];
    strncpy(t->name,      cur_name,      MAX_NAME   - 1);
    strncpy(t->script,    cur_script,    MAX_SCRIPT - 1);
    strncpy(t->schedule,  cur_schedule,  MAX_SCHED  - 1);
    strncpy(t->condition, cur_condition, MAX_COND   - 1);
    t->dep_count = cur_dep_count;
    t->before_count = cur_before_count;
    t->visited   = 0;
    t->in_stack  = 0;

    t->name[MAX_NAME - 1] = '\0';
    t->script[MAX_SCRIPT - 1] = '\0';
    t->schedule[MAX_SCHED - 1] = '\0';
    t->condition[MAX_COND - 1] = '\0';

    for (int i = 0; i < cur_dep_count; i++) {
        strncpy(t->depends_on[i], cur_deps[i], MAX_NAME - 1);
        t->depends_on[i][MAX_NAME - 1] = '\0';
    }

    for (int i = 0; i < cur_before_count; i++) {
        strncpy(t->before_tasks[i], cur_before[i], MAX_NAME - 1);
        t->before_tasks[i][MAX_NAME - 1] = '\0';
    }
}

static void set_script(const char *s)
{
    if (cur_run_seen) {
        fprintf(stderr,
            "[Semantic Error] Task '%s' has more than one RUN statement.\n",
            cur_name);
        parse_errors++;
        return;
    }

    cur_run_seen = 1;
    if (s[0] == '\0') {
        fprintf(stderr,
            "[Semantic Error] Task '%s' has an empty RUN command.\n",
            cur_name);
        parse_errors++;
        return;
    }

    strncpy(cur_script, s, MAX_SCRIPT - 1);
    cur_script[MAX_SCRIPT - 1] = '\0';
}

static void set_schedule(const char *s)
{
    if (cur_schedule[0] != '\0') {
        fprintf(stderr,
            "[Semantic Error] Task '%s' has more than one schedule statement.\n",
            cur_name);
        parse_errors++;
        return;
    }
    strncpy(cur_schedule, s, MAX_SCHED - 1);
    cur_schedule[MAX_SCHED - 1] = '\0';
}

static void add_dependency(const char *dep)
{
    if (current_dependency_exists(dep)) {
        fprintf(stderr,
            "[Semantic Error] Task '%s' repeats dependency '%s'.\n",
            cur_name, dep);
        parse_errors++;
        return;
    }

    if (cur_dep_count >= MAX_DEPS) {
        fprintf(stderr, "[Semantic Error] Too many dependencies in task.\n");
        parse_errors++;
        return;
    }
    strncpy(cur_deps[cur_dep_count], dep, MAX_NAME - 1);
    cur_deps[cur_dep_count][MAX_NAME - 1] = '\0';
    cur_dep_count++;
}

static void add_before_task(const char *task_name)
{
    if (current_before_exists(task_name)) {
        fprintf(stderr,
            "[Semantic Error] Task '%s' repeats BEFORE relationship '%s'.\n",
            cur_name, task_name);
        parse_errors++;
        return;
    }

    if (cur_before_count >= MAX_DEPS) {
        fprintf(stderr, "[Semantic Error] Too many BEFORE relationships in task.\n");
        parse_errors++;
        return;
    }
    strncpy(cur_before[cur_before_count], task_name, MAX_NAME - 1);
    cur_before[cur_before_count][MAX_NAME - 1] = '\0';
    cur_before_count++;
}

static void set_condition(const char *cond)
{
    if (cur_condition[0] != '\0') {
        fprintf(stderr,
            "[Semantic Error] Task '%s' has more than one IF condition.\n",
            cur_name);
        parse_errors++;
        return;
    }
    strncpy(cur_condition, cond, MAX_COND - 1);
    cur_condition[MAX_COND - 1] = '\0';
}

static int find_task(const char *name)
{
    for (int i = 0; i < task_count; i++)
        if (strcmp(tasks[i].name, name) == 0)
            return i;
    return -1;
}

static int current_dependency_exists(const char *dep)
{
    for (int i = 0; i < cur_dep_count; i++)
        if (strcmp(cur_deps[i], dep) == 0)
            return 1;
    return 0;
}

static int current_before_exists(const char *task_name)
{
    for (int i = 0; i < cur_before_count; i++)
        if (strcmp(cur_before[i], task_name) == 0)
            return 1;
    return 0;
}

static int add_dependency_to_task(Task *task, const char *dep)
{
    for (int i = 0; i < task->dep_count; i++) {
        if (strcmp(task->depends_on[i], dep) == 0) {
            fprintf(stderr,
                "[Semantic Error] Task '%s' repeats dependency '%s'. "
                "This can happen when BEFORE and AFTER describe the same relationship twice.\n",
                task->name, dep);
            parse_errors++;
            return 0;
        }
    }

    if (task->dep_count >= MAX_DEPS) {
        fprintf(stderr,
            "[Semantic Error] Task '%s' has too many dependencies (max %d).\n",
            task->name, MAX_DEPS);
        parse_errors++;
        return 0;
    }

    strncpy(task->depends_on[task->dep_count], dep, MAX_NAME - 1);
    task->depends_on[task->dep_count][MAX_NAME - 1] = '\0';
    task->dep_count++;
    return 1;
}

static void apply_before_dependencies(void)
{
    for (int i = 0; i < task_count; i++) {
        for (int b = 0; b < tasks[i].before_count; b++) {
            int target_idx = find_task(tasks[i].before_tasks[b]);
            if (target_idx < 0) {
                fprintf(stderr,
                    "[Semantic Error] Task '%s' declares BEFORE undefined task '%s'.\n",
                    tasks[i].name, tasks[i].before_tasks[b]);
                parse_errors++;
                continue;
            }

            add_dependency_to_task(&tasks[target_idx], tasks[i].name);
        }
    }
}

static void validate_condition_dependencies(void)
{
    for (int i = 0; i < task_count; i++) {
        if (tasks[i].condition[0] != '\0' && tasks[i].dep_count == 0) {
            fprintf(stderr,
                "[Semantic Error] Task '%s' has IF %s but no dependency. "
                "Conditions require AFTER, DEPENDS, DEPENDS ON, or another task declaring BEFORE this task.\n",
                tasks[i].name, tasks[i].condition);
            parse_errors++;
        }
    }
}

static int cycle_found = 0;
static int cycle_stack[MAX_TASKS];
static int cycle_depth = 0;

static void print_cycle_path(int repeated_idx)
{
    int start = 0;

    while (start < cycle_depth && cycle_stack[start] != repeated_idx)
        start++;

    fprintf(stderr,
        "[Semantic Error] Circular dependency detected. "
        "The workflow cannot execute because these tasks depend on each other: ");

    for (int i = start; i < cycle_depth; i++)
        fprintf(stderr, "%s -> ", tasks[cycle_stack[i]].name);

    fprintf(stderr, "%s\n", tasks[repeated_idx].name);
}

static int dfs_cycle(int idx)
{
    Task *t = &tasks[idx];
    t->visited  = 1;
    t->in_stack = 1;
    cycle_stack[cycle_depth++] = idx;

    for (int d = 0; d < t->dep_count; d++) {
        int dep_idx = find_task(t->depends_on[d]);
        if (dep_idx < 0) continue;

        if (!tasks[dep_idx].visited) {
            if (dfs_cycle(dep_idx)) {
                cycle_depth--;
                t->in_stack = 0;
                return 1;
            }
        } else if (tasks[dep_idx].in_stack) {
            print_cycle_path(dep_idx);
            cycle_found = 1;
            cycle_depth--;
            t->in_stack = 0;
            return 1;
        }
    }

    cycle_depth--;
    t->in_stack = 0;
    return 0;
}

static void topo_sort(int *order, int *order_len)
{
    int in_degree[MAX_TASKS] = {0};
    int queue[MAX_TASKS];
    int q_front = 0, q_back = 0;
    *order_len = 0;

    for (int i = 0; i < task_count; i++) {
        for (int d = 0; d < tasks[i].dep_count; d++) {
            int dep_idx = find_task(tasks[i].depends_on[d]);
            if (dep_idx >= 0)
                in_degree[i]++;
        }
    }

    for (int i = 0; i < task_count; i++)
        if (in_degree[i] == 0)
            queue[q_back++] = i;

    while (q_front < q_back) {
        int cur = queue[q_front++];
        order[(*order_len)++] = cur;

        for (int i = 0; i < task_count; i++) {
            for (int d = 0; d < tasks[i].dep_count; d++) {
                if (find_task(tasks[i].depends_on[d]) == cur) {
                    in_degree[i]--;
                    if (in_degree[i] == 0)
                        queue[q_back++] = i;
                }
            }
        }
    }
}

static void validate_semantics(void)
{
    apply_before_dependencies();
    validate_condition_dependencies();

    for (int i = 0; i < task_count; i++) {
        for (int d = 0; d < tasks[i].dep_count; d++) {
            if (find_task(tasks[i].depends_on[d]) < 0) {
                fprintf(stderr,
                    "[Semantic Error] Task '%s' depends on undefined task '%s'.\n",
                    tasks[i].name, tasks[i].depends_on[d]);
                parse_errors++;
            }
        }
    }

    for (int i = 0; i < task_count; i++)
        tasks[i].visited = tasks[i].in_stack = 0;

    for (int i = 0; i < task_count; i++) {
        if (!tasks[i].visited) {
            cycle_depth = 0;
            dfs_cycle(i);
        }
    }

    if (cycle_found)
        parse_errors++;
}

static void print_task(const Task *t)
{
    printf("Executing Task: %s\n", t->name);
    printf("  Script: \"%s\"\n", t->script);

    if (t->schedule[0])
        printf("  Schedule: %s\n", t->schedule);
    else
        printf("  Schedule: (none)\n");

    printf("  Depends on:");
    if (t->dep_count > 0) {
        for (int d = 0; d < t->dep_count; d++)
            printf(" %s", t->depends_on[d]);
        printf("\n");
    } else {
        printf(" (none)\n");
    }

    if (t->condition[0])
        printf("  Condition: %s\n", t->condition);
    else
        printf("  Condition: (none)\n");

    printf("\n");
}

static void run_simulation(void)
{
    printf("Parsing TaskLang++ input...\n\n");
    printf("--- EXECUTION START ---\n\n");

    int order[MAX_TASKS];
    int order_len = 0;
    topo_sort(order, &order_len);

    if (order_len < task_count) {
        fprintf(stderr,
            "[Warning] Execution order is unreliable due to cycles. "
            "Falling back to declaration order.\n\n");
        for (int i = 0; i < task_count; i++)
            print_task(&tasks[i]);
    } else {
        for (int i = 0; i < order_len; i++)
            print_task(&tasks[order[i]]);
    }

    printf("--- EXECUTION COMPLETE ---\n");
}

void yyerror(const char *msg)
{
    fprintf(stderr, "[Syntax Error] Line %d: %s\n", yyline, msg);
    parse_errors++;
}

int main(void)
{
    int parse_result = yyparse();

    validate_semantics();

    int total_errors = parse_errors + lex_error_count;

    if (total_errors > 0) {
        fprintf(stderr,
            "\n[Result] Parsing FAILED with %d error(s).\n", total_errors);
        return 1;
    }

    if (parse_result != 0) {
        fprintf(stderr, "\n[Result] Parsing FAILED.\n");
        return 1;
    }

    run_simulation();
    return 0;
}
