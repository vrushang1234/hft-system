#include "radix_tree.h"
#include "rb_tree.h"

int main()
{
    radix_node *a = create_radix_tree("");
    radix_add(a, "Hello");
    radix_add(a, "Hel");
    radix_del(a, "Hello");

    // radix_add(a, "Hello");
    // radix_add(a, "Hellolo");

    radix_print_children(a);
    // radix_print_children(a->children[0]);
    // radix_print_children(a->children[0]->children[0]);
    // printf("%i", radix_search(a, "Hellolo"));
}