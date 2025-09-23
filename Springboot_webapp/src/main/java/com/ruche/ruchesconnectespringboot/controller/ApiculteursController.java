package com.ruche.ruchesconnectespringboot.controller;

import com.ruche.ruchesconnectespringboot.model.Apiculteurs;
import com.ruche.ruchesconnectespringboot.service.ApiculteursService;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.*;

@Controller
@RequestMapping("/apiculteurs")
public class ApiculteursController {

    private final ApiculteursService service;

    public ApiculteursController(ApiculteursService service) {
        this.service = service;
    }

    @GetMapping
    public String list(Model model) {
        model.addAttribute("apiculteurs", service.findAll());
        return "admin/apiculteur_list"; // => templates/admin/apiculteur_list.html
    }

    @GetMapping("/new")
    public String newForm(Model model) {
        model.addAttribute("apiculteur", new Apiculteurs()); // ✅ singulier
        return "admin/create_apiculteur";
    }

    @PostMapping
    public String create(@ModelAttribute("apiculteur") Apiculteurs a, // ✅ singulier
                         @RequestParam(value = "rawPassword", required = false) String rawPassword) {
        if (rawPassword != null && !rawPassword.isBlank()) {
            a.setPassword(rawPassword);
        }
        service.upsert(a);
        return "redirect:/admin/apiculteur_list";
    }

    @GetMapping("/{id}")
    public String detail(@PathVariable String id, Model model) {
        model.addAttribute("apiculteur", service.findById(id).orElse(null));
        return "apiculteurs/detail";
    }

    @PostMapping("/{id}/delete")
    public String delete(@PathVariable String id) {
        service.delete(id);
        return "redirect:/apiculteurs";
    }
}
