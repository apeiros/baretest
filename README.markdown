Bare Test
=========



Summary
-------

A minimal Testframework.
Three methods to use it, Twenty to master it, about hundred lines of code[^foot].
Bare Test, try it and you'll love it.



Description
-----------

Baretest is a Testframework that tries to stay out of your way, but support you when you want it.
In order to do so it has a load of features:

* Strightforward and terse assertions (just a block whose return value defines
  success/failure)
* Easy grouping of assertions into suites
* BDD style specifications/test descriptions (NOT code), also extractable
* Uncomplicated dependency testing and skipping
* Helpers to deal painlessly with raising, throwing, float imprecision,
  unordered collections etc.
* Ships with colored Shell formatter, Diagnostic-, XML- and TAP formatter
* Interactive mode - drops you into an irb session within failed assertion
  with all setup methods executed, so you can inspect interactively why it
  failed.
* Trivial to add new formatters (the standard formatters are only roughly 20-50
  lines of code each)
* Teardown and Setup for suites
* Callbacks to integrate mock libraries
* API to use it from code, such as rake tasks (comes with an example rake-task)
* baretest executable to run tests on multiple files at once
* Diagnostic assertion helpers (e.g. same(:a, :b) will give you 'Expected
  :a but got :b' as diagnostic)



Quick Try
---------

1. Download from github and unpack (or clone)
2. Change into the baretest directory: `cd the/baretest/directory`
3. Run the examples: `./bin/baretest examples/test.rb`

That's it. Alternatively you can run baretests own tests, and play with formatters:
`./bin/baretest -f tap`



Install
-------

1. run `gem install baretest`, alternatively run `sudo gem install baretest`
2. There is no 2.

An inofficial way to install it (may not work yet):

1. Download from github and unpack (or clone)
2. Change into the baretest directory: `cd the/baretest/directory`
3. Run the installation task: `rake install:lib`



Executable
----------

    Usage: baretest [options] [glob, ...]
    Glob defaults to 'test/**/*.rb'
    Providing a directory as glob is equivalent to dir/**/*.rb
    Options:
      -f, --format FORMAT      use FORMAT for output
      -F, --formats            show available formats
      -d, --debug              set debugging flags (set $DEBUG to true)
      -i, --interactive        drop into IRB on error or failure
      -s, --setup FILE         specify setup file
      -v, --version            print the version and exit
      -w, --warn               turn warnings on for your script



Planned Features
----------------

* Word-wrapping for CLI runner
* Flags for color and verbose (\[no-]color and \[no-]verbose) for the executable
* Passing on flags/options for formatters
* Alternative CLI runner with status implicit via colored/bg-colored descriptions
* Alternative CLI runner which prints the name of the test prior the label and rewrites
  the line when the test has executed to add status & coloring.
* Simple stubbing with automatic cleanup at teardown. Example:

        assert "Should require a single file listed in :requires option." do |a|
          file = 'foo/bar'
          stub(Kernel, :require) do |file, *args| a.touch(file) end
          ::Test::Suite.create(nil, nil, :requires => file)
        
          touched file
        end

* Inline tests via Module#describe (basically the same as Test::Suite#suite)
* YARD code to extract the specifications without running the code
* A redmine plugin
* --fail-all flag, to test/review diagnostics of tests (no idea how to do that yet)



Rejected Features
-----------------

* Currently none


A Bit of Background
-------------------

Originally, bare-test started out as a project for shits & giggles on the flight
back from vegas (railsconf09), to prove that it is possible to have a fully
fledged test-framework in under 100 lines of source-code.
Later I realized that this project could become more. For one it was (still is)
dead simple to add another formatter, it is just as dead simple to embedd it
in code.
The principles are trivial to understand, embrace and extend.
Upon that it dawned me, that the project was viable and I began adding features
not found in other projects.



Example Testsuite
-----------------

From examples/test.rb:

    Test.run_if_mainfile do
      # assertions and refutations can be grouped in suites. They will share
      # setup and teardown
      # they don't have to be in suites, though
      suite "Success" do
        assert "An assertion returning a trueish value (non nil/false) is a success" do
          true
        end
      end

      suite "Failure" do
        assert "An assertion returning a falsish value (nil/false) is a failure" do
          false
        end
      end

      suite "Pending" do
        assert "An assertion without a block is pending"
      end

      suite "Error" do
        assert "Uncaught exceptions in an assertion are an error" do
          raise "Error!"
        end
      end

      suite "Special assertions" do
        assert "Assert a block to raise" do
          raises do
            sleep(rand()/3+0.05)
            raise "If this raises then the assertion is a success"
          end
        end

        assert "Assert a float to be close to another" do
          a = 0.18 - 0.01
          b = 0.17
          within_delta a, b, 0.001
        end

        suite "Nested suite" do
          assert "Assert two randomly ordered arrays to contain the same values" do
            a = [*"A".."Z"] # an array with values from A to Z
            b = a.sort_by { rand }
            a.equal_unordered(b) # can be used with any Enumerable, uses hash-key identity
          end
        end
      end

      suite "Setup & Teardown" do
        setup do
          @foo = "foo"
          @bar = "bar"
        end

        assert "@foo should be set" do
          @foo == "foo"
        end

        suite "Nested suite" do
          setup do
            @bar = "inner bar"
            @baz = "baz"
          end

          assert "@foo is inherited" do
            @foo == "foo"
          end

          assert "@bar is overridden" do
            @bar == "inner bar"
          end

          assert "@baz is defined only for inner" do
            @baz == "baz"
          end
        end

        teardown do
          @foo = nil # not that it'd make much sense, just to demonstrate
        end
      end

      suite "Dependencies", :requires => ['foo', 'bar'] do
        assert "Will be skipped, due to unsatisfied dependencies" do
          raise "This code therefore will never be executed"
        end
      end
    end



Known bugs
----------

Currently none.


Foot Notes
----------
[^foot]: The abbreviated form without support code and output formatters.
         The normal code is expanded to more lines for readability.
