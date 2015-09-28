# How to use

* Install the [CBRAIN Ruby API](https://github.com/aces/cbrain-apis): `git clone https://github.com/aces/cbrain-apis.git`

* Download the test data from [http://www.creatis.insa-lyon.fr/~glatard/test-melodic-cbrain/data.tgz](http://www.creatis.insa-lyon.fr/~glatard/test-melodic-cbrain/data.tgz)

* Extract the test data: `tar zxvf data.tgz`

* Tests are located in directory `tests`. To run them:

`ruby -I<path-to-cbrain-ruby-api> ./run_test.rb <path-to-test-file> <path-to-data-dir> --overwrite-all`