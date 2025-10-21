#ifdef HEADERS
#include "../include/rb_tree.h"
#elif defined TEST_RB_TREE

rb_node *root = NULL;

TEST("create tree")
{
    rb_node *root = create_rb_tree("hello");
    ASSERT(root != NULL);
    ASSERT(strcmp(root->val, "hello") == 0);
    ASSERT(root->color == BLACK);
    ASSERT(root->left == NULL && root->right == NULL);
    ENDTEST();
}


TEST("basic insert")
{
    rb_node *root = create_rb_tree("test1");
    rb_tree_add_node(&root, "test2");
    rb_tree_add_node(&root, "test3");

    ASSERT(rb_search(root, "test1") != NULL);
    ASSERT(rb_search(root, "test2") != NULL);
    ASSERT(rb_search(root, "test3") != NULL);
    ENDTEST();
}

TEST("search")
{
    rb_node *root = create_rb_tree("start");
    rb_tree_add_node(&root, "end");
    rb_tree_add_node(&root, "middle");

    rb_node *found = rb_search(root, "end");
    rb_node *not_found = rb_search(root, "missing");

    ASSERT(found != NULL && strcmp(found->val, "end") == 0);
    ASSERT(not_found == NULL);
    ENDTEST();
}

TEST("duplicate insert")
{
    rb_node *root = create_rb_tree("root");
    rb_tree_add_node(&root, "leaf1");
    rb_tree_add_node(&root, "leaf1");

    ASSERT(root->left != NULL && strcmp(root->left->val, "leaf1") == 0);
    ASSERT(root->left->left == NULL && root->left->right == NULL);
    ENDTEST();
}

TEST("delete leaf")
{
    rb_node *root = create_rb_tree("root");
    rb_tree_add_node(&root, "leaf1");
    rb_tree_add_node(&root, "leaf2");

    rb_delete(&root, "leaf1");

    ASSERT(rb_search(root, "leaf1") == NULL);
    ASSERT(rb_search(root, "root") != NULL);  
    ASSERT(rb_search(root, "leaf2") != NULL);  
    ENDTEST();
}
#endif