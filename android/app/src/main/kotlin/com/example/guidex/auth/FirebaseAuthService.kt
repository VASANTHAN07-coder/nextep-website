package com.kanitzatech.nextep.auth

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.net.Uri
import com.kanitzatech.nextep.R
import com.kanitzatech.nextep.auth.model.RegisterStudentRequest
import com.kanitzatech.nextep.auth.model.StudentProfile
import com.google.android.gms.auth.api.signin.GoogleSignIn
import com.google.android.gms.auth.api.signin.GoogleSignInClient
import com.google.android.gms.auth.api.signin.GoogleSignInOptions
import com.google.android.gms.common.api.ApiException
import com.google.firebase.FirebaseNetworkException
import com.google.firebase.auth.FirebaseAuth
import com.google.firebase.auth.FirebaseAuthException
import com.google.firebase.auth.FirebaseAuthInvalidCredentialsException
import com.google.firebase.auth.FirebaseAuthInvalidUserException
import com.google.firebase.auth.FirebaseAuthUserCollisionException
import com.google.firebase.auth.GoogleAuthProvider
import com.google.firebase.auth.OAuthProvider
import com.google.firebase.firestore.FirebaseFirestore
import kotlinx.coroutines.tasks.await
import java.io.IOException

class FirebaseAuthService(
    context: Context,
    private val auth: FirebaseAuth = FirebaseAuth.getInstance(),
    private val firestore: FirebaseFirestore = FirebaseFirestore.getInstance(),
) : AuthService {

    private val appContext = context.applicationContext
    private val studentsCollection = firestore.collection(StudentProfile.COLLECTION_STUDENTS)

    private val googleSignInClient: GoogleSignInClient by lazy {
        GoogleSignIn.getClient(appContext, buildGoogleSignInOptions())
    }

    override fun isLoggedIn(): Boolean = auth.currentUser != null

    override fun getCurrentUid(): String? = auth.currentUser?.uid

    override suspend fun registerWithEmail(request: RegisterStudentRequest): AuthResult<StudentProfile> {
        validateRegistrationInputs(request)?.let { return AuthResult.Error(it) }

        return try {
            val authResult = auth
                .createUserWithEmailAndPassword(request.email.trim(), request.password)
                .await()

            val user = authResult.user
                ?: return AuthResult.Error(AuthFailure.Unknown("Registration failed. Please try again."))

            val profile = StudentProfile(
                uid = user.uid,
                name = request.name.trim(),
                email = request.email.trim(),
                cutoff = request.cutoff,
                category = request.category.trim(),
                preferredCourse = request.preferredCourse.trim(),
            )

            studentsCollection.document(user.uid).set(profile.toFirestoreMap()).await()
            AuthResult.Success(profile)
        } catch (e: Exception) {
            AuthResult.Error(mapException(e))
        }
    }

    override suspend fun loginWithEmail(email: String, password: String): AuthResult<StudentProfile> {
        validateLoginInputs(email, password)?.let { return AuthResult.Error(it) }

        return try {
            val authResult = auth
                .signInWithEmailAndPassword(email.trim(), password)
                .await()

            val user = authResult.user
                ?: return AuthResult.Error(AuthFailure.Unknown("Login failed. Please try again."))

            fetchStudentProfile(user.uid, user.email, user.displayName)
        } catch (e: Exception) {
            AuthResult.Error(mapException(e))
        }
    }

    override suspend fun restoreSession(): AuthResult<StudentProfile?> {
        val user = auth.currentUser ?: return AuthResult.Success(null)
        return when (val result = fetchStudentProfile(user.uid, user.email, user.displayName)) {
            is AuthResult.Success -> AuthResult.Success(result.data)
            is AuthResult.Error -> result
        }
    }

    override fun googleSignInIntent(): Intent = googleSignInClient.signInIntent

    override suspend fun signInWithGoogleResult(data: Intent?): AuthResult<StudentProfile> {
        if (data == null) {
            return AuthResult.Error(AuthFailure.GoogleSignIn("Google sign-in was canceled."))
        }

        return try {
            val account = GoogleSignIn.getSignedInAccountFromIntent(data).await()
            val idToken = account.idToken
                ?: return AuthResult.Error(AuthFailure.GoogleSignIn("Missing Google ID token."))

            val firebaseCredential = GoogleAuthProvider.getCredential(idToken, null)
            val authResult = auth.signInWithCredential(firebaseCredential).await()
            val user = authResult.user
                ?: return AuthResult.Error(AuthFailure.GoogleSignIn("Google sign-in failed."))

            upsertSocialProfile(user.uid, user.email, user.displayName)
        } catch (e: ApiException) {
            AuthResult.Error(AuthFailure.GoogleSignIn("Google sign-in failed (${e.statusCode})."))
        } catch (e: Exception) {
            AuthResult.Error(mapException(e))
        }
    }

    override suspend fun signInWithApple(activity: Activity): AuthResult<StudentProfile> {
        if (!isAppleOAuthSupported()) {
            return AuthResult.Error(
                AuthFailure.AppleSignIn("Apple sign-in is not supported on this device."),
            )
        }

        return try {
            val providerBuilder = OAuthProvider.newBuilder("apple.com").apply {
                scopes = listOf("email", "name")
            }

            val authResult = auth.pendingAuthResult?.await()
                ?: auth.startActivityForSignInWithProvider(activity, providerBuilder.build()).await()

            val user = authResult.user
                ?: return AuthResult.Error(AuthFailure.AppleSignIn("Apple sign-in failed."))

            upsertSocialProfile(user.uid, user.email, user.displayName)
        } catch (e: Exception) {
            AuthResult.Error(mapException(e))
        }
    }

    override suspend fun logout() {
        auth.signOut()
        try {
            googleSignInClient.signOut().await()
        } catch (_: Exception) {
            // No-op: Firebase session is already cleared.
        }
    }

    private suspend fun upsertSocialProfile(
        uid: String,
        email: String?,
        displayName: String?,
    ): AuthResult<StudentProfile> {
        return try {
            val existing = studentsCollection.document(uid).get().await()
            if (existing.exists()) {
                AuthResult.Success(StudentProfile.fromDocument(existing))
            } else {
                val profile = StudentProfile(
                    uid = uid,
                    name = displayName.orEmpty(),
                    email = email.orEmpty(),
                    cutoff = 0.0,
                    category = "",
                    preferredCourse = "",
                )
                studentsCollection.document(uid).set(profile.toFirestoreMap()).await()
                AuthResult.Success(profile)
            }
        } catch (e: Exception) {
            AuthResult.Error(mapException(e))
        }
    }

    private suspend fun fetchStudentProfile(
        uid: String,
        fallbackEmail: String?,
        fallbackName: String?,
    ): AuthResult<StudentProfile> {
        return try {
            val document = studentsCollection.document(uid).get().await()
            if (document.exists()) {
                AuthResult.Success(StudentProfile.fromDocument(document))
            } else {
                val profile = StudentProfile(
                    uid = uid,
                    name = fallbackName.orEmpty(),
                    email = fallbackEmail.orEmpty(),
                    cutoff = 0.0,
                    category = "",
                    preferredCourse = "",
                )
                studentsCollection.document(uid).set(profile.toFirestoreMap()).await()
                AuthResult.Success(profile)
            }
        } catch (e: Exception) {
            AuthResult.Error(AuthFailure.Firestore("Failed to load profile. Please retry."))
        }
    }

    private fun validateRegistrationInputs(request: RegisterStudentRequest): AuthFailure? {
        if (request.name.isBlank()) return AuthFailure.Validation("Name is required.")
        if (!isValidEmail(request.email)) return AuthFailure.Validation("Enter a valid email address.")
        if (!isValidPassword(request.password)) {
            return AuthFailure.Validation("Password must be at least 8 characters.")
        }
        if (request.cutoff < 0.0) return AuthFailure.Validation("Cutoff cannot be negative.")
        if (request.category.isBlank()) return AuthFailure.Validation("Category is required.")
        if (request.preferredCourse.isBlank()) {
            return AuthFailure.Validation("Preferred course is required.")
        }
        return null
    }

    private fun validateLoginInputs(email: String, password: String): AuthFailure? {
        if (!isValidEmail(email)) return AuthFailure.Validation("Enter a valid email address.")
        if (password.isBlank()) return AuthFailure.Validation("Password is required.")
        return null
    }

    private fun buildGoogleSignInOptions(): GoogleSignInOptions {
        val webClientId = appContext.getString(R.string.default_web_client_id)
        return GoogleSignInOptions.Builder(GoogleSignInOptions.DEFAULT_SIGN_IN)
            .requestIdToken(webClientId)
            .requestEmail()
            .build()
    }

    private fun isAppleOAuthSupported(): Boolean {
        val browserIntent = Intent(Intent.ACTION_VIEW, Uri.parse("https://appleid.apple.com"))
        return browserIntent.resolveActivity(appContext.packageManager) != null
    }

    private fun mapException(throwable: Throwable): AuthFailure {
        return when (throwable) {
            is FirebaseAuthInvalidUserException -> AuthFailure.UserNotFound("User account not found.")
            is FirebaseAuthInvalidCredentialsException -> {
                AuthFailure.InvalidCredentials("Wrong email or password.")
            }
            is FirebaseAuthUserCollisionException -> {
                AuthFailure.UserCollision("An account already exists with this email.")
            }
            is FirebaseNetworkException,
            is IOException,
            -> AuthFailure.Network("Network error. Check your connection and retry.")
            is FirebaseAuthException -> AuthFailure.InvalidCredentials(throwable.localizedMessage.orEmpty())
            else -> AuthFailure.Unknown(throwable.localizedMessage ?: "Unexpected error.")
        }
    }

    private fun isValidEmail(email: String): Boolean {
        return android.util.Patterns.EMAIL_ADDRESS.matcher(email.trim()).matches()
    }

    private fun isValidPassword(password: String): Boolean = password.length >= 8
}
