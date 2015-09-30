# How to use

* Install the [CBRAIN Ruby API](https://github.com/aces/cbrain-apis): `git clone https://github.com/aces/cbrain-apis.git`

* Clone this repository: `git clone https://github.com/glatard/cbrain-tests-fsl-melodic.git`

* Move to directory `cbrain-tests-fsl-melodic` and get the test data with git annex: `git annex get data/*`

* Tests are located in directory `tests`. To run them:

`ruby -I<path-to-cbrain-ruby-api> ./run_test.rb <path-to-test-file> <path-to-data-dir> --overwrite-all`

# Available tests

## Individual analyses

Should complete: 
* Nifti files
* Minc files
* Nifti files with auto-correction of TR, number of volumes, number of voxels
* Nifti files with custom Nifti standard brain
* Nifti files with custom Minc standard brain
* Nifti files with different dimensions
* Nifti files with different TRs

Should fail with proper error message:
* Nifti files with few volumes

## Group analyses

Should complete: 
* Nifti files
* Minc files

Should complete with warning:
* Nifti files with different TRs

Should fail with proper error message: 
* Nifti files with different dimensions
* Nifti files with few volumes


# Limitations

The test script submits tasks to CBRAIN and puts the expected final status in the task description. It does not:

* Monitor tasks to completion.
* Check that the results of "Completed" tasks have the right parent in CBRAIN.
* Check that the FSL melodic viewer works for results of "Completed" tasks.
* Check that the results of "Completed" tasks are actually correct.
* Check that the logs of "Failed" tasks contain proper error messages.
