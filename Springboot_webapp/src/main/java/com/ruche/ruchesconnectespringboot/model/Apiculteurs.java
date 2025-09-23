package com.ruche.ruchesconnectespringboot.model;
import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;


@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@JsonIgnoreProperties(ignoreUnknown = true)
public class Apiculteurs {
    private String id;
    private String nom;
    private String prenom;
    private String adresse;
    private String email;
    private String password;
    private Long createdAt;
    private Long modifiedAt;
}
