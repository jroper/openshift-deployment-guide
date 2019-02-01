/*
 * Copyright © 2018 Lightbend, Inc. All rights reserved.
 * No information contained herein may be reproduced or transmitted in any form
 * or by any means without the express written permission of Typesafe, Inc.
 */

import de.heikoseeberger.sbtheader.HeaderPlugin
import com.lightbend.paradox.sbt.ParadoxPlugin
import sbt._
import sbt.Keys._

object Build extends AutoPlugin {

  import ParadoxPlugin.autoImport._
  import HeaderPlugin.autoImport._

  override def requires =
    plugins.JvmPlugin && HeaderPlugin

  override def trigger =
    allRequirements

  override def projectSettings =
    List(
      // Core settings
      organization := "com.lightbend",
      version := sys.env.getOrElse("PACKAGE_VERSION", "0.1.0"),
      licenses := Seq("Apache 2" -> url("http://www.apache.org/licenses/LICENSE-2.0")),
      scalaVersion := "2.11.8",
      scalacOptions ++= List(
        "-unchecked",
        "-deprecation",
        "-feature",
        "-language:_",
        "-target:jvm-1.8",
        "-encoding", "UTF-8",
        "-Xexperimental"
      ),
      // Header settings
      headerLicense := Some(HeaderLicense.Custom(
        """|Copyright © 2018 Lightbend, Inc. All rights reserved.
           |No information contained herein may be reproduced or transmitted in any form
           |or by any means without the express written permission of Lightbend, Inc.
           |""".stripMargin
      )),
      headerMappings := headerMappings.value ++ Map(
        HeaderFileType("conf") -> HeaderCommentStyle.hashLineComment
      )
    )
}
