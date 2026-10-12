import os
import shutil
import subprocess
import streamlit as st

st.set_page_config(
    page_title="C-Subset Semantic Analyzer",
    page_icon="🧠",
    layout="wide"
)

st.title("🧠 C-Subset Semantic Analyzer & Scope Explorer")
st.markdown(
    "Interactive Lexical, Syntax, and **Semantic Analyzer** featuring hierarchical "
    "**ScopeTable** and **SymbolTable** resolution."
)

@st.cache_resource
def build_compiler():
    """Builds the Flex and Bison semantic compiler binary."""
    try:
        # Detect parser file (.y)
        parser_file = "parser.y" if os.path.exists("parser.y") else "22101869.y"
        # Detect lexer file (.l)
        lexer_file = "lexer.l" if os.path.exists("lexer.l") else "22101869.l"

        if not os.path.exists(parser_file):
            return False, f"Parser file ({parser_file}) not found."
        if not os.path.exists(lexer_file):
            return False, f"Lexer file ({lexer_file}) not found."

        # 1. Run Bison to generate parser implementation and token header
        bison_res = subprocess.run(
            ["bison", "-d", "-y", parser_file],
            capture_output=True,
            text=True
        )
        if bison_res.returncode != 0:
            return False, f"Bison Error:\n{bison_res.stderr}"

        # Guarantee both standard (y.tab.h) and student ID (22101869.tab.h) headers exist
        if os.path.exists("y.tab.h"):
            shutil.copy("y.tab.h", "22101869.tab.h")

        # 2. Run Flex to generate lexical scanner
        flex_res = subprocess.run(
            ["flex", "-o", "lex.yy.c", lexer_file],
            capture_output=True,
            text=True
        )
        if flex_res.returncode != 0:
            return False, f"Flex Error:\n{flex_res.stderr}"

        # 3. Compile and link with g++
        compile_cmd = [
            "g++", "-w", "-std=c++11",
            "y.tab.c", "lex.yy.c",
            "-o", "compiler"
        ]
        gcc_res = subprocess.run(compile_cmd, capture_output=True, text=True)
        if gcc_res.returncode != 0:
            return False, f"G++ Compilation Error:\n{gcc_res.stderr}"

        return True, "Compiler built successfully!"
    except Exception as e:
        return False, f"Execution failed: {str(e)}"

# Build status check
with st.spinner("Compiling Semantic Parser & Scope Engine..."):
    success, msg = build_compiler()

if not success:
    st.error(msg)
    st.stop()

col_left, col_right = st.columns([1, 1])

# Default C sample code
default_code = """int a, b;
float c;

int foo(int x, int y) {
    return x + y;
}

int main() {
    int res;
    res = foo(10, 20);
    return 0;
}
"""

if os.path.exists("input.c"):
    try:
        with open("input.c", "r") as f:
            content = f.read().strip()
            if content:
                default_code = content
    except Exception:
        pass

with col_left:
    st.subheader("Source Code Input")
    source_code = st.text_area(
        "Write C-subset code to analyze:",
        value=default_code,
        height=380,
        help="Input program to analyze for type correctness, scoping, and grammar."
    )
    run_button = st.button("Analyze Semantics & Scopes", type="primary")

with col_right:
    st.subheader("Diagnostics & Output")

    if run_button or source_code:
        with open("temp_input.c", "w") as f:
            f.write(source_code)

        try:
            result = subprocess.run(
                ["./compiler", "temp_input.c"],
                capture_output=True,
                text=True,
                timeout=5
            )

            tabs = st.tabs(["Scope & Symbol Logs", "Standard Output", "Semantic Errors"])

            with tabs[0]:
                output_found = False
                for fname in ["log.txt", "parser_log.txt", "symbol_table.txt", "scope_log.txt"]:
                    if os.path.exists(fname):
                        with open(fname, "r") as f:
                            st.code(f.read(), language="text")
                        output_found = True
                        break
                if not output_found:
                    if result.stdout.strip():
                        st.code(result.stdout, language="text")
                    else:
                        st.info("Analysis completed.")

            with tabs[1]:
                if result.stdout.strip():
                    st.code(result.stdout, language="text")
                else:
                    st.info("No terminal stdout produced.")

            with tabs[2]:
                if os.path.exists("error.txt") and os.path.getsize("error.txt") > 0:
                    with open("error.txt", "r") as f:
                        st.error(f.read())
                elif result.stderr.strip():
                    st.error(result.stderr)
                else:
                    st.success("No semantic or syntax errors found! Scope resolution verified.")

        except subprocess.TimeoutExpired:
            st.error("Process timed out.")
        except Exception as e:
            st.error(f"Execution error: {str(e)}")
