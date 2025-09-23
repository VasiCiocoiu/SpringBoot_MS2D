package com.ruche.ruchesconnectespringboot.model;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import lombok.Getter;
import lombok.Setter;

import java.util.Map;

@Setter
@Getter
@JsonIgnoreProperties(ignoreUnknown = true)
public class Ruches {
    // Getters / Setters (outer)
    private String id;                       // "ruche_2"
    private String address;                  // adresse postale ou GPS
    private String description;              // notes libres
    private Boolean notificationsEnabled;    // on/off
    private Long createdAt;                  // epoch millis
    private Long modifiedAt;                 // epoch millis

    private RucheConstants constants;               // ← classe imbriquée ci-dessous
    private Map<String, Measurement> measurements;  // ← idem

    public Ruches() {}

    /* ===================== NESTED CLASSES ===================== */

    @Setter
    @Getter
    @JsonIgnoreProperties(ignoreUnknown = true)
    public static class RucheConstants {
        private Integer humidity;
        private Integer temperature;
        private Long interval;
        private Boolean notify;

        public RucheConstants() {}

    }

    @Setter
    @Getter
    @JsonIgnoreProperties(ignoreUnknown = true)
    public static class Measurement {
        private String type;              // "data", "hum_event", "cover_opened"

        private DataPackage data_package;
        public Measurement() {}

    }

    @Setter
    @Getter
    @JsonIgnoreProperties(ignoreUnknown = true)
    public static class DataPackage {
        private Integer humidity;
        private Integer temperature;

        public DataPackage() {}

    }
}
