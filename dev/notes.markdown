Writing Formatters
------------------

Bare-Test has 4 cycles:
initialize
:   All requires and extends should be done here.
    This method is only executed once and will invoke the following methods:
    init_mock
    :   specific init to initialize the mock
    init_formatter
    :   specific init to initialize the formatter
run
:   You should not touch this. Bare-Test prepares there for running the tests.
run_all
:   Outermost call. Invokes run_suite on toplevel suite. Invoked once per
    running all tests.
run_suite
:   Run once per suite per running all tests. Invokes run_suite per contained
    suite and run_test per contained assertion.
    Increments @count[:suite] by 1 after having run.
run_test
:   Run once per test.
    Increments @count[:test] and @count[status] by 1 after having run.
    Status is Assertion#status, one of :success, :failure, :error, :pending,
    :skipped.



Interactive Formatter
---------------------

* Read IRB source for how to drop into a session with code executed
* Add diagnostics to Assertions/Suites: line of definition (e.g. via caller).
  That way the code piece that failed could be displayed (trimmed and unindented
  text between line of definition of the current assertion and line of
  definition of closest assertion/suite/eof)
