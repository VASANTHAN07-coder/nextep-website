package com.kanitzatech.nextep.auth

import com.kanitzatech.nextep.auth.model.StudentProfile

data class AuthUiState(
    val isLoading: Boolean = false,
    val isLoggedIn: Boolean = false,
    val profile: StudentProfile? = null,
    val error: AuthFailure? = null,
)
