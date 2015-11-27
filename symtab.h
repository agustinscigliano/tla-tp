typedef struct Symtab Symtab;

Symtab *newsymboltable(void);
void   freesymboltable(Symtab *table);
void   *lookup(Symtab *table, int insert, char *key, void *value);

