# Homelab MQTT startup backport

This branch starts at upstream tag `4.37.0` (`43967f0a7e32abe763714507142ee09d72672ba3`).
It backports only the consumer-before-topic-subscription fix from
[the existing fork PR](https://github.com/dajudge/smallrye-reactive-messaging/pull/1).
The connection still starts eagerly. Topic subscription waits until the reactive
consumer and buffer are attached, so initial retained messages cannot disappear
before the application is listening.

Three deterministic tests cover immediate 5,000-message replay, broadcast, and a
shared client. They require no broker or Docker. The consumer application must
also pass its JVM, retained-replay, and native integration gates before use.
These focused tests do not replace the upstream container-based connector suite.

`homelab/pom.xml` publishes the built connector as
`com.dajudge.friday.patches:smallrye-reactive-messaging-mqtt:4.37.0-dajudge.2`.
Its runtime dependencies remain the upstream 4.37.0 provider and 3.19.1 Vert.x
Mutiny client; the application's Quarkus platform continues managing those
dependencies. A distinct group avoids an enforced BOM silently selecting the
unpatched connector. No upstream package is overwritten.

After reviewing and committing the source, tag the commit
`homelab-mqtt-4.37.0-dajudge.2`, push the branch and tag to this fork, load the
existing Maven environment without printing it, and run `sh homelab/publish.sh`.
The script tests and builds the module, publishes binary and source artifacts,
and refuses to overwrite an existing release. It contains no credentials.

The modified file is `MqttSource.java`; the original Apache-2.0 license and
this backport notice are explicitly included in binary and source artifacts. This is a
homelab backport, not an upstream release. AI assistance was used to backport,
test, and package this change. No pull request is sent upstream by this workflow.
