#ifdef HEADERS
#include "../include/radix_tree.h"
#elif defined TEST_RADIX_TREE

radix_node *root = create_radix_tree("");

TEST("radix add empty tree")
{
    radix_add(root, "Hello");
    ASSERT(!strcmp(root->children[0]->val, "Hello"));
}

TEST("radix add duplicate")
{
    radix_add(root, "Hello");
    ASSERT(root->children[1] == NULL);
}

TEST("radix add substring")
{
    radix_add(root, "Hel");
    ASSERT(!strcmp(root->children[0]->val, "Hel") && !strcmp(root->children[0]->children[0]->val, "lo"));
}

TEST("radix add partial prefix")
{
    radix_add(root, "House");
    ASSERT(!strcmp(root->children[0]->val, "H") && !strcmp(root->children[0]->children[1]->val, "el") && !strcmp(root->children[0]->children[0]->val, "ouse"));
}

TEST("radix add invalid value")
{
    radix_add(root, NULL);
    radix_print_tree(root);
    // ASSERT(1);
}

// TEST("radix del leaf")
// {
//     ASSERT(1);
// }

// TEST("radix del prefix")
// {
//     ASSERT(1);
// }

// TEST("radix del root")
// {
//     ASSERT(1);
// }

// TEST("radix del invalid value")
// {
//     ASSERT(1);
// }

// TEST("radix search existing value")
// {
//     ASSERT(1);
// }

// TEST("radix search non end of word")
// {
//     ASSERT(1);
// }

// TEST("radix search partial prefix")
// {
//     ASSERT(1);
// }

// TEST("radix search invalid value")
// {

//     ASSERT(1);
// }
#endif