package com.linovelib.reader.model;

import java.io.Serializable;
import java.util.ArrayList;
import java.util.List;

public class Volume implements Serializable {
    private String volumeId;
    private String volumeName;
    private String volumeUrl;
    private List<Chapter> chapters;

    public Volume() {
        this.chapters = new ArrayList<>();
    }

    public Volume(String volumeId, String volumeName) {
        this.volumeId = volumeId;
        this.volumeName = volumeName;
        this.chapters = new ArrayList<>();
    }

    // Getters
    public String getVolumeId() { return volumeId; }
    public String getVolumeName() { return volumeName; }
    public String getVolumeUrl() { return volumeUrl; }
    public List<Chapter> getChapters() { return chapters; }

    // Setters
    public void setVolumeId(String volumeId) { this.volumeId = volumeId; }
    public void setVolumeName(String volumeName) { this.volumeName = volumeName; }
    public void setVolumeUrl(String volumeUrl) { this.volumeUrl = volumeUrl; }
    public void setChapters(List<Chapter> chapters) { this.chapters = chapters; }

    // Helper methods
    public void addChapter(Chapter chapter) {
        this.chapters.add(chapter);
    }
}
