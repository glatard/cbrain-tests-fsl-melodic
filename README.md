# How to use

* Install the [CBRAIN Ruby API](https://github.com/aces/cbrain-apis): `git clone https://github.com/aces/cbrain-apis.git`

* Download the test data from [http://www.creatis.insa-lyon.fr/~glatard/test-melodic-cbrain/data.tgz](http://www.creatis.insa-lyon.fr/~glatard/test-melodic-cbrain/data.tgz)

* Extract the test data: `tar zxvf data.tgz`

* Tests are located in directory `tests`. To run them:

`ruby -I<path-to-cbrain-ruby-api> ./run_test.rb <path-to-test-file> <path-to-data-dir> --overwrite-all`

# Limitations

The test script submits tasks to CBRAIN and puts the expected final status in the task description. It does not:

* Monitor tasks to completion.
* Check that the results of "Completed" tasks have the right parent in CBRAIN.
* Check that the FSL melodic viewer works for results of "Completed" tasks.
* Check that the results of "Completed" tasks are actually correct.
* Check that the logs of "Failed" tasks contain proper error messages.
