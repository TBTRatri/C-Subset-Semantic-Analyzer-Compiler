#ifndef SCOPE_TABLE_H
#define SCOPE_TABLE_H

#include "symbol_info.h"
#include <list>
#include <vector>
#include <fstream>
#include <string>

using namespace std;

class scope_table {
private:
    int bucket_count; // Number of buckets in the hash table [cite: 86]
    int unique_id;    // Unique ID for the scope [cite: 79]
    scope_table *parent_scope = nullptr; // Pointer to the outer scope [cite: 78]
    vector<list<symbol_info *>> table;

    // Standard hash function based on the sum of characters [cite: 75, 76]
    int hash_function(const string &name) {
        int s = 0;
        for (char x : name) {
            s += (int)x;
        }
        return s % bucket_count; // Keep within bucket size range [cite: 77]
    }

public:
    // Constructor matching the requirement for an integer parameter 'n' [cite: 86]
    scope_table(int n, int id, scope_table *parent)
        : bucket_count(n), unique_id(id), parent_scope(parent) {
        table.resize(bucket_count);
    }

    // Destructor to deallocate memory for symbol_info objects 
    ~scope_table() {
        for (int i = 0; i < bucket_count; i++) {
            for (auto symbol : table[i]) {
                delete symbol;
            }
            table[i].clear();
        }
    }

    // Getters
    scope_table *get_parent_scope() { return parent_scope; }
    int get_unique_id() { return unique_id; }

    // Look up: Search only this specific hash table for a symbol [cite: 83]
    symbol_info *lookup_in_scope(string name) {
        int hash_val = hash_function(name);
        for (symbol_info *current : table[hash_val]) {
            if (current->getname() == name) {
                return current;
            }
        }
        return nullptr;
    }

    // Insert: Add symbol if not already present in this scope [cite: 81, 82]
    bool insert_in_scope(symbol_info *symbol) {
        if (lookup_in_scope(symbol->getname()) != nullptr) {
            return false; // Already exists in this scope
        }
        int hash_val = hash_function(symbol->getname());
        table[hash_val].push_back(symbol);
        return true;
    }

    // Delete: Remove an entry from the scope table [cite: 84]
    bool delete_from_scope(string name) {
        int hash_val = hash_function(name);
        for (auto it = table[hash_val].begin(); it != table[hash_val].end(); ++it) {
            if ((*it)->getname() == name) {
                delete *it; // Free memory
                table[hash_val].erase(it);
                return true;
            }
        }
        return false;
    }

    // Print: Print the scope table in the logfile as per format [cite: 85, 129, 130]
    void print_scope_table(ofstream &outlog) {
        outlog << " ScopeTable # " << unique_id << endl;
        for (int i = 0; i < bucket_count; i++) {
            if (!table[i].empty()) {
                outlog << " " << i << " --> ";
                for (auto current : table[i]) {
                    outlog << "< " << current->getname() << " : " << current->gettype() << " > ";
                }
                outlog << endl;
            }
        }
    }
};

#endif
