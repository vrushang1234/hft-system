#include "utils.h"

unsigned short str_prefix(char *s1, char *s2)
{
    short cnt = 0;
    while (*s1 && *s2 && (*s1++ == *s2++))
        cnt++;
    return cnt;
}

void prepend(char *s, const char *t)
{
    size_t len = strlen(t);
    memmove(s + len, s, strlen(s) + 1);
    memcpy(s, t, len);
}