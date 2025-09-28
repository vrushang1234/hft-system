typedef struct rb_node
{
    struct rb_node *left;
    struct rb_node *right;
    char *val;
} rb_node;

rb_node *create_rb_tree();

void radix_tree_add_node();

void rb_search(rb_node *root, char *value);