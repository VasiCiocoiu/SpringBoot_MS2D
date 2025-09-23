// src/main/java/com/ruche/ruchesconnectespringboot/firebase/FirebaseDbUtils.java
package com.ruche.ruchesconnectespringboot.firebase;

import com.google.firebase.database.*;
import java.util.concurrent.CompletableFuture;

public final class FirebaseDbUtils {

    private FirebaseDbUtils() {}

    /** Lecture "une fois" -> CompletableFuture<DataSnapshot> */
    public static CompletableFuture<DataSnapshot> getOnce(DatabaseReference ref) {
        CompletableFuture<DataSnapshot> fut = new CompletableFuture<>();
        ref.addListenerForSingleValueEvent(new ValueEventListener() {
            @Override public void onDataChange(DataSnapshot snapshot) {
                fut.complete(snapshot);
            }
            @Override public void onCancelled(DatabaseError error) {
                fut.completeExceptionally(error.toException());
            }
        });
        return fut;
    }

    /** Ecriture setValue -> CompletableFuture<Void> */
    public static CompletableFuture<Void> setValue(DatabaseReference ref, Object value) {
        CompletableFuture<Void> fut = new CompletableFuture<>();
        ref.setValue(value, (error, ignoredRef) -> {
            if (error != null) fut.completeExceptionally(error.toException());
            else fut.complete(null);
        });
        return fut;
    }

    /** Optionnel : updateChildren (merge partiel) */
    public static CompletableFuture<Void> updateChildren(DatabaseReference ref, java.util.Map<String, Object> updates) {
        CompletableFuture<Void> fut = new CompletableFuture<>();
        ref.updateChildren(updates, (error, ignoredRef) -> {
            if (error != null) fut.completeExceptionally(error.toException());
            else fut.complete(null);
        });
        return fut;
    }
}
