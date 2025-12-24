allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// Legacy build directory configuration for better compatibility
rootProject.buildDir = File(rootProject.projectDir, "../build")

subprojects {
    project.buildDir = File(rootProject.buildDir, project.name)
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.buildDir)
}
