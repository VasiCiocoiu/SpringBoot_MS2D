package com.ruche.ruchesconnectespringboot.service;

import com.google.firebase.database.DatabaseReference;
import com.google.firebase.database.DataSnapshot;
import com.google.firebase.database.ValueEventListener;
import com.google.firebase.database.DatabaseError;
import com.ruche.ruchesconnectespringboot.model.Apiculteurs;
import org.springframework.stereotype.Service;

import java.util.*;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.atomic.AtomicReference;

@Service
public class ApiculteursService {

    private final DatabaseReference apisRef;

    public ApiculteursService(DatabaseReference rootRef) {
        this.apisRef = rootRef.child("apiculteurs");
    }

    public List<Apiculteurs> findAll() {
        try {
            CountDownLatch latch = new CountDownLatch(1);
            AtomicReference<DataSnapshot> holder = new AtomicReference<>();

            apisRef.addListenerForSingleValueEvent(new ValueEventListener() {
                @Override public void onDataChange(DataSnapshot snapshot) {
                    holder.set(snapshot);
                    latch.countDown();
                }
                @Override public void onCancelled(DatabaseError error) {
                    latch.countDown();
                }
            });

            // Attente max 5s
            latch.await(5, TimeUnit.SECONDS);
            DataSnapshot s = holder.get();

            List<Apiculteurs> out = new ArrayList<>();
            if (s != null && s.exists()) {
                for (DataSnapshot c : s.getChildren()) {
                    Apiculteurs a = c.getValue(Apiculteurs.class);
                    if (a != null) { a.setId(c.getKey()); out.add(a); }
                }
            }
            out.sort(Comparator.comparing(
                    Apiculteurs::getNom,
                    Comparator.nullsLast(String::compareToIgnoreCase)
            ));
            return out;
        } catch (Exception e) {
            throw new RuntimeException("Firebase: findAll apiculteurs failed", e);
        }
    }

    public Optional<Apiculteurs> findById(String id) {
        try {
            CountDownLatch latch = new CountDownLatch(1);
            AtomicReference<DataSnapshot> holder = new AtomicReference<>();

            apisRef.child(id).addListenerForSingleValueEvent(new ValueEventListener() {
                @Override public void onDataChange(DataSnapshot snapshot) {
                    holder.set(snapshot);
                    latch.countDown();
                }
                @Override public void onCancelled(DatabaseError error) {
                    latch.countDown();
                }
            });

            latch.await(5, TimeUnit.SECONDS);
            DataSnapshot s = holder.get();

            if (s == null || !s.exists()) return Optional.empty();
            Apiculteurs a = s.getValue(Apiculteurs.class);
            if (a != null) a.setId(s.getKey());
            return Optional.ofNullable(a);
        } catch (Exception e) {
            throw new RuntimeException("Firebase: findById apiculteur failed", e);
        }
    }

    public String upsert(Apiculteurs a) {
        long now = System.currentTimeMillis();
        if (a.getCreatedAt() == null) a.setCreatedAt(now);
        a.setModifiedAt(now);

        String id = a.getId();
        if (id == null || id.isBlank()) {
            id = apisRef.push().getKey();
            a.setId(id);
        }
        apisRef.child(id).setValueAsync(a);
        return id;
    }

    public void delete(String id) {
        apisRef.child(id).removeValueAsync();
    }
}
