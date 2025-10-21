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
    ASSERT(1);
}

TEST("radix del leaf")
{
    radix_del(root, "House");
    ASSERT(root->children[0]->children[1] == NULL);
}

TEST("radix del prefix")
{
    radix_del(root, "Hel");
    ASSERT(root->children[0]->eow == false && root->children[0]->children[0]->eow == false && !strcmp(root->children[0]->children[0]->children[0]->val, "lo"));
}

TEST("radix del invalid value")
{
    radix_del(root, "abc");
    ASSERT(root->children[0]->eow == false && root->children[0]->children[0]->eow == false && !strcmp(root->children[0]->children[0]->children[0]->val, "lo"));
}

TEST("radix search existing value")
{
    ASSERT(radix_search(root, "Hello"));
}

TEST("radix search non end of word")
{
    ASSERT(!radix_search(root, "Hel"));
}

TEST("radix search partial prefix")
{
    ASSERT(!radix_search(root, "Hellos"));
}

TEST("radix search invalid value")
{

    ASSERT(!radix_search(root, "Donkey"));
}

TEST("radix del root")
{
    radix_del_tree(root);
    ASSERT(1);
}
#endif