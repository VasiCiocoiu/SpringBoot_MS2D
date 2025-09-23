package com.ruche.ruchesconnectespringboot.controller;

import com.ruche.ruchesconnectespringboot.model.Ruchers;
import com.ruche.ruchesconnectespringboot.model.Ruches;
import com.ruche.ruchesconnectespringboot.security.FirebaseUser;
import com.ruche.ruchesconnectespringboot.service.RucherService;
import org.springframework.security.core.Authentication;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.time.format.DateTimeParseException;
import java.util.*;
import java.util.stream.Collectors;

import static com.ruche.ruchesconnectespringboot.service.RucherService.isValidKey;

@Controller
@RequestMapping("/ruchers/{rucherId}/ruches")
public class RuchesController {

    private final RucherService rucherService;
    private static final DateTimeFormatter MEAS_FMT = DateTimeFormatter.ofPattern("dd-MM-yyyy_HH:mm");

    public RuchesController(RucherService rucherService) {
        this.rucherService = rucherService;
    }

    /* ==================== UTIL ==================== */
    private String requireUid(Authentication auth) {
        if (auth == null || auth.getPrincipal() == null) return null;
        Object p = auth.getPrincipal();
        if (p instanceof FirebaseUser fu) return fu.getUid();   // ✅ UID Firebase
        return auth.getName(); // fallback (souvent l’email si mal configuré)
    }

    private LocalDateTime parseKey(String k) {
        if (k == null) return null;
        try {
            return LocalDateTime.parse(k, MEAS_FMT);
        } catch (DateTimeParseException e) {
            return null;
        }
    }

    /* ==================== LISTE DES RUCHES ==================== */
    @GetMapping
    public String list(@PathVariable String rucherId, Authentication auth, Model model) {
        String uid = requireUid(auth);
        if (uid == null || uid.isBlank()) return "redirect:/login";

        Map<String, Ruches> ruchesMap = rucherService.findRuchesForRucher(uid, rucherId);
        List<Ruches> ruchesList = new ArrayList<>(ruchesMap.values());

        model.addAttribute("rucherId", rucherId);
        model.addAttribute("ruchesMap", ruchesMap);
        model.addAttribute("ruches", ruchesList);

        Ruchers r = new Ruchers();
        r.setId(rucherId);
        r.setNom(rucherId);
        model.addAttribute("rucher", r);

        return "user/ruches_list";
    }


    /* ==================== DETAIL D’UNE RUCHE ==================== */
    @GetMapping("/{rucheId}")
    public String detail(@PathVariable String rucherId,
                         @PathVariable String rucheId,
                         Authentication auth,
                         Model model) {

        String uid = requireUid(auth);
        if (uid == null || uid.isBlank()) return "redirect:/login";

        Ruches ruche = rucherService.findRucheBlocking(uid, rucherId, rucheId);
        if (ruche == null) return "redirect:/ruchers/" + rucherId;

        // Trier les mesures
        Map<String, Ruches.Measurement> measures = ruche.getMeasurements();
        List<Map.Entry<String, Ruches.Measurement>> sortedMeasures = Collections.emptyList();
        Map.Entry<String, Ruches.Measurement> lastMeasurement = null;

        if (measures != null && !measures.isEmpty()) {
            sortedMeasures = measures.entrySet().stream()
                    .sorted(Comparator.comparing(
                            (Map.Entry<String, Ruches.Measurement> e) ->
                                    Optional.ofNullable(parseKey(e.getKey())).orElse(LocalDateTime.MIN)
                    ))
                    .toList();
            if (!sortedMeasures.isEmpty()) {
                lastMeasurement = sortedMeasures.getLast();
            }
        }

        List<Map.Entry<String, Ruches.Measurement>> last20 = sortedMeasures.stream()
                .skip(Math.max(0, sortedMeasures.size() - 20))
                .collect(Collectors.toList());


        List<Map<String, Object>> chartPoints = new ArrayList<>();
        for (Map.Entry<String, Ruches.Measurement> e : sortedMeasures) {
            String key = e.getKey(); // ex "20-09-2025_11:15"
            Ruches.Measurement m = e.getValue();
            Integer t = (m != null && m.getData_package() != null) ? m.getData_package().getTemperature() : null;
            Integer h = (m != null && m.getData_package() != null) ? m.getData_package().getHumidity() : null;

            Map<String, Object> row = new HashMap<>();
            row.put("key", key);
            row.put("temperature", t);
            row.put("humidity", h);
            chartPoints.add(row);
        }
        model.addAttribute("chartPoints", chartPoints);
        model.addAttribute("rucherId", rucherId);
        model.addAttribute("rucheId", rucheId);
        model.addAttribute("ruche", ruche);
        model.addAttribute("constants", ruche.getConstants());
        model.addAttribute("lastMeasurement", lastMeasurement);
        model.addAttribute("recentMeasurements", last20);
        model.addAttribute("measureCount", measures != null ? measures.size() : 0);
        model.addAttribute("notificationsEnabled",
                ruche.getNotificationsEnabled() != null ? ruche.getNotificationsEnabled() : Boolean.FALSE);

        // breadcrumb minimal
        Ruchers r = new Ruchers();
        r.setId(rucherId);
        model.addAttribute("rucher", r);

        return "user/ruche_detail";
    }

    /* ==================== FORMULAIRE CREATION ==================== */
    @GetMapping("/new")
    public String newForm(@PathVariable String rucherId, Authentication auth, Model model) {
        String uid = requireUid(auth);
        if (uid == null || uid.isBlank()) return "redirect:/login";

        model.addAttribute("rucherId", rucherId);
        model.addAttribute("ruche", new Ruches());
        return "user/create_ruches";
    }

    /* ==================== CREATION POST ==================== */
    @PostMapping
    public String create(@PathVariable String rucherId,
                         @ModelAttribute("ruche") Ruches ruche,
                         Authentication auth,
                         Model model) {
        String uid = requireUid(auth);
        if (uid == null || uid.isBlank()) return "redirect:/login";

        if (!isValidKey(ruche.getId())) {
            model.addAttribute("rucherId", rucherId);
            model.addAttribute("ruche", ruche);
            model.addAttribute("error", "Identifiant invalide : il ne doit pas contenir . # $ [ ] /");
            return "user/create_ruches"; // on revient sur le formulaire avec un message
        }

        if (ruche.getNotificationsEnabled() == null) {
            ruche.setNotificationsEnabled(Boolean.TRUE);
        }

        rucherService.upsertRuche(uid, rucherId, ruche);
        return "redirect:/ruchers/" + rucherId;
    }


    /* ==================== TOGGLE NOTIFS ==================== */
    @PostMapping("/{rucheId}/notifications")
    public String toggleNotif(@PathVariable String rucherId,
                              @PathVariable String rucheId,
                              @RequestParam("enabled") boolean enabled,
                              Authentication auth) {
        String uid = requireUid(auth);
        if (uid == null || uid.isBlank()) return "redirect:/login";

        rucherService.toggleNotifications(uid, rucherId, rucheId, enabled);
        return "redirect:/ruchers/" + rucherId + "/ruches/" + rucheId;
    }




}
