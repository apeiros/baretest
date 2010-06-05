In Prose
========

* The return value is only considered in 'verify' blocks. Those have to return a
  trueish value. Nil and false make the verify fail.
* Setting the test status to failure is only allowed in setup, verify and teardown.
  * setup: missing dependency, source file, component, ...
  * verify: verification failed
  * teardown: additional verifications performed by components (e.g. mock teardowns)
* Setting the test status to pending is always final
  The moment a test becomes pending, execution of it is halted
* Setting the test status to skipped is always final
  The moment a test becomes skipped, execution of it is halted
* Setting the test status to error is final in setup, verify and teardown, but
  NOT in exercise.
  This is to allow testing for exceptions being raised
* If there's no test status set at the end of all phases, the test status
  becomes set to success. The phase of the status will be :cleanup



nocontrol:    happens when somebody uses 'return' in a setup block eg.
status set:   set the status unless the status has already been set or forced
status is:    status force + mark as unchangeable
status force: set the status unless the status is marked unchangeable

broken test:  this means the tests definition has a bug, execution will be prematurely terminated
success:      this means the test definition is ok, and the test so far went well and indicates behaviour as specified/assumed
failure:      this means the test definition is ok, but the test didn't go well and indicates behaviour misses specification/assumption
skipped:      this means the test was prematurely terminated for a given reason
pending:      this means the test was prematurely terminated for the test not yet being completly implemented (a specific case of 'skipped'?)

phase     return    condition     significance          action
setup     trueish   -             success,              continue
setup     falsish   -             success,              continue
setup     -         nocontrol     broken test           teardown as much as possible, status is error
setup     -         failure       broken test           teardown as much as possible, status is error
setup     -         error         broken test           teardown as much as possible, status is error
setup     -         skip          skipped test          teardown as much as possible, status is skipped
setup     -         pending       pending test          teardown as much as possible, status is pending

exercise  trueish   -             success               continue
exercise  falsish   -             success               continue
exercise  -         failure       broken test           teardown all, status is error
exercise  -         error         broken test or        continue, status set error
                                  testing raise/throw
exercise  -         skip          skipped test          teardown all, status is skipped
exercise  -         pending       pending test          teardown all, status is pending

verify    trueish   -             success               continue
verify    falsish   -             failure               continue, status is failure
verify    -         failure       failure               continue, status is failure
verify    -         error         broken test           teardown all, status is error
verify    -         skip          skipped test          teardown all, status is skipped
verify    -         pending       pending test          teardown all, status is pending

teardown  trueish   -             success               continue
teardown  falsish   -             success               continue
teardown  -         failure       failure               continue, status is failure
teardown  -         error         broken test           continue, status is error
teardown  -         skip          skipped test          continue, status is skipped  <-- ??? should that be allowed?
teardown  -         pending       pending test          continue, status is pending  <-- ??? should that be allowed?

A verify or teardown can force the status. This is useful e.g. to verify raises
or check for test-spies.