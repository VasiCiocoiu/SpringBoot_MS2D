package com.ruche.ruchesconnectespringboot.model;
import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import lombok.*;
import java.util.Map;

@Getter @Setter @NoArgsConstructor @AllArgsConstructor
@JsonIgnoreProperties(ignoreUnknown = true)
public class Ruchers {
    private String id;
    private String nom;
    private String address;
    private String description;
    private Long createdAt;
    private Long updatedAt;

    private Map<String, Ruches> ruches;
}
