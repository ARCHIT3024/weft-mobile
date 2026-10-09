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
// geocoding_android 3.3.1 hard-codes `compileSdk 33`, but the AndroidX
// libraries it pulls in (fragment 1.7, exifinterface 1.4, ...) require
// compiling against API 34+, so :geocoding_android:checkDebugAarMetadata
// fails. Raise compileSdk for any Android LIBRARY subproject still below 34 to
// Flutter's default (36). compileSdk is compile-time only: it does not change
// any plugin's minSdk/targetSdk or runtime behaviour. Must be registered
// before `evaluationDependsOn` below evaluates the projects. Remove once the
// geocoding plugin is upgraded (geocoding ^4).
subprojects {
    afterEvaluate {
        extensions.findByType(com.android.build.api.dsl.LibraryExtension::class.java)?.let { android ->
            if ((android.compileSdk ?: 0) < 34) {
                android.compileSdk = 36
            }
        }
    }
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
