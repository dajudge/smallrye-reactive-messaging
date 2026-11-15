#!/bin/sh
set -eu
root=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
cd "$root"
: "${MAVEN_REPOSITORY_URL:?missing Forgejo Maven URL}"
: "${MAVEN_USERNAME:?missing Maven username}"
: "${MAVEN_PASSWORD:?missing Maven password}"
case "$MAVEN_REPOSITORY_URL" in
  https://git.dajudge.com/api/packages/friday/maven|https://git.dajudge.com/api/packages/friday/maven/) ;;
  *) echo "Only the homelab Friday Maven repository is supported" >&2; exit 1 ;;
esac
[ -z "$(git status --porcelain)" ] || { echo "Publish requires a clean source commit" >&2; exit 1; }
[ "$(git rev-parse HEAD)" = "$(git rev-parse homelab-mqtt-4.37.0-dajudge.1^{commit})" ] || {
  echo "Publish requires the exact immutable homelab release tag" >&2; exit 1;
}
mvn -B -ntp -pl smallrye-reactive-messaging-mqtt -am package source:jar-no-fork \
  -Dtest=MqttSourceStartupTest -Dsurefire.failIfNoSpecifiedTests=false -Drevapi.skip=true
[ -z "$(git status --porcelain)" ] || { echo "Build changed tracked sources; review before publishing" >&2; exit 1; }
artifact=smallrye-reactive-messaging-mqtt/target/smallrye-reactive-messaging-mqtt-4.37.0
release_path=com/dajudge/friday/patches/smallrye-reactive-messaging-mqtt/4.37.0-dajudge.1/smallrye-reactive-messaging-mqtt-4.37.0-dajudge.1.pom
code=$(curl --silent --show-error --head --user "$MAVEN_USERNAME:$MAVEN_PASSWORD" \
  --output /dev/null --write-out '%{http_code}' "${MAVEN_REPOSITORY_URL%/}/$release_path")
[ "$code" = 404 ] || { echo "Refusing to publish: release existence check returned $code" >&2; exit 1; }
mvn -B -ntp -s homelab/settings.xml org.apache.maven.plugins:maven-deploy-plugin:3.1.4:deploy-file \
  -DrepositoryId=friday -Durl="$MAVEN_REPOSITORY_URL" \
  -Dfile="$artifact.jar" -DpomFile=homelab/pom.xml \
  -Dfiles="$artifact-sources.jar" -Dclassifiers=sources -Dtypes=jar
