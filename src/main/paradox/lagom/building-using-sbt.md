---
sbt.prompt: [shopping-cart] $
sbt.sub.project: shopping-cart-impl
---
# Building using sbt

sbt uses a plugin called [sbt-native-packager](https://www.scala-sbt.org/sbt-native-packager/) to allow conveniently packaging Java and Scala applications built using sbt as Docker images.

## Setup

This plugin is automatically enabled and configured by the Lagom sbt plugin, so no setup is needed to use it.

@@include[building-using-sbt.md](../includes/building-using-sbt.md) { #no-setup }
