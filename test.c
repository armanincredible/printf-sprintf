extern "C" int _printf (const char* str, ...);

int main ()
{
    const char* str_from = "N.ARMAN";
    const char* str = "dora";
    _printf ("im %s and i listen %% %c %s %%. %d in d its %o in o %b in b %x in x\n I %s %x %d%%%c%b\n$", str_from, '+', str, 42, 42, 42, 42, "love", 3802, 100, 33, 15);
    //_printf ("im %b", 42);
    return 0;
}
