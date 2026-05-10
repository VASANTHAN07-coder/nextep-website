package com.kanitzatech.nextep.auth.model

import com.google.firebase.firestore.DocumentSnapshot

data class StudentProfile(
    val uid: String,
    val name: String,
    val email: String,
    val cutoff: Double,
    val category: String,
    val preferredCourse: String,
) {
    fun toFirestoreMap(): Map<String, Any> {
        return mapOf(
            FIELD_UID to uid,
            FIELD_NAME to name,
            FIELD_EMAIL to email,
            FIELD_CUTOFF to cutoff,
            FIELD_CATEGORY to category,
            FIELD_PREFERRED_COURSE to preferredCourse,
        )
    }

    companion object {
        const val COLLECTION_STUDENTS = "students"
        const val FIELD_UID = "uid"
        const val FIELD_NAME = "name"
        const val FIELD_EMAIL = "email"
        const val FIELD_CUTOFF = "cutoff"
        const val FIELD_CATEGORY = "category"
        const val FIELD_PREFERRED_COURSE = "preferred_course"

        fun fromDocument(document: DocumentSnapshot): StudentProfile {
            return StudentProfile(
                uid = document.getString(FIELD_UID).orEmpty(),
                name = document.getString(FIELD_NAME).orEmpty(),
                email = document.getString(FIELD_EMAIL).orEmpty(),
                cutoff = document.getDouble(FIELD_CUTOFF) ?: 0.0,
                category = document.getString(FIELD_CATEGORY).orEmpty(),
                preferredCourse = document.getString(FIELD_PREFERRED_COURSE).orEmpty(),
            )
        }
    }
}
