allprojects {
    repositories {
        google()
        mavenCentral()
    }
    configurations.all {
        resolutionStrategy {
            force("androidx.browser:browser:1.8.0")
            force("androidx.core:core:1.15.0")
            force("androidx.core:core-ktx:1.15.0")
        }
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}

subprojects {
    configurations.all {
        resolutionStrategy {
            force("androidx.browser:browser:1.8.0")
            force("androidx.core:core:1.15.0")
            force("androidx.core:core-ktx:1.15.0")
        }
    }
}
subprojects {
    val configureAndroid = { proj: Project ->
        val android = proj.extensions.findByName("android")
        if (android != null) {
            // Fix missing namespace for older libraries like isar_flutter_libs (required by AGP 8.0+)
            try {
                val getNamespace = android.javaClass.getMethod("getNamespace")
                val currentNs = getNamespace.invoke(android)
                if (currentNs == null || (currentNs is String && currentNs.isEmpty())) {
                    val fallbackNs = when (proj.name) {
                        "isar_flutter_libs" -> "dev.isar.isar_flutter_libs"
                        else -> {
                            val manifestFile = proj.file("src/main/AndroidManifest.xml")
                            var resolved: String? = null
                            if (manifestFile.exists()) {
                                val match = Regex("""package\s*=\s*["']([^"']+)["']""").find(manifestFile.readText())
                                resolved = match?.groups?.get(1)?.value
                            }
                            if (resolved.isNullOrEmpty()) {
                                val grp = proj.group.toString()
                                if (grp.isNotEmpty() && grp != "unspecified") grp else "com.example.${proj.name.replace('-', '_')}"
                            } else {
                                resolved
                            }
                        }
                    }
                    val setNamespace = android.javaClass.getMethod("setNamespace", String::class.java)
                    setNamespace.invoke(android, fallbackNs)
                }
            } catch (e: Exception) {
                // ignore
            }

            try {
                val method = android.javaClass.getMethod("compileSdkVersion", Int::class.javaPrimitiveType)
                method.invoke(android, 35)
            } catch (e: Exception) {
                try {
                    val method = android.javaClass.getMethod("setCompileSdkVersion", Int::class.javaPrimitiveType)
                    method.invoke(android, 35)
                } catch (e2: Exception) {
                    // ignore
                }
            }
        }
    }

    plugins.withId("com.android.library") {
        configureAndroid(this@subprojects)
    }

    afterEvaluate {
        configureAndroid(this)
    }

    tasks.configureEach {
        if (name.contains("verifyReleaseResources", ignoreCase = true)) {
            enabled = false
        }
    }
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}

