# Changelog

### 0.1.5

### 0.1.4 (2016-10-13)
* Bugfix: pass HostConfig when creating rather than when starting a Docker container, to work with Docker 1.12 and above.
* Abstracted docker image names from `lib/util.coffee` to `config/`.
* Added *BL Modules* usage example to `README.md`.
* Updated `blrunner` docker image version to `v0.5.2`.
* Updated dockerode version.

### 0.1.3 (2016-01-05)
* Bugfix: parse query as string instead of object.
* Updated copyright to 2016.

### 0.1.2 (2015-09-22)
* Use the right Docker image:tag.

### 0.1.1 (2015-09-22)
* A specific tag is now used when pulling Docker images.
* Internal improvements.

### 0.1.0 (2015-09-18)
* Initial public release.