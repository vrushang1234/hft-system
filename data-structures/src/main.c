#include "radix_tree.h"
#include "rb_tree.h"

int main()
{
    radix_node *a = create_radix_tree("");
    radix_add(a, "Hello");
    radix_add(a, "Hel");
    // radix_del(a, "Hello");

    radix_add(a, "Hello");
    radix_add(a, "Hello");
    radix_add(a, "Hellolo");

    radix_add(a, "Booking");
    // radix_print_tree(a);
    radix_add(a, "Bo");

    radix_add(a, "Booker");

    // radix_print_tree(a);
    radix_add(a, "Book");

    radix_print_tree(a);
    // radix_print_tree(a->children[0]);
    // radix_print_tree(a->children[0]->children[0]);
    // printf("%i", radix_search(a, "Hellolo"));
}