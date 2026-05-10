package com.kanitzatech.nextep.auth.model

data class RegisterStudentRequest(
    val name: String,
    val email: String,
    val password: String,
    val cutoff: Double,
    val category: String,
    val preferredCourse: String,
)
