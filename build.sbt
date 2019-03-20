enablePlugins(ParadoxPlugin)

name := "lightbend-openshift-guide"

val akkaManagementVersion = "1.0.0"
val lagomAkkaDiscoveryVersion = "1.0.0"
val lagomVersion = "1.4.11"

paradoxProperties ++= Map(
  "akka.management.version" -> akkaManagementVersion,
  "akka.version" -> "2.5.20",
  "sbt.native.packager.version" -> "1.3.17",
  "sbt.dynver.version" -> "3.3.0",
  "adoptopenjdk.docker.image.version" -> "jdk8u202-b08",
  "strimzi.version" -> "0.9.0",
  "lagom.akka.discovery.version" -> lagomAkkaDiscoveryVersion,
  "lagom.version" -> lagomVersion
)

scalaVersion := "2.12.8"

libraryDependencies ++= Seq(
  "com.lightbend.akka.management" %% "akka-management-cluster-bootstrap" % akkaManagementVersion,
  "com.lightbend.akka.discovery" %% "akka-discovery-kubernetes-api" % akkaManagementVersion,
  "com.lightbend.lagom" %% "lagom-scaladsl-akka-discovery-service-locator" % lagomAkkaDiscoveryVersion,
  "com.lightbend.lagom" %% "lagom-scaladsl-server" % lagomVersion,
  "com.lightbend.lagom" %% "lagom-scaladsl-dev-mode" % lagomVersion,
  "com.lightbend.lagom" %% "lagom-javadsl-server" % lagomVersion
)

Compile / unmanagedSourceDirectories ++= ((Compile / paradox / sourceDirectory).value ** "code").get

// Exclude the includes directory from being compiled directly
(Compile / paradoxMarkdownToHtml / excludeFilter) := (Compile / paradoxMarkdownToHtml / excludeFilter).value ||
  ParadoxPlugin.InDirectoryFilter((Compile / paradox / sourceDirectory).value / "includes")

paradoxTheme := Some(builtinParadoxTheme("generic"))
paradoxNavigationDepth := 3
