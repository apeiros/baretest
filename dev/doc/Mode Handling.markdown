File Mode
=========
Only the specified files are run.

### Execution order
1. load global configuration
2. load user configuration
3. load globbed test files (default: <pwd>/**/*.rb)
4. finish loading
5. run tests with no helpers, no external, ...



Layout Mode
===========

a specified directory structure is available.
* Helper files,
* External files
* Library files
* Test library files
* etc.
can be found according to the layout

### Execution order
1. load global configuration
2. load user configuration
3. load layout
4. load layout configuration
5. load setup
6. load globbed test files (default: <test-dir>/{<units>}/**/*.rb)
7. finish loading
8. modify env
9. run tests with helpers, external, ...
