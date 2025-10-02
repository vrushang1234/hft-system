#include "radix_tree.h"
#include "utils.h"

radix_node *create_radix_tree(const char *init_val)
{
    radix_node *root = malloc(sizeof(radix_node));

    root->children = malloc(RADIX_CHILD_SIZE * sizeof(radix_node *));
    memset(root->children, 0, RADIX_CHILD_SIZE * sizeof(radix_node *));

    root->val = strdup(init_val);
    root->eow = true;

    return root;
}

/*
This function adds a node to an existing radix tree

Input: root, the root of the radix tree to add to
       value, the value of the new node that will be added

Output: nothing to return, the new node is added in place
*/
void radix_add(radix_node *root, const char *value)
{
    radix_node *curr_node = root;
    radix_node *curr_child;

    bool found_path = true; // whether a node with a matching prefix was found in the curr_node's children

    unsigned short matched = 0;
    unsigned short new_val_len = strlen(value);

    while (found_path)
    {
        found_path = false;
        for (unsigned short i = 0; curr_node->children[i]; i++)
        {
            curr_child = curr_node->children[i];
            unsigned short prefix = str_prefix(&value[matched], curr_child->val);

            if (prefix > 0)
            {
                matched += prefix;
                if (matched < strlen(value) && prefix == strlen(curr_child->val)) // not done matching prefixes
                {
                    curr_node = curr_child;
                    found_path = true;
                    break;
                }
                else if (prefix < strlen(curr_child->val)) // reached end of matching existing nodes
                {
                    char *curr_child_suffix = strdup(&curr_child->val[prefix]);

                    radix_node *temp = create_radix_tree(curr_child_suffix);

                    if (matched != strlen(value)) // new value is a partial match with an existing value (i.e "Biggest", "Bigger")
                    {
                        char *value_suffix = strdup(&value[matched]);
                        radix_node *add_child = create_radix_tree(value_suffix);

                        unsigned short j = 0;
                        for (; curr_child->children[j]; j++)
                            temp->children[j] = curr_child->children[j];

                        curr_child->children[j++] = add_child;
                        curr_child->children[j] = temp;
                    }
                    else // new value is a substr of an existing value (i.e "Big", "Bigger")
                    {
                        for (unsigned short j = 0; curr_child->children[j]; j++)
                            temp->children[j] = curr_child->children[j];

                        curr_child->children[0] = temp;
                    }
                    curr_child->val[prefix] = 0;
                }
                else
                { // new value is the same as an existing value
                    curr_node->eow = true;
                }
                return;
            }
        }
    }
    unsigned short append_idx = 0;
    while (curr_node->children[append_idx])
        append_idx++;
    curr_node->children[append_idx] = create_radix_tree(&value[matched]);
}

/*
This function removes a node from an existing radix tree

Input: root, the root of the radix tree to remove from
       value, the value of the node that will be removed

Output: nothing to return
*/
void radix_del(radix_node *root, const char *value)
{
    radix_node *curr_node = root;
    radix_node *curr_child;

    unsigned short matched = 0;
    bool found_path = true; // whether a node with a matching prefix was found in the curr_node's children

    while (found_path)
    {
        found_path = false;
        for (unsigned short i = 0; curr_node->children[i]; i++)
        {
            curr_child = curr_node->children[i];
            unsigned short prefix = str_prefix(&value[matched], curr_child->val);

            if (prefix > 0)
            {
                matched += prefix;
                if (matched < strlen(value) && prefix == strlen(curr_child->val)) // not done matching prefixes
                {
                    curr_node = curr_child;
                    found_path = true;
                    break;
                }
                else if (prefix == strlen(curr_child->val)) // new value is the same as an existing value
                {
                    if (curr_child->children[0])
                    {
                        curr_child->eow = false;
                    }
                    else
                    {
                        free(curr_child->val);
                        free(curr_child);
                        curr_node->children[i++] = NULL;
                        for (; curr_node->children[i]; i++)
                            curr_node->children[i - 1] = curr_node->children[i];
                    }
                    // otherwise no match was found, do nothing or return false
                    return;
                }
            }
        }
    }
}

bool radix_search(radix_node *root, const char *value)
{
    radix_node *curr_node = root;
    radix_node *curr_child;

    unsigned short matched = 0;
    bool found_path = true; // whether a node with a matching prefix was found in the curr_node's children

    while (found_path)
    {
        found_path = false;
        for (unsigned short i = 0; curr_node->children[i]; i++)
        {
            curr_child = curr_node->children[i];
            unsigned short prefix = str_prefix(&value[matched], curr_child->val);

            if (prefix > 0)
            {
                matched += prefix;
                if (matched < strlen(value) && prefix == strlen(curr_child->val)) // not done matching prefixes
                {
                    curr_node = curr_child;
                    found_path = true;
                    break;
                }
                else if (prefix == strlen(curr_child->val) && curr_child->eow) // new value is the same as an existing value
                {
                    return true;
                }
                return false; // otherwise no match was found, do nothing or return false
            }
        }
    }
    return false;
}

void radix_print_tree(radix_node *root)
{
    radix_node **stack = malloc(RADIX_CHILD_SIZE * sizeof(radix_node *));
    radix_node *curr_node = root;
    char *eow_prefix = malloc(128 * sizeof(char));

    unsigned short depth = 0, i = 0, j;
    while (curr_node)
    {
        for (j = 0; curr_node->children[j]; j++)
            stack[++i] = curr_node->children[j];

        if (!curr_node->eow)
        {
            prepend(eow_prefix, curr_node->val);
        }
        else
        {
            printf("%s%s ", eow_prefix, curr_node->val);
        }
        if (!j)
        {
            eow_prefix[0] = '\0';
            printf("\n%*s", 2 * depth--, "");
        }
        else
            depth++;

        curr_node = stack[i];
        stack[i--] == NULL;
    }

    free(stack);
}
