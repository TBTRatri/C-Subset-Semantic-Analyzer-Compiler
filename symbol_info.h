#ifndef SYMBOL_INFO_H
#define SYMBOL_INFO_H

#include <iostream>
#include <string>
#include <vector>

using namespace std;

class symbol_info {
private:
    string name;
    string type; // e.g., "ID", "KEYWORD", "INT" [cite: 17, 72]
    
    // Additional information for CSE 420 Lab 2 [cite: 118]
    string data_type; // e.g., "int", "float" [cite: 113]
    bool is_array = false;
    int array_size = 0; // [cite: 114]

    bool is_function = false;
    string return_type; // [cite: 115]
    vector<pair<string, string>> parameters; // List of {type, name} [cite: 116]

public:
    // Constructors
    symbol_info(string name, string type) : name(name), type(type) {}
    
    symbol_info(string name, string type, string data_type)
        : name(name), type(type), data_type(data_type) {}
    
    symbol_info(string name, string type, string data_type, int array_size)
        : name(name), type(type), data_type(data_type), array_size(array_size), is_array(true) {}

    // Getters
    string getname() const { return name; }
    string gettype() const { return type; }
    string get_data_type() const { return data_type; }
    bool get_is_array() const { return is_array; }
    int get_array_size() const { return array_size; }
    bool get_is_function() const { return is_function; }
    string get_return_type() const { return return_type; }
    vector<pair<string, string>> get_parameters() const { return parameters; }

    // Setters
    void setname(const string &name) { this->name = name; }
    void settype(const string &type) { this->type = type; }
    void set_data_type(const string &data_type) { this->data_type = data_type; }
    void set_array_size(int size) { this->array_size = size; this->is_array = true; }
    
    void set_as_function(const string &ret_type, const vector<pair<string, string>> &params) {
        this->is_function = true;
        this->return_type = ret_type;
        this->parameters = params;
    }

    // Standard destructor
    ~symbol_info() {} 
};

#endif
