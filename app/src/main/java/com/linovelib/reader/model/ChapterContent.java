package com.linovelib.reader.model;

import java.io.Serializable;

public class ChapterContent implements Serializable {
    private String chapterId;
    private String title;
    private String content;
    private String prevChapterUrl;
    private String nextChapterUrl;

    public ChapterContent() {
    }

    public ChapterContent(String chapterId, String title, String content) {
        this.chapterId = chapterId;
        this.title = title;
        this.content = content;
    }

    // Getters
    public String getChapterId() { return chapterId; }
    public String getTitle() { return title; }
    public String getContent() { return content; }
    public String getPrevChapterUrl() { return prevChapterUrl; }
    public String getNextChapterUrl() { return nextChapterUrl; }

    // Setters
    public void setChapterId(String chapterId) { this.chapterId = chapterId; }
    public void setTitle(String title) { this.title = title; }
    public void setContent(String content) { this.content = content; }
    public void setPrevChapterUrl(String prevChapterUrl) { this.prevChapterUrl = prevChapterUrl; }
    public void setNextChapterUrl(String nextChapterUrl) { this.nextChapterUrl = nextChapterUrl; }
}
