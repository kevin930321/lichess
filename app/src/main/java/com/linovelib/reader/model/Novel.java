package com.linovelib.reader.model;

import java.io.Serializable;
import java.util.List;

public class Novel implements Serializable {
    private String novelId;
    private String title;
    private String author;
    private String illustrator;
    private String translator;
    private String coverUrl;
    private String description;
    private List<String> tags;
    private float rating;
    private String status;
    private int favoriteCount;

    public Novel() {
    }

    public Novel(String novelId, String title) {
        this.novelId = novelId;
        this.title = title;
    }

    // Getters
    public String getNovelId() { return novelId; }
    public String getTitle() { return title; }
    public String getAuthor() { return author; }
    public String getIllustrator() { return illustrator; }
    public String getTranslator() { return translator; }
    public String getCoverUrl() { return coverUrl; }
    public String getDescription() { return description; }
    public List<String> getTags() { return tags; }
    public float getRating() { return rating; }
    public String getStatus() { return status; }
    public int getFavoriteCount() { return favoriteCount; }

    // Setters
    public void setNovelId(String novelId) { this.novelId = novelId; }
    public void setTitle(String title) { this.title = title; }
    public void setAuthor(String author) { this.author = author; }
    public void setIllustrator(String illustrator) { this.illustrator = illustrator; }
    public void setTranslator(String translator) { this.translator = translator; }
    public void setCoverUrl(String coverUrl) { this.coverUrl = coverUrl; }
    public void setDescription(String description) { this.description = description; }
    public void setTags(List<String> tags) { this.tags = tags; }
    public void setRating(float rating) { this.rating = rating; }
    public void setStatus(String status) { this.status = status; }
    public void setFavoriteCount(int favoriteCount) { this.favoriteCount = favoriteCount; }
}
