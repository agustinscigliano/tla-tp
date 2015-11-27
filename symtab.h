typedef struct Symtab Symtab;

Symtab *newsymboltable(void);
void   freesymboltable(Symtab *table);
int    *lookup(Symtab *table, int insert, char *key, int *value);

typedef void (*symtabfnT)(char *key, void *value, void * clientData);
void mapsymtab(symtabfnT fn, Symtab *table, void *clientData);
