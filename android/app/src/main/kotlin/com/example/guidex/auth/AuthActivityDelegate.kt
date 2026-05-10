package com.kanitzatech.nextep.auth

import androidx.activity.ComponentActivity
import androidx.activity.result.ActivityResultLauncher
import androidx.activity.result.contract.ActivityResultContracts

class AuthActivityDelegate(
    private val activity: ComponentActivity,
    private val authViewModel: AuthViewModel,
) {
    private val googleSignInLauncher: ActivityResultLauncher<android.content.Intent> =
        activity.registerForActivityResult(ActivityResultContracts.StartActivityForResult()) { result ->
            authViewModel.onGoogleSignInResult(result.data)
        }

    fun startGoogleSignIn() {
        googleSignInLauncher.launch(authViewModel.googleSignInIntent())
    }

    fun startAppleSignIn() {
        authViewModel.signInWithApple(activity)
    }
}
