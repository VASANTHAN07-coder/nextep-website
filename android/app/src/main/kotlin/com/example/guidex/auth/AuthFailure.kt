package com.kanitzatech.nextep.auth

sealed class AuthFailure(open val message: String) {
    data class Validation(override val message: String) : AuthFailure(message)
    data class InvalidCredentials(override val message: String) : AuthFailure(message)
    data class UserNotFound(override val message: String) : AuthFailure(message)
    data class UserCollision(override val message: String) : AuthFailure(message)
    data class Network(override val message: String) : AuthFailure(message)
    data class GoogleSignIn(override val message: String) : AuthFailure(message)
    data class AppleSignIn(override val message: String) : AuthFailure(message)
    data class Firestore(override val message: String) : AuthFailure(message)
    data class Unknown(override val message: String) : AuthFailure(message)
}
