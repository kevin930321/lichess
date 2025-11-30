package com.linovelib.reader.api;

import android.util.Log;

import java.io.IOException;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.concurrent.TimeUnit;

import okhttp3.Cookie;
import okhttp3.CookieJar;
import okhttp3.HttpUrl;
import okhttp3.OkHttpClient;
import okhttp3.Request;
import okhttp3.Response;

public class LinovelibAPI {
    private static final String TAG = "LinovelibAPI";
    private static final String BASE_URL = "https://tw.linovelib.com";
    private static final int TIMEOUT_SECONDS = 15;
    
    private static LinovelibAPI instance;
    private final OkHttpClient client;

    private LinovelibAPI() {
        client = new OkHttpClient.Builder()
                .connectTimeout(TIMEOUT_SECONDS, TimeUnit.SECONDS)
                .readTimeout(TIMEOUT_SECONDS, TimeUnit.SECONDS)
                .writeTimeout(TIMEOUT_SECONDS, TimeUnit.SECONDS)
                .cookieJar(new CookieJar() {
                    private final HashMap<String, List<Cookie>> cookieStore = new HashMap<>();

                    @Override
                    public void saveFromResponse(HttpUrl url, List<Cookie> cookies) {
                        if (cookies != null && !cookies.isEmpty()) {
                            List<Cookie> currentCookies = cookieStore.get(url.host());
                            if (currentCookies == null) {
                                currentCookies = new ArrayList<>();
                                cookieStore.put(url.host(), currentCookies);
                            }
                            // Simple logic: replace old cookies with new ones by name
                            for (Cookie newCookie : cookies) {
                                for (int i = 0; i < currentCookies.size(); i++) {
                                    if (currentCookies.get(i).name().equals(newCookie.name())) {
                                        currentCookies.remove(i);
                                        break;
                                    }
                                }
                                currentCookies.add(newCookie);
                            }
                        }
                    }

                    @Override
                    public List<Cookie> loadForRequest(HttpUrl url) {
                        List<Cookie> cookies = cookieStore.get(url.host());
                        return cookies != null ? cookies : new ArrayList<>();
                    }
                })
                .build();
    }

    public static synchronized LinovelibAPI getInstance() {
        if (instance == null) {
            instance = new LinovelibAPI();
        }
        return instance;
    }

    /**
     * 獲取首頁 HTML
     */
    public String fetchHomePage() throws IOException {
        return fetchUrl(BASE_URL + "/");
    }

    /**
     * 獲取小說詳情頁 HTML
     */
    public String fetchNovelDetail(String novelId) throws IOException {
        return fetchUrl(BASE_URL + "/novel/" + novelId + ".html");
    }

    /**
     * 獲取章節目錄 HTML
     */
    public String fetchCatalog(String novelId) throws IOException {
        return fetchUrl(BASE_URL + "/novel/" + novelId + "/catalog");
    }

    /**
     * 獲取章節內容 HTML
     */
    public String fetchChapterContent(String chapterUrl) throws IOException {
        // 如果URL已經是完整的，直接使用；否則補充 BASE_URL
        if (chapterUrl.startsWith("http")) {
            return fetchUrl(chapterUrl);
        } else {
            return fetchUrl(BASE_URL + chapterUrl);
        }
    }

    /**
     * 搜索小說
     */
    public String searchNovels(String keyword) throws IOException {
        // 這裡需要根據實際網站的搜索URL格式調整
        String url = BASE_URL + "/search.php?keyword=" + keyword;
        return fetchUrl(url);
    }

    /**
     * 通用的 URL 請求方法
     */
    private String fetchUrl(String url) throws IOException {
        Log.d(TAG, "Fetching URL: " + url);

        Request request = new Request.Builder()
                .url(url)
                .addHeader("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36")
                .addHeader("Accept", "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7")
                .addHeader("Accept-Language", "zh-TW,zh;q=0.9,en-US;q=0.8,en;q=0.7")
                .addHeader("Referer", BASE_URL + "/")
                .build();

        try (Response response = client.newCall(request).execute()) {
            if (!response.isSuccessful()) {
                throw new IOException("Unexpected code " + response);
            }

            if (response.body() == null) {
                throw new IOException("Response body is null");
            }

            return response.body().string();
        }
    }
}
