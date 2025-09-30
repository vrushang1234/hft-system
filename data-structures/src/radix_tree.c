#include "radix_tree.h"

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

    bool found_path = true;

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
                    curr_child->val[prefix] = 0; // any bugs most likely from here
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
    unsigned short value_idx = 0;
    while (1)
    {
        for (unsigned short i = 0; curr_node->children[i]; i++)
        {
            unsigned short prefix = str_prefix(&value[value_idx], curr_node->children[i]->val);
            if (prefix > 0)
            {
                if (prefix + value_idx == strlen(value))
                {
                    if (curr_node->children[i]->val[prefix] == '\0')
                    {
                        radix_node *rm_node = curr_node->children[i];
                        unsigned short j = i + 1;
                        while (curr_node->children[j])
                            j++;
                        memmove(&curr_node->children[i], &curr_node->children[i + 1], (j - i - 1) * sizeof(radix_node *));
                        curr_node->children[j - 1] = NULL;
                        // for (int k = 0; rm_node->children[k]; k++)

                        free(rm_node);
                    }
                    return;
                }
                value_idx += prefix;
                curr_node = curr_node->children[i];
                break;
            }
        }
    }
}

bool radix_search(radix_node *root, const char *value)
{
    for (unsigned short i = 0; root->children[i]; i++)
        if (radix_rec_search(root->children[i], value))
            return true;
    return false;
}

bool radix_rec_search(radix_node *node, const char *value)
{
    if (node->val == NULL)
        return false;
    unsigned short pre_len = str_prefix(node->val, value);
    if (!pre_len)
        return false;
    else if (pre_len == strlen(value))
        return true;

    char *new_val = &value[pre_len];
    for (unsigned short i = 0; node->children[i]; i++)
        if (radix_rec_search(node->children[i], new_val))
            return true;
    return false;
}

void radix_print_tree(radix_node *root)
{
    radix_node **stack = malloc(RADIX_CHILD_SIZE * sizeof(radix_node *));
    radix_node *curr_node = root;

    unsigned short depth = 0, i = 0, j;
    while (curr_node)
    {
        for (j = 0; curr_node->children[j]; j++)
            stack[++i] = curr_node->children[j];

        printf("%s ", curr_node->val);
        if (!j)
            printf("\n%*s", 2 * depth--, "");
        else
            depth++;
        curr_node = stack[i];

        stack[i--] == NULL;
    }

    free(stack);
}