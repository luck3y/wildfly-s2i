#!/bin/bash
SCRIPT_DIR=$(dirname $0)
wildflyPath=$1
nobuild=$2
buildImageDir=$SCRIPT_DIR/../wildfly-builder-image
modulesDir=$SCRIPT_DIR/../wildfly-modules
customModule=$modulesDir/jboss/container/wildfly/base/custom/module.yaml
customModuleCopy=$modulesDir/jboss/container/wildfly/base/custom/module.yaml.orig
overridesFile=$buildImageDir/dev-overrides.yaml
generatorJar=$SCRIPT_DIR/maven-repo-generator/target/maven-repo-generator-1.0.jar

if [ ! -d "$wildflyPath" ]; then
  echo "ERROR: WildFly directory doesn't exist."
  exit 1
fi

if [ -z "$nobuild" ] || [ ! "$nobuild" = "--no-wildfly-build" ]; then
  mvn -f $wildflyPath/pom.xml clean install -DskipTests -Drelease
  if [ $? != 0 ]; then
    echo ERROR: Building WildFly failed.
    exit 1
  fi
fi

offliner=$(find $wildflyPath/dist/target/ -type f -iname "*-all-artifacts-list.txt")

if [ ! -f "$offliner" ]; then
  echo ERROR: Offliner file not found in  $wildflyPath/dist/target/ be sure to build WildFly with -Drelease argument
  exit 1
fi

version="$(basename $offliner -all-artifacts-list.txt)"
version="${version#wildfly-galleon-pack-}"
echo "Building image for Wildfly $version"

if [ ! -f "$generatorJar" ]; then
  mvn -f $SCRIPT_DIR/maven-repo-generator/pom.xml clean package
  if [ $? != 0 ]; then
    echo ERROR: Building repo generator failed.
    exit 1
  fi
fi

echo "Generating zipped maven repository"
java -jar $generatorJar $offliner > /dev/null 2>&1 
if [ $? != 0 ]; then
  echo ERROR: Building maven repo failed.
  exit 1
fi
mv maven-repo.zip /tmp
echo "Zipped maven repository generated in /tmp/maven-repo.zip"

cp "$customModule" "$customModuleCopy"
sed -i "s|###SNAPSHOT_VERSION###|$version|" "$customModule"
echo "Patched $customModule with proper version $version"

pushd $buildImageDir > /dev/null
  cekit build --overrides=$overridesFile ${CONTAINER_BUILD_ENGINE}
  if [ $? != 0 ]; then
    echo ERROR: Building image failed.
  fi
popd > /dev/null

mv $customModuleCopy $customModule
echo "Reverted changes done to $customModule"
rm -rf /tmp/maven-repo.zip
echo "/tmp/maven-repo.zip deleted"
rm -f errors.log
echo "Done!"
