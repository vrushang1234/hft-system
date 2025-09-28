unsigned short str_prefix(char *s1, char *s2)
{
    short cnt = 0;
    while (*s1 && *s2 && (*s1++ == *s2++))
        cnt++;
    return cnt;
}