#pragma once

#include "utils.h"
#include <stdbool.h>
#include <stdlib.h>
#include <string.h>
#include <stdio.h>

typedef struct radix_node
{
    struct radix_node **children;
    char *val;
    bool eow; // end of word
} radix_node;

radix_node *create_radix_tree(const char *init_val);

void radix_add(radix_node *root, const char *value);

void radix_del(radix_node *root, const char *value);

bool radix_search(radix_node *root, const char *value);

bool radix_rec_search(radix_node *node, const char *value);

void radix_print_tree(radix_node *root);