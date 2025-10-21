#include <stdio.h>
#include <assert.h>

#define HEADERS
#include "radix_tree_tests.c"
#undef HEADERS

#define TEST(name) test = name;
#define ASSERT(ast)       \
    do                    \
    {                     \
        assertion = #ast; \
        file = __FILE__;  \
        line = __LINE__;  \
        if (ast)          \
            putchar('.'); \
        else              \
            goto fail;    \
    } while (0)

int run_radix_tests()
{
    const char *test = "";
    const char *assertion = "";
    const char *file = "";
    int line = 0;

#define TEST_RADIX_TREE
#include "radix_tree_tests.c"
#undef TEST_RADIX_TREE

    putchar('\n');
    return 0;

fail:
    printf("!\nTest failed at %s:%d\n    %s: %s\n",
           file, line,
           test, assertion);
    return -1;
}

#define HEADERS
#include "rb_tree_test.c"
#undef HEADERS

const char *current_test = "";
const char *current_assertion = "";
const char *current_file = "";
int current_line = 0;

#define TEST(name) \
    current_test = name; { \
        int test_failed = 0;

#define ASSERT(expr) \
    do { \
        current_assertion = #expr; \
        current_file = __FILE__; \
        current_line = __LINE__; \
        if (!(expr)) { \
            printf("[FAIL] %s at %s:%d\n    %s\n", \
                   current_test, current_file, current_line, \
                   current_assertion); \
            test_failed = 1; \
            return -1; \
        } \
    } while (0)

#define ENDTEST() \
        if (!test_failed) printf("[PASS] %s\n", current_test); \
    }
    
int run_rb_tests(void) {
    printf("Running RB Tree tests...\n\n");

#define TEST_RB_TREE
#include "rb_tree_test.c"
#undef TEST_RB_TREE

    printf("\nAll Red Black Tree tests passed!\n");
    return 0;
}

int main(void) {
    int result = 0;
    result |= run_radix_tests();
    result |= run_rb_tests();

    if (result == 0)
        printf("\nAll tests passed!\n");
    else
        printf("\nSome tests failed.\n");

    return result;
}