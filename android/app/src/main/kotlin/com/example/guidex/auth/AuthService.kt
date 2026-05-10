package com.kanitzatech.nextep.auth

import android.app.Activity
import android.content.Intent
import com.kanitzatech.nextep.auth.model.RegisterStudentRequest
import com.kanitzatech.nextep.auth.model.StudentProfile

interface AuthService {
    fun isLoggedIn(): Boolean
    fun getCurrentUid(): String?

    suspend fun registerWithEmail(request: RegisterStudentRequest): AuthResult<StudentProfile>
    suspend fun loginWithEmail(email: String, password: String): AuthResult<StudentProfile>
    suspend fun restoreSession(): AuthResult<StudentProfile?>

    fun googleSignInIntent(): Intent
    suspend fun signInWithGoogleResult(data: Intent?): AuthResult<StudentProfile>

    suspend fun signInWithApple(activity: Activity): AuthResult<StudentProfile>

    suspend fun logout()
}
