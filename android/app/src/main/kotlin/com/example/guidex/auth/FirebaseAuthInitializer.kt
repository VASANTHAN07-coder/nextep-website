package com.kanitzatech.nextep.auth

import android.content.Context
import com.google.firebase.FirebaseApp
import com.google.firebase.auth.FirebaseAuth
import com.google.firebase.firestore.FirebaseFirestore

object FirebaseAuthInitializer {
    val firebaseAuth: FirebaseAuth by lazy { FirebaseAuth.getInstance() }
    val firestore: FirebaseFirestore by lazy { FirebaseFirestore.getInstance() }

    fun createAuthService(context: Context): AuthService {
        FirebaseApp.initializeApp(context)
        return FirebaseAuthService(
            context = context,
            auth = firebaseAuth,
            firestore = firestore,
        )
    }
}
