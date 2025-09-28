#include "radix_tree.h"

radix_node *create_radix_tree(const char *init_val)
{
    radix_node *root = malloc(sizeof(radix_node));

    root->children = malloc(RADIX_CHILD_SIZE * sizeof(radix_node *));
    memset(root->children, 0, RADIX_CHILD_SIZE * sizeof(radix_node *));

    root->val = strdup(init_val);
    root->eow = false;

    return root;
}

void radix_add(radix_node *root, const char *value)
{
    radix_node *curr_node = root;
    unsigned short value_idx = 0;
    while (1)
    {
        bool found_path = false;
        for (unsigned short i = 0; curr_node->children[i]; i++)
        {
            unsigned short prefix = str_prefix(&value[value_idx], curr_node->children[i]->val);
            if (prefix > 0)
            {
                if (prefix + value_idx == strlen(value))
                {
                    if (curr_node->children[i]->val[prefix] != '\0')
                    {
                        radix_node *temp = curr_node->children[i];
                        char *new_val = strdup(&temp->val[prefix]);
                        free(temp->val);
                        temp->val = new_val;
                        curr_node->children[i] = create_radix_tree(value);
                        curr_node->children[i]
                            ->children[0] = temp;
                    }
                    return;
                }
                value_idx += prefix;
                curr_node = curr_node->children[i];
                found_path = true;
                break;
            }
        }
        if (!found_path)
        {
            break;
        }
    }
    unsigned short append_idx = 0;
    while (curr_node->children[append_idx])
        append_idx++;
    curr_node->children[append_idx] = create_radix_tree(&value[value_idx]);
}

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

void radix_print_children(radix_node *root)
{
    radix_node *curr_node = root;
    for (int i = 0; curr_node->children[i] != NULL; i++)
        if (curr_node->eow)
            printf("%s ", curr_node->children[i]->val);
    printf("\n");
}