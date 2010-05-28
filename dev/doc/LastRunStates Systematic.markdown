Last Run States
===============

* run
  * success
  * aborted
    * manually (? better term ?)
      * skip
        * skip-tagged
        * [optional!] component missing (:use => foo, foo was not found)
        * [optional!] library missing (:requires => foo, foo could not be required)
        * [optional!] dependency missing (:depends_on => foo, while foo was not provide)
      * pending
        * pending-tagged
        * no setup block given
        * no exercise block given
        * no verify block given
        * no teardown block given
    * automatically (? better term ?)
      * failure
        * setup failure
          * [default] component missing (:use => foo, foo was not found)
          * [default] library missing (:requires => foo, foo could not be required)
          * [default] dependency missing (:depends_on => foo, while foo was not provide)
        * verification failure
      * error
        * setup error
        * exercise error
        * verification error
        * teardown error
* unrun
  * new (the test didn't exist in the last run)
  * deselected (via glob, last-run-state or tag)


The smallest unit that has a last-run-state is Unit, NOT Test. So all test
variants of a unit are either run or ignored.
