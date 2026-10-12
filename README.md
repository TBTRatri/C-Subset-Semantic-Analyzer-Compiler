# C-Subset Semantic Analyzer & Hierarchical Symbol Table

A multi-phase compiler intermediate stage featuring **Semantic Analysis**, type checking, function signature validation, and hierarchical scoped symbol table tracking implemented using **Flex**, **Bison (Yacc)**, and C++.

---

## Compiler Architecture & Features

1. **Hierarchical Scope Management:**
   - `scope_table.h`: Hash table managing identifiers within a specific scope. Handles lookup, insertion, and deletion within local contexts.
   - `symbol_table.h`: Manages nested scopes using a stack of `ScopeTable` instances. Supports scope entry (`enterScope()`), scope exit (`exitScope()`), and recursive parent-chain identifier resolution.
   - `symbol_info.h`: Tracks symbol metadata (identifier name, type, array bounds, function parameter lists, and return types).

2. **Semantic Verification:**
   - Detection of undeclared and multiply declared variables/functions.
   - Strict expression type checking (integer, float, void).
   - Array index validation and dimension mismatch checks.
   - Function call parameter type and arity verification.

3. **Lexical & Syntax Pipeline:**
   - `lexer.l`: Tokenizes expressions, control structures, and source tokens.
   - `parser.y`: Context-free grammar rules augmented with semantic action rules and syntax error recovery.

---

## File Structure

```text
├── lexer.l              # Flex scanner rules
├── parser.y             # Bison grammar rules with semantic actions
├── symbol_info.h        # Symbol token definition and metadata
├── scope_table.h        # Individual scope hash table implementation
├── symbol_table.h       # Stack of nested scopes
├── input.c              # Test C-subset source program
├── script.sh            # Local compilation script
├── app.py               # Streamlit cloud interactive runner
├── packages.txt         # Linux build dependencies (flex, bison, g++)
├── requirements.txt     # Python requirements (streamlit)
└── README.md
