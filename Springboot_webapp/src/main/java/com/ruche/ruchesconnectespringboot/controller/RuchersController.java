package com.ruche.ruchesconnectespringboot.controller;

import com.ruche.ruchesconnectespringboot.model.Ruchers;
import com.ruche.ruchesconnectespringboot.model.Ruches;
import com.ruche.ruchesconnectespringboot.security.FirebaseUser;
import com.ruche.ruchesconnectespringboot.service.RucherService;
import org.springframework.security.core.Authentication;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.*;

import java.util.ArrayList;
import java.util.Map;

@Controller
@RequestMapping("/ruchers")
public class RuchersController {

    private final RucherService rucherService;

    public RuchersController(RucherService rucherService) {
        this.rucherService = rucherService;
    }

    /* -------- util -------- */
    private String requireUid(Authentication auth) {
        if (auth == null || auth.getPrincipal() == null) return null;
        Object p = auth.getPrincipal();
        if (p instanceof FirebaseUser fu) return fu.getUid();
        return auth.getName();
    }

    /* -------- liste des ruchers -------- */
    @GetMapping
    public String list(Authentication auth, Model model) {
        String uid = requireUid(auth);
        if (uid == null || uid.isBlank()) return "redirect:/login";
        model.addAttribute("ruchers", rucherService.findAllForUserUid(uid));
        return "user/ruchers"; // templates/user/ruchers.html
    }

    /* -------- formulaire de création -------- */
    // Chemin littéral => priorité sur "/{rucherId}", donc pas besoin de regex
    @GetMapping("/new")
    public String showCreateForm(Authentication auth, Model model) {
        String uid = requireUid(auth);
        if (uid == null || uid.isBlank()) return "redirect:/login";
        model.addAttribute("rucher", new Ruchers());
        return "user/create_rucher";
    }

    /* -------- création POST -------- */
    @PostMapping
    public String create(@ModelAttribute("rucher") Ruchers rucher,
                         Authentication auth,
                         Model model) {
        String uid = requireUid(auth);
        if (uid == null || uid.isBlank()) return "redirect:/login";

        // id obligatoire et sans caractères interdits
        if (rucher.getId() == null || rucher.getId().isBlank()
                || !RucherService.isValidKey(rucher.getId())) {
            model.addAttribute("error", "Identifiant invalide (interdits: . # $ [ ] /)");
            model.addAttribute("rucher", rucher);
            return "user/create_rucher"; // NE PAS rediriger, sinon on perd le message
        }

        // si "nom" vide, on met l'id pour l’affichage
        if (rucher.getNom() == null || rucher.getNom().isBlank()) {
            rucher.setNom(rucher.getId());
        }

        rucherService.upsertRucher(uid, rucher);
        return "redirect:/ruchers";
    }

    /* -------- vue d’un rucher: affiche ses ruches -------- */
    @GetMapping("/{rucherId}")
    public String viewRucher(@PathVariable String rucherId,
                             Authentication auth,
                             Model model) {
        String uid = requireUid(auth);
        if (uid == null || uid.isBlank()) return "redirect:/login";

        Map<String, Ruches> ruchesMap = rucherService.findRuchesForRucher(uid, rucherId);

        Ruchers r = new Ruchers();
        r.setId(rucherId);
        r.setNom(rucherId); // pour breadcrumbs si besoin

        model.addAttribute("rucherId", rucherId);
        model.addAttribute("rucher", r);
        model.addAttribute("ruches", new ArrayList<>(ruchesMap.values()));
        model.addAttribute("ruchesMap", ruchesMap);

        return "user/ruches_list";
    }
}
