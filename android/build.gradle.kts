// android/build.gradle.kts
// مخزن‌ها را اینجا تعریف نکن! (settings.gradle.kts مسئول مخزن‌هاست)

import org.gradle.api.file.Directory
import org.gradle.api.tasks.Delete

// جابه‌جایی فولدر بیلد به ../../build
val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.set(newBuildDir)

subprojects {
    // هر ماژول داخل ../../build/<moduleName> بیلد شود
    layout.buildDirectory.set(newBuildDir.dir(name))
    // اطمینان از ارزیابی app قبل از سایر ماژول‌ها (در صورت نیاز)
    evaluationDependsOn(":app")
}

// تسک clean
tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
