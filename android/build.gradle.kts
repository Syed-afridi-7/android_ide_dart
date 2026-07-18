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
    fun patchNamespace() {
        if (project.plugins.hasPlugin("com.android.library")) {
            val android = project.extensions.getByName("android") as com.android.build.gradle.LibraryExtension
            android.compileSdk = 36
            if (android.namespace.isNullOrEmpty()) {
                val manifest = file("${project.projectDir}/src/main/AndroidManifest.xml")
                if (manifest.exists()) {
                    val pkg = javax.xml.parsers.DocumentBuilderFactory.newInstance()
                        .newDocumentBuilder()
                        .parse(manifest)
                        .documentElement
                        .getAttribute("package")
                    if (pkg.isNotEmpty()) {
                        android.namespace = pkg
                    }
                }
            }
        }
    }
    if (project.state.executed) {
        patchNamespace()
    } else {
        project.afterEvaluate {
            patchNamespace()
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
