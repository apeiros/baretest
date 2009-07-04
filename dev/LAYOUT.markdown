Bare Test
=========



Project Layout
--------------

Baretest has a concept called 'layout'. It means that if you build your project up in a conventional
way, baretest can relieve you of a lot of boilerplate code dealing with requiring and finding files
and directories.

The following is the standard layout:

* project-directory
  * bin:  the directory for your executables
  * lib:  the directory for your ruby files that can be required, baretest will add this directory to
          $LOAD_PATH
  * test: the directory for your baretest files
    * external:    this directory can contain files that are necessary for your tests but should be
                   ignored by baretest.
                   The path is available in its expanded form via Test.layout.external.
    * helper:      files that are needed to support your tests.
                   The path is available via Test.layout.helper.
    * suite:       the directory for your assertions, this directory rebuilds the structure of the
                   project-directory
    * unit:        Where you put your unit tests
    * integration: Where you put your integration tests
    * system:      Where you put your system tests
    * setup.rb:    this file is automatically required prior to loading all tests
    * teardown.rb: this file is automatically required after all tests are run

All other 