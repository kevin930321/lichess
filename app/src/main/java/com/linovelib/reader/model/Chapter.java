package com.linovelib.reader.model;

import java.io.Serializable;

public class Chapter implements Serializable {
    private String chapterId;
    private String chapterTitle;
    private String chapterUrl;
    private String volumeId;
    private boolean isRead;

    public Chapter() {
    }

    public Chapter(String chapterId, String chapterTitle, String chapterUrl) {
        this.chapterId = chapterId;
        this.chapterTitle = chapterTitle;
        this.chapterUrl = chapterUrl;
        this.isRead = false;
    }

    // Getters
    public String getChapterId() { return chapterId; }
    public String getChapterTitle() { return chapterTitle; }
    public String getChapterUrl() { return chapterUrl; }
    public String getVolumeId() { return volumeId; }
    public boolean isRead() { return isRead; }

    // Setters
    public void setChapterId(String chapterId) { this.chapterId = chapterId; }
    public void setChapterTitle(String chapterTitle) { this.chapterTitle = chapterTitle; }
    public void setChapterUrl(String chapterUrl) { this.chapterUrl = chapterUrl; }
    public void setVolumeId(String volumeId) { this.volumeId = volumeId; }
    public void setRead(boolean read) { isRead = read; }
}
