#!/bin/sh

TEST_OPTION=$1
if [ "TEST_OPTION" = "help" ]
then
	echo " test options
		BRANCH - Release Branch Snapshopt like jenkins branch build"
		RELEASE_CHECK - do full release process, check for snapshots
		RELEASE_NO_CHECK - bypass snapshot check on build
fi

#get the current pom version and store it into a variable
MVN_VERSION=`mvn help:evaluate -Dexpression=project.properties -q -DforceStdout|egrep revision|cut -f2 -d\>|cut -f1 -d\<`
echo "MVN_VERSION=$MVN_VERSION"

GIT_BRANCH=`git rev-parse --abbrev-ref HEAD`
echo "GIT_BRANCH=$GIT_BRANCH"
HEAD_SHA=`git rev-parse --short HEAD`
echo "HEAD_SHA=$HEAD_SHA"

#increment the second digit of the version and overwrite the variable
RELEASE_VERSION=$(echo ${MVN_VERSION} |  awk -F'.' '{print $1"."$2}' |  sed s/[.]$//)".$HEAD_SHA"
echo "RELEASE_VERSION=$RELEASE_VERSION"

BRANCH_VERSION="${RELEASE_VERSION}.${GIT_BRANCH}-SNAPSHOT"
echo "BRANCH_VERSION=$BRANCH_VERSION"

echo "TEST_OPTION=$TEST_OPTION"
case "$TEST_OPTION" in


	"RELEASE_CHECK" | "RELEASE_NO_CHECK")
		echo "Step 1 Check if releases exit if it does fail."
		EXISTING_TAG=`git tag --list | egrep "$RELEASE_VERSION"`
		if [ "$EXISTING_TAG" != "" ]
		then
			echo "ERROR: Tag $RELEASE_VERSION exists, to rebuild version delete tag the re-run"
			exit 1
		fi

		if [ "$TEST_OPTION" = "RELEASE_CHECK" ]
		then
			#for demo purposes
			cp module1/pom.xml module1/pom.xml.bak
			sed 's/3.8.1/5.11.0-SNAPSHOT/g' module1/pom.xml.bak >module1/pom.xml

			echo "Step 2 check if we have any snapshots, fail build if we do."
			SNAPSHOT_DEPENDENCIES=`find . -name pom.xml -exec egrep -H SNAPSHOT {} \;|egrep -v '<revision>.*\..*\..*-SNAPSHOT</revision>'`
			#echo "SNAPSHOT_DEPENDENCIES=$SNAPSHOT_DEPENDENCIES"
			if [ "$SNAPSHOT_DEPENDENCIES" != "" ]
			then
				echo "ERROR: cannot release with SNAPSHOT dependencies."
				echo "------------------------------------------------"
				echo $SNAPSHOT_DEPENDENCIES
				echo "------------------------------------------------"

				#for demo cleanup
				git co module1/pom.xml

				exit 1
			fi
		else
			echo "INFO: Skipping step 2 - checking SNAPSHOT_DEPENDENCIES"
		fi

		set -e
		echo "Step 3 build branch - fail if the build fails for compile or tests we save pushing artifacts."
		mvn -Drevision="$RELEASE_VERSION" clean install 

		echo "Step 4 if the build passes push to nexus."
		mvn -Drevision="$RELEASE_VERSION" -DskipTests validate
		#mvn -Drevision=$RELEASE_VERSION -DskipTests deploy

		echo "Step 4a Validate maven artifacts."
		mvn -Drevision="$RELEASE_VERSION" -DskipTests -P testRelease install

		echo "Step 5 - Tag the release and push to repo, tag: $RELEASE_VERSION"
		git tag $RELEASE_VERSION
		git push origin $RELEASE_VERSION
	;;

	*) echo "BRANCH release."
		echo "Step 3 build branch - fail if the build fails for compile or tests we save pushing artifacts."
		#mvn -Drevision=$BRANCH_VERSION clean install deploy
		mvn -Drevision=$BRANCH_VERSION clean install 
	;;
esac

