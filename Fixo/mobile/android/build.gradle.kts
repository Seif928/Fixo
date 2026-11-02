buildscript {
    repositories { google(); mavenCentral() }
    // Firebase Auth 25 uses Kotlin 2.4 metadata; Android's compatibility
    // matrix requires R8 9.1.29 or newer when keeping AGP 8.11.
    dependencies { classpath("com.android.tools:r8:9.1.31") }
}

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

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
