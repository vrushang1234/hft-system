#include "rb_tree.h"

/*
Function creates a new Red-Black Tree node

Input: init_val, the string value to store in the new node

Output: pointer to the newly created node, colored BLACK, with no children or parent
*/

rb_node *create_rb_tree(const char *init_val) {
    rb_node *node = malloc(sizeof(rb_node));
    node->val = strdup(init_val);
    node->color = BLACK;
    node->right = node->left = node->parent = NULL;
    return node;
}
/*
This function inserts a new node with the given value into a Red-Black Tree

Input: root_ref, pointer to the root of the Red-Black Tree
       value, the string value to insert

Output: nothing to return, the new node is inserted and tree rebalanced in place
*/
void rb_tree_add_node(rb_node **root_ref, const char *value) {
    rb_node *parent = NULL, *temp = *root_ref;
    rb_node *newNode = malloc(sizeof(rb_node));
    newNode->val = strdup(value);
    newNode->left = newNode->right = newNode->parent = NULL;
    newNode->color = RED;

    while (temp) {
        parent = temp;
        int cmp = strcmp(value, temp->val);
        if (cmp == 0) { free(newNode->val); free(newNode); return; }
        else if (cmp < 0) temp = temp->left;
        else temp = temp->right;
    }

    newNode->parent = parent;
    if (!parent) 
        *root_ref = newNode;
    else if (strcmp(value, parent->val) < 0) 
        parent->left = newNode;
    else 
        parent->right = newNode;

    rb_node *node = newNode;
    while (node->parent && node->parent->color == RED) {
        rb_node *grandparent = node->parent->parent;
        int dir = (node->parent == grandparent->left);
        
        rb_node *uncle = dir ? grandparent->right : grandparent->left;
        if (uncle && uncle->color == RED) {
            node->parent->color = BLACK;
            uncle->color = BLACK;
            grandparent->color = RED;
            node = grandparent;
        } else {
            if (node == (dir ? node->parent->right : node->parent->left)) {
                node = node->parent;
                if (dir) rb_left_rotate(root_ref, node);
                else
                    rb_right_rotate(root_ref, node);
            }
            node->parent->color = BLACK;
            grandparent->color = RED;
            if (dir) rb_right_rotate(root_ref, grandparent);
            else rb_left_rotate(root_ref, grandparent);
        }
    }
(*root_ref)->color = BLACK;
}

/*
This function searches for a node with a given value in a Red-Black Tree

Input: root, the root of the Red-Black Tree
       value, the string value to search for

Output: pointer to the node containing the value, or NULL if not found
*/

rb_node *rb_search(rb_node *root, const char *value) {
    rb_node *temp = root;
    while (temp) {
        int cmp = strcmp(value, temp->val);
        if (cmp == 0) return temp;
        else if (cmp < 0) temp = temp->left;
        else temp = temp->right;
    }
    return NULL;
}

/*
This function deletes a node with a specific value from a Red-Black Tree

Input: root_ref, pointer to the root of the Red-Black Tree
       value, the string value of the node to delete

Output: nothing to return, the node is removed and the tree rebalanced in place
*/

void rb_delete(rb_node **root_ref, const char *value) {
    rb_node *node = *root_ref;
    while (node && strcmp(node->val, value))
        node = (strcmp(value, node->val) < 0) ? node->left : node->right;
    if (!node) return;

    
    rb_node *y = node, *x = NULL;
    int y_original_color = y->color;

    if (!node->left) {
        x = node->right;
        if (node->parent) {
            if (node == node->parent->left) node->parent->left = node->right;
            else node->parent->right = node->right;
        } else {
            *root_ref = node->right;
        }
        if (node->right) node->right->parent = node->parent;
    } else if (!node->right) {
        x = node->left;
        if (node->parent) {
            if (node == node->parent->left) node->parent->left = node->left;
            else node->parent->right = node->left;
        } else {
            *root_ref = node->left;
        }
        if (node->left) node->left->parent = node->parent;
    } else {
        y = rb_minimum(node->right);
        y_original_color = y->color;
        x = y->right;

        if (y->parent == node) {
            if (x) x->parent = y;
        } else {
            if (y->parent) {
                if (y == y->parent->left) y->parent->left = y->right;
                else y->parent->right = y->right;
            }
            if (y->right) y->right->parent = y->parent;
            y->right = node->right;
            if (y->right) y->right->parent = y;
        }

        if (node->parent) {
            if (node == node->parent->left) node->parent->left = y;
            else node->parent->right = y;
        } else {
            *root_ref = y;
        }
        y->parent = node->parent;
        y->left = node->left;
        if (y->left) y->left->parent = y;
        y->color = node->color;
    }

    free(node->val);
    free(node);

    while (x != *root_ref && (!x || x->color == BLACK) && y_original_color == BLACK) {
        rb_node *p = x ? x->parent : NULL;
        if (!p) break;
        int left = (x == p->left);
        rb_node *w = left ? p->right : p->left;

        if (w && w->color == RED) {
            w->color = BLACK;
            p->color = RED;
            if (left) rb_left_rotate(root_ref, p); else rb_right_rotate(root_ref, p);
            w = left ? p->right : p->left;
        }
        if ((!w || (!w->left || w->left->color == BLACK)) &&
            (!w || (!w->right || w->right->color == BLACK))) {
            if (w) w->color = RED;
            x = p;
        } else {
            if (left && (!w->right || w->right->color == BLACK)) {
                if (w->left) w->left->color = BLACK;
                if (w) {
                    w->color = RED;
                    rb_right_rotate(root_ref, w);
                }
                w = p->right;
            } else if (!left && (!w->left || w->left->color == BLACK)) {
                if (w->right) w->right->color = BLACK;
                if (w) {
                    w->color = RED;
                    rb_left_rotate(root_ref, w);
                }
                w = p->left;
            }

            if (w) {
                w->color = p->color;
                p->color = BLACK;
                if (left && w->right) w->right->color = BLACK;
                else if (!left && w->left) w->left->color = BLACK;
            }

            if (left) rb_left_rotate(root_ref, p);
            else rb_right_rotate(root_ref, p);
            x = *root_ref;
        }
    }
    if (x) x->color = BLACK;
}
// Performs left rotation on a node in Red-Black Tree
void rb_left_rotate(rb_node **root, rb_node *x) {
    rb_node *y = x->right;
    if (!y) return; 

    x->right = y->left;
    if (y->left) y->left->parent = x;

    y->parent = x->parent;
    if (!x->parent) {
        *root = y;
    } else if (x == x->parent->left) {
        x->parent->left = y;
    } else {
        x->parent->right = y;
    }
    y->left = x;
    x->parent = y;
}

// Performs right rotation on a node in Red-Black Tree
void rb_right_rotate(rb_node **root, rb_node *y) {
    rb_node *x = y->left;
    if (!x) return;

    y->left = x->right;
    if (x->right) x->right->parent = y;

    x->parent = y->parent;
    if (!y->parent) {
        *root = x;
    } else if (y == y->parent->right) {
        y->parent->right = x;
    } else {
        y->parent->left = x;
    }

    x->right = y;
    y->parent = x;
}
// This function finds the pointer to the node with the minimum value in a subtree of a Red-Black Tree
rb_node *rb_minimum(rb_node *x) {
    while (x && x->left) x = x->left;
    return x;
}
