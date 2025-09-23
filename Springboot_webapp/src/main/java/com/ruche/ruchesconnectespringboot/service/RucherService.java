// src/main/java/com/ruche/ruchesconnectespringboot/service/RucherService.java
package com.ruche.ruchesconnectespringboot.service;

import com.google.firebase.database.DataSnapshot;
import com.google.firebase.database.DatabaseReference;
import com.ruche.ruchesconnectespringboot.firebase.FirebaseDbUtils;
import com.ruche.ruchesconnectespringboot.model.Ruchers;
import com.ruche.ruchesconnectespringboot.model.Ruches;
import org.springframework.stereotype.Service;

import java.util.*;
import java.util.concurrent.*;
import java.util.regex.Pattern;


@Service
public class RucherService {

    private final DatabaseReference root;

    public RucherService(DatabaseReference root) {
        this.root = root;
    }

    public Ruches findRucheBlocking(String uid, String rucherId, String rucheId) {
        return findRuche(uid, rucherId, rucheId).orElse(null);
    }

    public CompletableFuture<Void> upsertRucheAsync(String uid, String rucherId, Ruches ruche) {
        if (ruche == null) return CompletableFuture.completedFuture(null);
        String rucheId = (ruche.getId() == null || ruche.getId().isBlank())
                ? UUID.randomUUID().toString()
                : ruche.getId();
        ruche.setId(rucheId);
        if (ruche.getCreatedAt() == null) ruche.setCreatedAt(System.currentTimeMillis());
        ruche.setModifiedAt(System.currentTimeMillis());

        if (ruche.getConstants() == null) {
            Ruches.RucheConstants c = new Ruches.RucheConstants();
            c.setTemperature(30);
            c.setHumidity(80);
            c.setInterval(60000L);
            c.setNotify(Boolean.TRUE);
            ruche.setConstants(c);
        }

        DatabaseReference ref = root.child(uid).child(rucherId).child(rucheId);
        return FirebaseDbUtils.setValue(ref, ruche); // -> CompletableFuture<Void>
    }


    private static final Pattern FORBIDDEN = Pattern.compile("[.#$\\[\\]/]");

    public static boolean isValidKey(String key){
        return key != null && !FORBIDDEN.matcher(key).find();
    }



    public CompletableFuture<Void> toggleNotificationsAsync(String uid, String rucherId, String rucheId, boolean enabled) {
        DatabaseReference ref = root.child(uid).child(rucherId).child(rucheId).child("notificationsEnabled");
        return FirebaseDbUtils.setValue(ref, enabled);
    }

    public void toggleNotifications(String uid, String rucherId, String rucheId, boolean enabled) {
        try {
            toggleNotificationsAsync(uid, rucherId, rucheId, enabled).get(5, TimeUnit.SECONDS);
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
        } catch (ExecutionException | TimeoutException ignored) { }
    }


    public void upsertRuche(String uid, String rucherId, Ruches ruche) {
        try {
            upsertRucheAsync(uid, rucherId, ruche).get(5, TimeUnit.SECONDS);
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
        } catch (ExecutionException | TimeoutException ignored) { }
    }

    private static <T> T join(CompletableFuture<T> f) {
        try {
            return f.get(8, TimeUnit.SECONDS);
        } catch (Exception e) {
            throw new RuntimeException(e);
        }
    }

    // RucherService.java

    public CompletableFuture<Void> setRucheConstantsNotifyAsync(
            String uid, String rucherId, String rucheId, boolean notify) {

        DatabaseReference ref = root.child(uid)
                .child(rucherId)
                .child(rucheId)
                .child("constants")
                .child("notify");

        return FirebaseDbUtils.setValue(ref, notify);
    }

    public void setRucheConstantsNotify(String uid, String rucherId, String rucheId, boolean notify) {
        try {
            setRucheConstantsNotifyAsync(uid, rucherId, rucheId, notify).get(5, TimeUnit.SECONDS);
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
        } catch (ExecutionException | TimeoutException ignored) { }
    }

    /* (Optionnel) Mise à jour groupée des constantes */
    public CompletableFuture<Void> updateRucheConstantsAsync(
            String uid, String rucherId, String rucheId,
            Integer temperature, Integer humidity, Long interval, Boolean notify) {

        Map<String,Object> patch = new HashMap<>();
        if (temperature != null) patch.put("temperature", temperature);
        if (humidity != null)    patch.put("humidity", humidity);
        if (interval != null)    patch.put("interval", interval);
        if (notify != null)      patch.put("notify", notify);

        DatabaseReference ref = root.child(uid)
                .child(rucherId)
                .child(rucheId)
                .child("constants");

        return FirebaseDbUtils.updateChildren(ref, patch); // wrappe ref.updateChildren(...)
    }

    public void updateRucheConstants(String uid, String rucherId, String rucheId,
                                     Integer temperature, Integer humidity, Long interval, Boolean notify) {
        try {
            updateRucheConstantsAsync(uid, rucherId, rucheId, temperature, humidity, interval, notify)
                    .get(5, TimeUnit.SECONDS);
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
        } catch (ExecutionException | TimeoutException ignored) { }
    }


    public void upsertRucher(String uid, Ruchers rucher) {
        if (uid == null || uid.isBlank()) throw new IllegalArgumentException("uid manquant");
        if (rucher == null) throw new IllegalArgumentException("rucher manquant");

        String rucherId = rucher.getId();
        if (!isValidKey(rucherId)) {
            throw new IllegalArgumentException("Identifiant rucher invalide (caractères . # $ [ ] / interdits)");
        }

        DatabaseReference ref = root.child(uid).child(rucherId);
        long now = System.currentTimeMillis();

        // LECTURE (bloquante via ton utilitaire)
        DataSnapshot snap = join(FirebaseDbUtils.getOnce(ref));
        boolean exists = (snap != null && snap.exists());

        Long createdAt = exists
                ? snap.child("createdAt").getValue(Long.class)
                : (rucher.getCreatedAt() != null ? rucher.getCreatedAt() : now);

        Map<String, Object> data = new HashMap<>();
        data.put("id", rucherId);
        data.put("address", rucher.getAddress() != null ? rucher.getAddress() : null);
        data.put("description", rucher.getDescription() != null ? rucher.getDescription() : null);
        data.put("createdAt", createdAt);
        data.put("updatedAt", now);

        join(FirebaseDbUtils.updateChildren(ref, data));
    }



    public CompletableFuture<Map<String, Ruches>> findRuchesForRucherAsync(String uid, String rucherId) {
        DatabaseReference rucherRef = root.child(uid).child(rucherId);
        return FirebaseDbUtils.getOnce(rucherRef).thenApply(rucherSnap -> {
            Map<String, Ruches> result = new LinkedHashMap<>();
            if (!rucherSnap.exists()) return result;

            for (DataSnapshot child : rucherSnap.getChildren()) {
                String key = child.getKey();
                if (key == null) continue;

                if ("nom".equals(key) || "address".equals(key) || "description".equals(key)
                        || "createdAt".equals(key) || "updatedAt".equals(key)) {
                    continue;
                }


                boolean looksLikeRuche = child.child("constants").exists() || child.child("measurements").exists();
                if (!looksLikeRuche) continue;

                Ruches ruche = child.getValue(Ruches.class);
                if (ruche == null) ruche = new Ruches();
                if (ruche.getId() == null || ruche.getId().isBlank()) {
                    ruche.setId(key);
                }
                result.put(key, ruche);
            }
            return result;
        });
    }

    /** Version bloquante (pratique dans un contrôleur MVC). */
    public Map<String, Ruches> findRuchesForRucher(String uid, String rucherId) {
        try {
            return findRuchesForRucherAsync(uid, rucherId).get(5, TimeUnit.SECONDS);
        } catch (InterruptedException ie) {
            Thread.currentThread().interrupt();
            return Collections.emptyMap();
        } catch (ExecutionException | TimeoutException e) {
            return Collections.emptyMap();
        }
    }



    /** Asynchrone. */
    public CompletableFuture<Optional<Ruches>> findRucheAsync(String uid, String rucherId, String rucheId) {
        DatabaseReference rucheRef = root.child(uid).child(rucherId).child(rucheId);
        return FirebaseDbUtils.getOnce(rucheRef).thenApply(snap -> {
            if (!snap.exists()) return Optional.empty();
            Ruches r = snap.getValue(Ruches.class);
            if (r == null) r = new Ruches();
            if (r.getId() == null || r.getId().isBlank()) r.setId(rucheId);
            return Optional.of(r);
        });
    }

    /** Bloquante. */
    public Optional<Ruches> findRuche(String uid, String rucherId, String rucheId) {
        try {
            return findRucheAsync(uid, rucherId, rucheId).get(5, TimeUnit.SECONDS);
        } catch (InterruptedException ie) {
            Thread.currentThread().interrupt();
            return Optional.empty();
        } catch (ExecutionException | TimeoutException e) {
            return Optional.empty();
        }
    }



    public CompletableFuture<List<Ruchers>> findAllForUserUidAsync(String uid) {
        DatabaseReference userRef = root.child(uid);
        return FirebaseDbUtils.getOnce(userRef).thenApply(userRoot -> {
            List<Ruchers> out = new ArrayList<>();
            if (!userRoot.exists()) return out;

            for (DataSnapshot rucherSnap : userRoot.getChildren()) {
                String rucherKey = rucherSnap.getKey();
                if (rucherKey == null) continue;

                Ruchers r = new Ruchers();
                r.setId(rucherKey);
                if (rucherSnap.child("nom").exists())        r.setNom(String.valueOf(rucherSnap.child("nom").getValue()));
                if (rucherSnap.child("address").exists())    r.setAddress(String.valueOf(rucherSnap.child("address").getValue()));
                if (rucherSnap.child("description").exists())r.setDescription(String.valueOf(rucherSnap.child("description").getValue()));
                if (rucherSnap.child("createdAt").exists())  r.setCreatedAt(rucherSnap.child("createdAt").getValue(Long.class));
                if (rucherSnap.child("updatedAt").exists())  r.setUpdatedAt(rucherSnap.child("updatedAt").getValue(Long.class));
                if (r.getNom() == null || r.getNom().isBlank()) r.setNom(rucherKey);

                Map<String, Ruches> ruchesMap = new LinkedHashMap<>();
                for (DataSnapshot child : rucherSnap.getChildren()) {
                    String k = child.getKey();
                    if (k == null) continue;
                    if ("nom".equals(k) || "address".equals(k) || "description".equals(k)
                            || "createdAt".equals(k) || "updatedAt".equals(k)) {
                        continue;
                    }
                    boolean looksLikeRuche = child.child("constants").exists() || child.child("measurements").exists();
                    if (!looksLikeRuche) continue;

                    Ruches ruche = child.getValue(Ruches.class);
                    if (ruche == null) ruche = new Ruches();
                    if (ruche.getId() == null || ruche.getId().isBlank()) ruche.setId(k);
                    ruchesMap.put(k, ruche);
                }
                r.setRuches(ruchesMap);
                out.add(r);
            }
            return out;
        });
    }

    public List<Ruchers> findAllForUserUid(String uid) {
        try {
            return findAllForUserUidAsync(uid).get(5, TimeUnit.SECONDS);
        } catch (InterruptedException ie) {
            Thread.currentThread().interrupt();
            return List.of();
        } catch (ExecutionException | TimeoutException e) {
            return List.of();
        }
    }



}
