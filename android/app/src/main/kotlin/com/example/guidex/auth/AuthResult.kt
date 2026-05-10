package com.kanitzatech.nextep.auth

sealed class AuthResult<out T> {
    data class Success<T>(val data: T) : AuthResult<T>()
    data class Error(val failure: AuthFailure) : AuthResult<Nothing>()
}
