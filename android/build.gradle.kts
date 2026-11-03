allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

subprojects {
    val configureAndroid: (Project) -> Unit = { p ->
        val androidExt = p.extensions.findByName("android")
        if (androidExt != null) {
            val method = androidExt.javaClass.methods.firstOrNull {
                it.name == "compileSdkVersion" && it.parameterTypes.size == 1 && it.parameterTypes[0] == java.lang.Integer.TYPE
            } ?: androidExt.javaClass.methods.firstOrNull {
                it.name == "setCompileSdkVersion" && it.parameterTypes.size == 1 && it.parameterTypes[0] == java.lang.Integer.TYPE
            }
            method?.invoke(androidExt, 36)
        }
    }

    if (project.state.executed) {
        configureAndroid(project)
    } else {
        project.afterEvaluate { configureAndroid(project) }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
