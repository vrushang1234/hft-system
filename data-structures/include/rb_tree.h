#include <stdlib.h>
#include <string.h>
#include <stddef.h>
#include <stdio.h>

typedef struct rb_node
{
    struct rb_node left, right, parent;
    char val;
    int color;
} rb_node;

rb_node *create_rb_tree(const char *init_val);

void rb_tree_add_node(rb_node **root_ref, const char *value);

rb_node *rb_search(rb_node *root, const char *value);

void rb_delete(rb_node **root_ref, const char *value);

void rb_left_rotate(rb_node **root, rb_node *x);

void rb_right_rotate(rb_node **root, rb_node *y);

rb_node *rb_minimum(rb_node *x);