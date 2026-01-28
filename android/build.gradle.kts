import org.gradle.api.Action
import org.gradle.api.Project

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
    fun Project.applyNamespaceFallback() {
        val androidExt = extensions.findByName("android") ?: return

        val compileSdk = 35
        val setCompileSdk =
            androidExt.javaClass.methods.firstOrNull {
                it.name == "setCompileSdk" &&
                    it.parameterTypes.size == 1 &&
                    (it.parameterTypes[0] == Int::class.javaPrimitiveType || it.parameterTypes[0] == Int::class.java)
            }
        val setCompileSdkVersion =
            androidExt.javaClass.methods.firstOrNull {
                it.name == "setCompileSdkVersion" &&
                    it.parameterTypes.size == 1 &&
                    (it.parameterTypes[0] == Int::class.javaPrimitiveType || it.parameterTypes[0] == Int::class.java)
            }
        val compileSdkVersion =
            androidExt.javaClass.methods.firstOrNull {
                it.name == "compileSdkVersion" &&
                    it.parameterTypes.size == 1 &&
                    (it.parameterTypes[0] == Int::class.javaPrimitiveType || it.parameterTypes[0] == Int::class.java)
            }
        try {
            when {
                setCompileSdk != null -> setCompileSdk.invoke(androidExt, compileSdk)
                setCompileSdkVersion != null -> setCompileSdkVersion.invoke(androidExt, compileSdk)
                compileSdkVersion != null -> compileSdkVersion.invoke(androidExt, compileSdk)
            }
        } catch (_: Throwable) {
        }

        val getNamespace =
            androidExt.javaClass.methods.firstOrNull { it.name == "getNamespace" && it.parameterTypes.isEmpty() }
        val setNamespace =
            androidExt.javaClass.methods.firstOrNull {
                it.name == "setNamespace" && it.parameterTypes.size == 1 && it.parameterTypes[0] == String::class.java
            }

        if (setNamespace != null) {
            val current = getNamespace?.invoke(androidExt) as? String
            if (current.isNullOrBlank()) {
                val candidate = group.toString()
                val namespace =
                    if (candidate.contains('.') && candidate.none { it.isWhitespace() }) candidate else "com.example.$name"
                try {
                    setNamespace.invoke(androidExt, namespace)
                } catch (_: Throwable) {
                }
            }
        }
    }

    afterEvaluate(
        Action<Project> {
            applyNamespaceFallback()
        },
    )
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
