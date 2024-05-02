
# ci friendly process
The bottom line is we do not want to use the Maven release plugin. It is heavy, time-consuming, and not intended to use with ci-friendly '<revision>' property.

## General Approach
The build should read the version from the '<revision>' tag in the parent pom and then build the repo passing -Drevision=xxx to build the appropriate versions.  We will use the x.y from this property but ignore the .z-<modifiers> and construct the version as follows:

### Feature branches
1. Set version to x.y.<sha>.<branch_name>-SNAPSHOT
2. Do not tag anything

### Protected branch
1. Validations: Check if the release tag exists and check for snapshot dependencies; both of these will fail the build
2. Set version to x.y.<sha1> as a projected branch is always a release
3. Run clean install package # Note: deploy run as a separate step so we don't push artifacts or create tags if build/tests fail.
4. Run deploy
5. Tag the protected branch with the release id

## Benefits
1. Your builds are measurably faster than using the release plugin
2. Every merge commit creates a release and tag
3. There are no commits to the projected branch by CI, so we don't create additional builds in the pipeline.

## references:
1. https://stackoverflow.com/questions/59641739/maven-release-plugin-together-with-cifriendly-versions
2. https://medium.com/outbrain-engineering/faster-release-with-maven-ci-friendly-versions-and-a-customised-flatten-plugin-fe53f0fcc0df
3. https://stackoverflow.com/questions/8988405/automatically-incrementing-a-build-number-in-a-java-project
4. https://maven.apache.org/maven-ci-friendly.html
5. Project forked from jitpack/maven-modular

## Below are five tests output
	 Test 1: show re-running a release due to the tag existing (this protects releases)
	 Test 2: show we fail if there are snapshot dependencies on a release
	 Test 3: show a proper release, not version is 1.0.sha1
	 Test 4: Show a branch release - note the version is 1.0.sha.branch-SNAPSHOT
	 Step 4a Validate maven artifacts
	 Test 5: Show a local build version is 1.0.sha.local-SNAPSHOT

## Test 1: show re-running a release due to the tag existing (this protects releases)
```
(base) ➜  maven-modular git:(master) ✗ sh  ./release.sh RELEASE_CHECK
MVN_VERSION=1.0.0-local-SNAPSHOT
GIT_BRANCH=master
HEAD_SHA=11a078e
RELEASE_VERSION=1.0.11a078e
BRANCH_VERSION=1.0.11a078e.master-SNAPSHOT
TEST_OPTION=RELEASE_CHECK
Step 1 Check if release exit if it does fail
ERROR: Tag 1.0.11a078e exists, to rebuild version delete tag the re-run
```

### cleanup tag 
```
(base) ➜  maven-modular git:(master) ✗ git tag --delete 1.0.11a078e
Deleted tag '1.0.11a078e' (was 11a078e)
```

## Test 2: show we fail if there are snapshot dependencies on a release

```
(base) ➜  maven-modular git:(master) ✗ sh  ./release.sh RELEASE_CHECK
MVN_VERSION=1.0.0-local-SNAPSHOT
GIT_BRANCH=master
HEAD_SHA=11a078e
RELEASE_VERSION=1.0.11a078e
BRANCH_VERSION=1.0.11a078e.master-SNAPSHOT
TEST_OPTION=RELEASE_CHECK
Step 1 Check if release exit if it does fail
Step 2 check if we have any snapshots, fail to build if we do
ERROR: cannot release with SNAPSHOT dependencies
------------------------------------------------
./module1/pom.xml: <version>5.11.0-SNAPSHOT</version>
------------------------------------------------
Updated 1 path from the index
```

## Test 3: show a proper release, note version is 1.0.sha1

```
(base) ➜  maven-modular git:(master) ✗ sh  ./release.sh RELEASE_NO_CHECK
MVN_VERSION=1.0.0-local-SNAPSHOT
GIT_BRANCH=master
HEAD_SHA=11a078e
RELEASE_VERSION=1.0.11a078e
BRANCH_VERSION=1.0.11a078e.master-SNAPSHOT
TEST_OPTION=RELEASE_NO_CHECK
Step 1 Check if releases exit if it does fail
INFO: Skipping step 2 - checking SNAPSHOT_DEPENDENCIES
Step 3 build branch - fail if the build fails for compile or tests, we save pushing artifacts
[INFO] Scanning for projects...
[INFO] ------------------------------------------------------------------------
[INFO] Reactor Build Order:
[INFO]
[INFO] example-root                                                       [pom]
[INFO] module1                                                            [jar]
[INFO] module2                                                            [jar]
[INFO]
[INFO] ----------------------< io.jitpack:example-root >-----------------------
[INFO] Building example-root 1.0.11a078e                                  [1/3]
[INFO] --------------------------------[ pom ]---------------------------------
[INFO]
[INFO] --- maven-clean-plugin:2.5:clean (default-clean) @ example-root ---
[INFO]
[INFO] --- maven-install-plugin:2.4:install (default-install) @ example-root ---
[INFO] Installing /Users/jim/Library/CloudStorage/OneDrive-NessDigitalEngineering/rf-dev/maven-modular/pom.xml to /Users/jim/.m2/repository/io/jitpack/example-root/1.0.11a078e/example-root-1.0.11a078e.pom
[INFO]
[INFO] -------------------------< io.jitpack:module1 >-------------------------
[INFO] Building module1 1.0.11a078e                                       [2/3]
[INFO] --------------------------------[ jar ]---------------------------------
[INFO]
[INFO] --- maven-clean-plugin:2.5:clean (default-clean) @ module1 ---
[INFO] Deleting /Users/jim/Library/CloudStorage/OneDrive-NessDigitalEngineering/rf-dev/maven-modular/module1/target
[INFO]
[INFO] --- maven-resources-plugin:2.6:resources (default-resources) @ module1 ---
[INFO] Using 'UTF-8' encoding to copy filtered resources.
[INFO] skip non existing resourceDirectory /Users/jim/Library/CloudStorage/OneDrive-NessDigitalEngineering/rf-dev/maven-modular/module1/src/main/resources
[INFO]
[INFO] --- maven-compiler-plugin:3.2:compile (default-compile) @ module1 ---
[INFO] Changes detected - recompiling the module!
[INFO] Compiling 1 source file to /Users/jim/Library/CloudStorage/OneDrive-NessDigitalEngineering/rf-dev/maven-modular/module1/target/classes
[INFO]
[INFO] --- maven-resources-plugin:2.6:testResources (default-testResources) @ module1 ---
[INFO] Using 'UTF-8' encoding to copy filtered resources.
[INFO] skip non existing resourceDirectory /Users/jim/Library/CloudStorage/OneDrive-NessDigitalEngineering/rf-dev/maven-modular/module1/src/test/resources
[INFO]
[INFO] --- maven-compiler-plugin:3.2:testCompile (default-testCompile) @ module1 ---
[INFO] Changes detected - recompiling the module!
[INFO] Compiling 1 source file to /Users/jim/Library/CloudStorage/OneDrive-NessDigitalEngineering/rf-dev/maven-modular/module1/target/test-classes
[INFO]
[INFO] --- maven-surefire-plugin:2.12.4:test (default-test) @ module1 ---
[INFO] Surefire report directory: /Users/jim/Library/CloudStorage/OneDrive-NessDigitalEngineering/rf-dev/maven-modular/module1/target/surefire-reports

-------------------------------------------------------
 T E S T S
-------------------------------------------------------
Running io.jitpack.AppTest
Tests run: 1, Failures: 0, Errors: 0, Skipped: 0, Time elapsed: 0.008 sec

Results :

Tests run: 1, Failures: 0, Errors: 0, Skipped: 0

[INFO]
[INFO] --- maven-jar-plugin:2.4:jar (default-jar) @ module1 ---
[INFO] Building jar: /Users/jim/Library/CloudStorage/OneDrive-NessDigitalEngineering/rf-dev/maven-modular/module1/target/module1-1.0.11a078e.jar
[INFO]
[INFO] --- maven-install-plugin:2.4:install (default-install) @ module1 ---
[INFO] Installing /Users/jim/Library/CloudStorage/OneDrive-NessDigitalEngineering/rf-dev/maven-modular/module1/target/module1-1.0.11a078e.jar to /Users/jim/.m2/repository/io/jitpack/module1/1.0.11a078e/module1-1.0.11a078e.jar
[INFO] Installing /Users/jim/Library/CloudStorage/OneDrive-NessDigitalEngineering/rf-dev/maven-modular/module1/pom.xml to /Users/jim/.m2/repository/io/jitpack/module1/1.0.11a078e/module1-1.0.11a078e.pom
[INFO]
[INFO] -------------------------< io.jitpack:module2 >-------------------------
[INFO] Building module2 1.0.11a078e                                       [3/3]
[INFO] --------------------------------[ jar ]---------------------------------
[INFO]
[INFO] --- maven-clean-plugin:2.5:clean (default-clean) @ module2 ---
[INFO] Deleting /Users/jim/Library/CloudStorage/OneDrive-NessDigitalEngineering/rf-dev/maven-modular/module2/target
[INFO]
[INFO] --- maven-resources-plugin:2.6:resources (default-resources) @ module2 ---
[INFO] Using 'UTF-8' encoding to copy filtered resources.
[INFO] skip non existing resourceDirectory /Users/jim/Library/CloudStorage/OneDrive-NessDigitalEngineering/rf-dev/maven-modular/module2/src/main/resources
[INFO]
[INFO] --- maven-compiler-plugin:3.2:compile (default-compile) @ module2 ---
[INFO] Changes detected - recompiling the module!
[INFO] Compiling 1 source file to /Users/jim/Library/CloudStorage/OneDrive-NessDigitalEngineering/rf-dev/maven-modular/module2/target/classes
[INFO]
[INFO] --- maven-resources-plugin:2.6:testResources (default-testResources) @ module2 ---
[INFO] Using 'UTF-8' encoding to copy filtered resources.
[INFO] skip non existing resourceDirectory /Users/jim/Library/CloudStorage/OneDrive-NessDigitalEngineering/rf-dev/maven-modular/module2/src/test/resources
[INFO]
[INFO] --- maven-compiler-plugin:3.2:testCompile (default-testCompile) @ module2 ---
[INFO] Changes detected - recompiling the module!
[INFO] Compiling 1 source file to /Users/jim/Library/CloudStorage/OneDrive-NessDigitalEngineering/rf-dev/maven-modular/module2/target/test-classes
[INFO]
[INFO] --- maven-surefire-plugin:2.12.4:test (default-test) @ module2 ---
[INFO] Surefire report directory: /Users/jim/Library/CloudStorage/OneDrive-NessDigitalEngineering/rf-dev/maven-modular/module2/target/surefire-reports

-------------------------------------------------------
 T E S T S
-------------------------------------------------------
Running io.jitpack.AppTest
Tests run: 1, Failures: 0, Errors: 0, Skipped: 0, Time elapsed: 0.016 sec

Results :

Tests run: 1, Failures: 0, Errors: 0, Skipped: 0

[INFO]
[INFO] --- maven-jar-plugin:2.4:jar (default-jar) @ module2 ---
[INFO] Building jar: /Users/jim/Library/CloudStorage/OneDrive-NessDigitalEngineering/rf-dev/maven-modular/module2/target/module2-1.0.11a078e.jar
[INFO]
[INFO] --- maven-install-plugin:2.4:install (default-install) @ module2 ---
[INFO] Installing /Users/jim/Library/CloudStorage/OneDrive-NessDigitalEngineering/rf-dev/maven-modular/module2/target/module2-1.0.11a078e.jar to /Users/jim/.m2/repository/io/jitpack/module2/1.0.11a078e/module2-1.0.11a078e.jar
[INFO] Installing /Users/jim/Library/CloudStorage/OneDrive-NessDigitalEngineering/rf-dev/maven-modular/module2/pom.xml to /Users/jim/.m2/repository/io/jitpack/module2/1.0.11a078e/module2-1.0.11a078e.pom
[INFO] ------------------------------------------------------------------------
[INFO] Reactor Summary for example-root 1.0.11a078e:
[INFO]
[INFO] example-root ....................................... SUCCESS [  0.215 s]
[INFO] module1 ............................................ SUCCESS [  1.462 s]
[INFO] module2 ............................................ SUCCESS [  0.482 s]
[INFO] ------------------------------------------------------------------------
[INFO] BUILD SUCCESS
[INFO] ------------------------------------------------------------------------
[INFO] Total time:  2.234 s
[INFO] Finished at: 2023-08-06T17:50:42-04:00
[INFO] ------------------------------------------------------------------------
Step 4 if build passes push to nexus
[INFO] Scanning for projects...
[INFO] ------------------------------------------------------------------------
[INFO] Reactor Build Order:
[INFO]
[INFO] example-root                                                       [pom]
[INFO] module1                                                            [jar]
[INFO] module2                                                            [jar]
[INFO] ------------------------------------------------------------------------
[INFO] Reactor Summary for example-root 1.0.11a078e:
[INFO]
[INFO] example-root ....................................... SKIPPED
[INFO] module1 ............................................ SKIPPED
[INFO] module2 ............................................ SKIPPED
[INFO] ------------------------------------------------------------------------
[INFO] BUILD FAILURE
[INFO] ------------------------------------------------------------------------
[INFO] Total time:  0.072 s
[INFO] Finished at: 2023-08-06T17:50:43-04:00
[INFO] ------------------------------------------------------------------------
[ERROR] No goals have been specified for this build. You must specify a valid lifecycle phase or a goal in the format <plugin-prefix>:<goal> or <plugin-group-id>:<plugin-artifact-id>[:<plugin-version>]:<goal>. Available lifecycle phases are: validate, initialize, generate-sources, process-sources, generate-resources, process-resources, compile, process-classes, generate-test-sources, process-test-sources, generate-test-resources, process-test-resources, test-compile, process-test-classes, test, prepare-package, package, pre-integration-test, integration-test, post-integration-test, verify, install, deploy, pre-clean, clean, post-clean, pre-site, site, post-site, site-deploy. -> [Help 1]
[ERROR]
[ERROR] To see the full stack trace of the errors, re-run Maven with the -e switch.
[ERROR] Re-run Maven using the -X switch to enable full debug logging.
[ERROR]
[ERROR] For more information about the errors and possible solutions, please read the following articles:
[ERROR] [Help 1] http://cwiki.apache.org/confluence/display/MAVEN/NoGoalSpecifiedException
Step 5 - Tag the release and push to repo, tag: 1.0.11a078e
Username for 'https://github.com': ^C
```

## Test 4: Show a branch release - note the version is 1.0.sha.branch-SNAPSHOT

```
(base) ➜  maven-modular git:(master) ✗ sh  ./release.sh BRANCH
MVN_VERSION=1.0.0-local-SNAPSHOT
GIT_BRANCH=master
HEAD_SHA=11a078e
RELEASE_VERSION=1.0.11a078e
BRANCH_VERSION=1.0.11a078e.master-SNAPSHOT
TEST_OPTION=BRANCH
BRANCH release
Step 3 build branch - fail if build fails for compile or tests we save pushing artifacts
[INFO] Scanning for projects...
[INFO] ------------------------------------------------------------------------
[INFO] Reactor Build Order:
[INFO]
[INFO] example-root                                                       [pom]
[INFO] module1                                                            [jar]
[INFO] module2                                                            [jar]
[INFO]
[INFO] ----------------------< io.jitpack:example-root >-----------------------
[INFO] Building example-root 1.0.11a078e.master-SNAPSHOT                  [1/3]
[INFO] --------------------------------[ pom ]---------------------------------
[INFO]
[INFO] --- maven-clean-plugin:2.5:clean (default-clean) @ example-root ---
[INFO]
[INFO] --- maven-install-plugin:2.4:install (default-install) @ example-root ---
[INFO] Installing /Users/jim/Library/CloudStorage/OneDrive-NessDigitalEngineering/rf-dev/maven-modular/pom.xml to /Users/jim/.m2/repository/io/jitpack/example-root/1.0.11a078e.master-SNAPSHOT/example-root-1.0.11a078e.master-SNAPSHOT.pom
[INFO]
[INFO] -------------------------< io.jitpack:module1 >-------------------------
[INFO] Building module1 1.0.11a078e.master-SNAPSHOT                       [2/3]
[INFO] --------------------------------[ jar ]---------------------------------
[INFO]
[INFO] --- maven-clean-plugin:2.5:clean (default-clean) @ module1 ---
[INFO] Deleting /Users/jim/Library/CloudStorage/OneDrive-NessDigitalEngineering/rf-dev/maven-modular/module1/target
[INFO]
[INFO] --- maven-resources-plugin:2.6:resources (default-resources) @ module1 ---
[INFO] Using 'UTF-8' encoding to copy filtered resources.
[INFO] skip non existing resourceDirectory /Users/jim/Library/CloudStorage/OneDrive-NessDigitalEngineering/rf-dev/maven-modular/module1/src/main/resources
[INFO]
[INFO] --- maven-compiler-plugin:3.2:compile (default-compile) @ module1 ---
[INFO] Changes detected - recompiling the module!
[INFO] Compiling 1 source file to /Users/jim/Library/CloudStorage/OneDrive-NessDigitalEngineering/rf-dev/maven-modular/module1/target/classes
[INFO]
[INFO] --- maven-resources-plugin:2.6:testResources (default-testResources) @ module1 ---
[INFO] Using 'UTF-8' encoding to copy filtered resources.
[INFO] skip non existing resourceDirectory /Users/jim/Library/CloudStorage/OneDrive-NessDigitalEngineering/rf-dev/maven-modular/module1/src/test/resources
[INFO]
[INFO] --- maven-compiler-plugin:3.2:testCompile (default-testCompile) @ module1 ---
[INFO] Changes detected - recompiling the module!
[INFO] Compiling 1 source file to /Users/jim/Library/CloudStorage/OneDrive-NessDigitalEngineering/rf-dev/maven-modular/module1/target/test-classes
[INFO]
[INFO] --- maven-surefire-plugin:2.12.4:test (default-test) @ module1 ---
[INFO] Surefire report directory: /Users/jim/Library/CloudStorage/OneDrive-NessDigitalEngineering/rf-dev/maven-modular/module1/target/surefire-reports

-------------------------------------------------------
 T E S T S
-------------------------------------------------------
Running io.jitpack.AppTest
Tests run: 1, Failures: 0, Errors: 0, Skipped: 0, Time elapsed: 0.006 sec

Results :

Tests run: 1, Failures: 0, Errors: 0, Skipped: 0

[INFO]
[INFO] --- maven-jar-plugin:2.4:jar (default-jar) @ module1 ---
[INFO] Building jar: /Users/jim/Library/CloudStorage/OneDrive-NessDigitalEngineering/rf-dev/maven-modular/module1/target/module1-1.0.11a078e.master-SNAPSHOT.jar
[INFO]
[INFO] --- maven-install-plugin:2.4:install (default-install) @ module1 ---
[INFO] Installing /Users/jim/Library/CloudStorage/OneDrive-NessDigitalEngineering/rf-dev/maven-modular/module1/target/module1-1.0.11a078e.master-SNAPSHOT.jar to /Users/jim/.m2/repository/io/jitpack/module1/1.0.11a078e.master-SNAPSHOT/module1-1.0.11a078e.master-SNAPSHOT.jar
[INFO] Installing /Users/jim/Library/CloudStorage/OneDrive-NessDigitalEngineering/rf-dev/maven-modular/module1/pom.xml to /Users/jim/.m2/repository/io/jitpack/module1/1.0.11a078e.master-SNAPSHOT/module1-1.0.11a078e.master-SNAPSHOT.pom
[INFO]
[INFO] -------------------------< io.jitpack:module2 >-------------------------
[INFO] Building module2 1.0.11a078e.master-SNAPSHOT                       [3/3]
[INFO] --------------------------------[ jar ]---------------------------------
[INFO]
[INFO] --- maven-clean-plugin:2.5:clean (default-clean) @ module2 ---
[INFO] Deleting /Users/jim/Library/CloudStorage/OneDrive-NessDigitalEngineering/rf-dev/maven-modular/module2/target
[INFO]
[INFO] --- maven-resources-plugin:2.6:resources (default-resources) @ module2 ---
[INFO] Using 'UTF-8' encoding to copy filtered resources.
[INFO] skip non existing resourceDirectory /Users/jim/Library/CloudStorage/OneDrive-NessDigitalEngineering/rf-dev/maven-modular/module2/src/main/resources
[INFO]
[INFO] --- maven-compiler-plugin:3.2:compile (default-compile) @ module2 ---
[INFO] Changes detected - recompiling the module!
[INFO] Compiling 1 source file to /Users/jim/Library/CloudStorage/OneDrive-NessDigitalEngineering/rf-dev/maven-modular/module2/target/classes
[INFO]
[INFO] --- maven-resources-plugin:2.6:testResources (default-testResources) @ module2 ---
[INFO] Using 'UTF-8' encoding to copy filtered resources.
[INFO] skip non existing resourceDirectory /Users/jim/Library/CloudStorage/OneDrive-NessDigitalEngineering/rf-dev/maven-modular/module2/src/test/resources
[INFO]
[INFO] --- maven-compiler-plugin:3.2:testCompile (default-testCompile) @ module2 ---
[INFO] Changes detected - recompiling the module!
[INFO] Compiling 1 source file to /Users/jim/Library/CloudStorage/OneDrive-NessDigitalEngineering/rf-dev/maven-modular/module2/target/test-classes
[INFO]
[INFO] --- maven-surefire-plugin:2.12.4:test (default-test) @ module2 ---
[INFO] Surefire report directory: /Users/jim/Library/CloudStorage/OneDrive-NessDigitalEngineering/rf-dev/maven-modular/module2/target/surefire-reports

-------------------------------------------------------
 T E S T S
-------------------------------------------------------
Running io.jitpack.AppTest
Tests run: 1, Failures: 0, Errors: 0, Skipped: 0, Time elapsed: 0.013 sec

Results :

Tests run: 1, Failures: 0, Errors: 0, Skipped: 0

[INFO]
[INFO] --- maven-jar-plugin:2.4:jar (default-jar) @ module2 ---
[INFO] Building jar: /Users/jim/Library/CloudStorage/OneDrive-NessDigitalEngineering/rf-dev/maven-modular/module2/target/module2-1.0.11a078e.master-SNAPSHOT.jar
[INFO]
[INFO] --- maven-install-plugin:2.4:install (default-install) @ module2 ---
[INFO] Installing /Users/jim/Library/CloudStorage/OneDrive-NessDigitalEngineering/rf-dev/maven-modular/module2/target/module2-1.0.11a078e.master-SNAPSHOT.jar to /Users/jim/.m2/repository/io/jitpack/module2/1.0.11a078e.master-SNAPSHOT/module2-1.0.11a078e.master-SNAPSHOT.jar
[INFO] Installing /Users/jim/Library/CloudStorage/OneDrive-NessDigitalEngineering/rf-dev/maven-modular/module2/pom.xml to /Users/jim/.m2/repository/io/jitpack/module2/1.0.11a078e.master-SNAPSHOT/module2-1.0.11a078e.master-SNAPSHOT.pom
[INFO] ------------------------------------------------------------------------
[INFO] Reactor Summary for example-root 1.0.11a078e.master-SNAPSHOT:
[INFO]
[INFO] example-root ....................................... SUCCESS [  0.208 s]
[INFO] module1 ............................................ SUCCESS [  1.330 s]
[INFO] module2 ............................................ SUCCESS [  0.395 s]
[INFO] ------------------------------------------------------------------------
[INFO] BUILD SUCCESS
[INFO] ------------------------------------------------------------------------
[INFO] Total time:  2.004 s
[INFO] Finished at: 2023-08-06T17:51:05-04:00
[INFO] ------------------------------------------------------------------------
```


## Test 5: Show a local build version is 1.0.sha.local-SNAPSHOT

```
(base) ➜  maven-modular git:(master) ✗ mvn install
[INFO] Scanning for projects...
[INFO] ------------------------------------------------------------------------
[INFO] Reactor Build Order:
[INFO]
[INFO] example-root                                                       [pom]
[INFO] module1                                                            [jar]
[INFO] module2                                                            [jar]
[INFO]
[INFO] ----------------------< io.jitpack:example-root >-----------------------
[INFO] Building example-root 1.0.0-local-SNAPSHOT                         [1/3]
[INFO] --------------------------------[ pom ]---------------------------------
[INFO]
[INFO] --- maven-install-plugin:2.4:install (default-install) @ example-root ---
[INFO] Installing /Users/jim/Library/CloudStorage/OneDrive-NessDigitalEngineering/rf-dev/maven-modular/pom.xml to /Users/jim/.m2/repository/io/jitpack/example-root/1.0.0-local-SNAPSHOT/example-root-1.0.0-local-SNAPSHOT.pom
[INFO]
[INFO] -------------------------< io.jitpack:module1 >-------------------------
[INFO] Building module1 1.0.0-local-SNAPSHOT                              [2/3]
[INFO] --------------------------------[ jar ]---------------------------------
[INFO]
[INFO] --- maven-resources-plugin:2.6:resources (default-resources) @ module1 ---
[INFO] Using 'UTF-8' encoding to copy filtered resources.
[INFO] skip non existing resourceDirectory /Users/jim/Library/CloudStorage/OneDrive-NessDigitalEngineering/rf-dev/maven-modular/module1/src/main/resources
[INFO]
[INFO] --- maven-compiler-plugin:3.2:compile (default-compile) @ module1 ---
[INFO] Changes detected - recompiling the module!
[INFO] Compiling 1 source file to /Users/jim/Library/CloudStorage/OneDrive-NessDigitalEngineering/rf-dev/maven-modular/module1/target/classes
[INFO]
[INFO] --- maven-resources-plugin:2.6:testResources (default-testResources) @ module1 ---
[INFO] Using 'UTF-8' encoding to copy filtered resources.
[INFO] skip non existing resourceDirectory /Users/jim/Library/CloudStorage/OneDrive-NessDigitalEngineering/rf-dev/maven-modular/module1/src/test/resources
[INFO]
[INFO] --- maven-compiler-plugin:3.2:testCompile (default-testCompile) @ module1 ---
[INFO] Changes detected - recompiling the module!
[INFO] Compiling 1 source file to /Users/jim/Library/CloudStorage/OneDrive-NessDigitalEngineering/rf-dev/maven-modular/module1/target/test-classes
[INFO]
[INFO] --- maven-surefire-plugin:2.12.4:test (default-test) @ module1 ---
[INFO] Surefire report directory: /Users/jim/Library/CloudStorage/OneDrive-NessDigitalEngineering/rf-dev/maven-modular/module1/target/surefire-reports

-------------------------------------------------------
 T E S T S
-------------------------------------------------------
Running io.jitpack.AppTest
Tests run: 1, Failures: 0, Errors: 0, Skipped: 0, Time elapsed: 0.006 sec

Results :

Tests run: 1, Failures: 0, Errors: 0, Skipped: 0

[INFO]
[INFO] --- maven-jar-plugin:2.4:jar (default-jar) @ module1 ---
[INFO] Building jar: /Users/jim/Library/CloudStorage/OneDrive-NessDigitalEngineering/rf-dev/maven-modular/module1/target/module1-1.0.0-local-SNAPSHOT.jar
[INFO]
[INFO] --- maven-install-plugin:2.4:install (default-install) @ module1 ---
[INFO] Installing /Users/jim/Library/CloudStorage/OneDrive-NessDigitalEngineering/rf-dev/maven-modular/module1/target/module1-1.0.0-local-SNAPSHOT.jar to /Users/jim/.m2/repository/io/jitpack/module1/1.0.0-local-SNAPSHOT/module1-1.0.0-local-SNAPSHOT.jar
[INFO] Installing /Users/jim/Library/CloudStorage/OneDrive-NessDigitalEngineering/rf-dev/maven-modular/module1/pom.xml to /Users/jim/.m2/repository/io/jitpack/module1/1.0.0-local-SNAPSHOT/module1-1.0.0-local-SNAPSHOT.pom
[INFO]
[INFO] -------------------------< io.jitpack:module2 >-------------------------
[INFO] Building module2 1.0.0-local-SNAPSHOT                              [3/3]
[INFO] --------------------------------[ jar ]---------------------------------
[INFO]
[INFO] --- maven-resources-plugin:2.6:resources (default-resources) @ module2 ---
[INFO] Using 'UTF-8' encoding to copy filtered resources.
[INFO] skip non existing resourceDirectory /Users/jim/Library/CloudStorage/OneDrive-NessDigitalEngineering/rf-dev/maven-modular/module2/src/main/resources
[INFO]
[INFO] --- maven-compiler-plugin:3.2:compile (default-compile) @ module2 ---
[INFO] Changes detected - recompiling the module!
[INFO] Compiling 1 source file to /Users/jim/Library/CloudStorage/OneDrive-NessDigitalEngineering/rf-dev/maven-modular/module2/target/classes
[INFO]
[INFO] --- maven-resources-plugin:2.6:testResources (default-testResources) @ module2 ---
[INFO] Using 'UTF-8' encoding to copy filtered resources.
[INFO] skip non existing resourceDirectory /Users/jim/Library/CloudStorage/OneDrive-NessDigitalEngineering/rf-dev/maven-modular/module2/src/test/resources
[INFO]
[INFO] --- maven-compiler-plugin:3.2:testCompile (default-testCompile) @ module2 ---
[INFO] Changes detected - recompiling the module!
[INFO] Compiling 1 source file to /Users/jim/Library/CloudStorage/OneDrive-NessDigitalEngineering/rf-dev/maven-modular/module2/target/test-classes
[INFO]
[INFO] --- maven-surefire-plugin:2.12.4:test (default-test) @ module2 ---
[INFO] Surefire report directory: /Users/jim/Library/CloudStorage/OneDrive-NessDigitalEngineering/rf-dev/maven-modular/module2/target/surefire-reports

-------------------------------------------------------
 T E S T S
-------------------------------------------------------
Running io.jitpack.AppTest
Tests run: 1, Failures: 0, Errors: 0, Skipped: 0, Time elapsed: 0.017 sec

Results :

Tests run: 1, Failures: 0, Errors: 0, Skipped: 0

[INFO]
[INFO] --- maven-jar-plugin:2.4:jar (default-jar) @ module2 ---
[INFO] Building jar: /Users/jim/Library/CloudStorage/OneDrive-NessDigitalEngineering/rf-dev/maven-modular/module2/target/module2-1.0.0-local-SNAPSHOT.jar
[INFO]
[INFO] --- maven-install-plugin:2.4:install (default-install) @ module2 ---
[INFO] Installing /Users/jim/Library/CloudStorage/OneDrive-NessDigitalEngineering/rf-dev/maven-modular/module2/target/module2-1.0.0-local-SNAPSHOT.jar to /Users/jim/.m2/repository/io/jitpack/module2/1.0.0-local-SNAPSHOT/module2-1.0.0-local-SNAPSHOT.jar
[INFO] Installing /Users/jim/Library/CloudStorage/OneDrive-NessDigitalEngineering/rf-dev/maven-modular/module2/pom.xml to /Users/jim/.m2/repository/io/jitpack/module2/1.0.0-local-SNAPSHOT/module2-1.0.0-local-SNAPSHOT.pom
[INFO] ------------------------------------------------------------------------
[INFO] Reactor Summary for example-root 1.0.0-local-SNAPSHOT:
[INFO]
[INFO] example-root ....................................... SUCCESS [  0.196 s]
[INFO] module1 ............................................ SUCCESS [  1.528 s]
[INFO] module2 ............................................ SUCCESS [  0.534 s]
[INFO] ------------------------------------------------------------------------
[INFO] BUILD SUCCESS
[INFO] ------------------------------------------------------------------------
[INFO] Total time:  2.334 s
[INFO] Finished at: 2023-08-06T17:55:44-04:00
[INFO] ------------------------------------------------------------------------
```
