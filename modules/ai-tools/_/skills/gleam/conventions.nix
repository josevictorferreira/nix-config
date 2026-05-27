{ lib
, pkgs
, isDarwin
, npx
, defaultBrowser
, kebabToHuman
, ...
}:
{
  allowed-tools = [
    "Read"
    "Grep"
    "Glob"
    "Write"
    "Edit"
    "Bash"
  ];
  name = "gleam-conventions";
  description = "Gleam language conventions, patterns, and anti-patterns covering naming (snake_case, qualified imports, x_to_y conversion functions, try_ prefix), function annotations, Result vs Option, descriptive error type design, making invalid states impossible, module organization, and anti-patterns like panicking in libraries, dynamic FFI, and category theory overuse.";
  prompt = ''
    # Gleam Conventions, Patterns, and Anti-patterns

    ## Conventions

    Gleam enforces `snake_case` for variables, constants, and functions, and
    `PascalCase` for types and variants.

    ### Avoid unqualified importing of functions and constants

    Always used the qualified syntax for functions and constants defined in other
    modules.

    ```gleam
    import gleam/list
    import gleam/string

    pub fn reverse(input: String) -> String {
      input
      |> string.to_graphemes
      |> list.reverse
      |> string.concat
    }
    ```

    Types and record constructors may be used with the unqualified syntax,
    providing you think it does not make the code more difficult to read.

    ### Annotate all module functions

    All module functions should have annotations for their argument types and for
    their return type.

    ```gleam
    fn calculate_total(amounts: List(Float), service_charge: Float) -> Float { ... }
    ```

    ### Use result for fallible functions

    All functions that can succeed or fail must return a Result in Gleam.
    Never use Option for fallible functions. Panics are not used for fallible
    functions, especially within libraries.

    ```gleam
    pub fn first(list: List(a)) -> Result(a, Nil) {
      case list {
        [item, ..] -> Ok(item)
        _ -> Error(Nil)
      }
    }
    ```

    ### Use singular for module names

    Module names are singular, not plural.

    ```gleam
    import app/user    // Good
    import app/users   // Bad
    ```

    ### Treat acronyms as single words

    ```gleam
    let json: Json = build_json()    // Good
    let j_s_o_n: JSON = build_j_s_o_n()  // Bad
    ```

    ### Name conversion functions as prescribed

    Use `x_to_y` convention. If the module name matches the type name, omit the
    type prefix from the function name. Use descriptive names when available.

    ```gleam
    pub fn json_to_string(data: Json) -> String
    pub fn to_string(id: Identifier) -> String    // In identifier module
    pub fn date_to_rfc3339(date: Date) -> String
    pub fn round(data: Float) -> Int              // Instead of float_to_int
    ```

    ### Name short-circuiting result functions as prescribed

    Use `try_` prefix for result-handling versions of existing functions that
    short-circuit on error, unless a domain-specific name fits better.

    ```gleam
    pub fn try_map(list: List(a), f: fn(a) -> Result(b, e)) -> Result(List(b), e)
    ```

    ### Use the core libraries

    Use `gleam_stdlib`, `gleam_time`, `gleam_http`, `gleam_erlang`, `gleam_otp`,
    `gleam_javascript` rather than replicating functionality.

    ### Use the correct source code directory

    - `src` — Application/library code. Imports from dependencies and `src/` only.
    - `test` — Test code. Imports from any dependencies and any directory.
    - `dev` — Development helpers. Imports from any dependencies and any directory.

    ## Patterns

    ### Design descriptive errors

    Design error variants to describe what the error was in terms of your business
    domain. Each variant should hold additional information about the error instance.

    ```gleam
    pub type NotesError {
      NoteAlreadyExists(path: String)
      NoteCouldNotBeCreated(path: String, reason: simplifile.FileError)
      NoteCouldNotBeRead(path: String, reason: simplifile.FileError)
      NoteInvalidFrontmatter(path: String, reason: tom.ParseError)
    }
    ```

    ### Comment liberally

    Comments explain both _what_ the code does and _why_. Adding comments does not
    mean the code itself can be written in an unclear way.

    ### Make invalid states impossible

    Use Gleam's type system to precisely model your domain so invalid data cannot
    be constructed.

    ```gleam
    pub type Visitor {
      LoggedInUser(id: Int, email: String)
      Guest
    }
    // Bad: allows invalid states (id without email)
    pub type Visitor {
      Visitor(id: Option(Int), email: Option(String))
    }
    ```

    ## Anti-patterns

    - **Fragmented modules**: Do not prematurely split modules. Focus on business domain.
    - **Panicking in libraries**: Libraries must not panic — always return Result.
    - **Global namespace pollution**: Place modules within a uniquely named directory matching the package name.
    - **Namespace trespassing**: Do not place modules in a top-level directory belonging to another package.
    - **Using dynamic with FFI**: Never use `Dynamic` for FFI types. Create new opaque types instead.
    - **Category theory overuse**: Avoid complex abstractions. Solve specific problems with specific solutions.
  '';
}
