package com.linovelib.reader.activity;

import android.os.Bundle;
import android.util.Log;
import android.view.View;
import android.widget.Button;
import android.widget.LinearLayout;
import android.widget.ProgressBar;
import android.widget.ScrollView;
import android.widget.TextView;
import android.widget.Toast;

import androidx.appcompat.app.AppCompatActivity;

import com.linovelib.reader.R;
import com.linovelib.reader.api.LinovelibAPI;
import com.linovelib.reader.database.ReadingHistoryDao;
import com.linovelib.reader.model.ChapterContent;
import com.linovelib.reader.parser.LinovelibParser;

public class ReaderActivity extends AppCompatActivity {
    private static final String TAG = "ReaderActivity";

    private ScrollView scrollView;
    private TextView tvChapterTitle, tvContent;
    private LinearLayout bottomNav;
    private Button btnPrevChapter, btnChapterList, btnNextChapter;
    private ProgressBar progressBar;

    private String novelId;
    private String chapterUrl;
    private String chapterTitle;
    private ChapterContent currentContent;
    private ReadingHistoryDao historyDao;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_reader);

        initViews();

        historyDao = new ReadingHistoryDao(this);

        novelId = getIntent().getStringExtra("novel_id");
        chapterUrl = getIntent().getStringExtra("chapter_url");
        chapterTitle = getIntent().getStringExtra("chapter_title");

        loadChapter(chapterUrl);

        // Toggle navigation on content click
        scrollView.setOnClickListener(v -> toggleNavigation());

        btnPrevChapter.setOnClickListener(v -> {
            if (currentContent != null && currentContent.getPrevChapterUrl() != null) {
                loadChapter(currentContent.getPrevChapterUrl());
            } else {
                Toast.makeText(this, "已經是第一章", Toast.LENGTH_SHORT).show();
            }
        });

        btnNextChapter.setOnClickListener(v -> {
            if (currentContent != null && currentContent.getNextChapterUrl() != null) {
                loadChapter(currentContent.getNextChapterUrl());
            } else {
                Toast.makeText(this, "已經是最後一章", Toast.LENGTH_SHORT).show();
            }
        });

        btnChapterList.setOnClickListener(v -> finish());
    }

    private void initViews() {
        scrollView = findViewById(R.id.scrollView);
        tvChapterTitle = findViewById(R.id.tvChapterTitle);
        tvContent = findViewById(R.id.tvContent);
        bottomNav = findViewById(R.id.bottomNav);
        btnPrevChapter = findViewById(R.id.btnPrevChapter);
        btnChapterList = findViewById(R.id.btnChapterList);
        btnNextChapter = findViewById(R.id.btnNextChapter);
        progressBar = findViewById(R.id.progressBar);
    }

    private void loadChapter(String url) {
        progressBar.setVisibility(View.VISIBLE);
        tvContent.setVisibility(View.GONE);
        bottomNav.setVisibility(View.GONE);

        new Thread(() -> {
            try {
                String html = LinovelibAPI.getInstance().fetchChapterContent(url);
                ChapterContent content = LinovelibParser.parseChapterContent(html);

                runOnUiThread(() -> {
                    currentContent = content;
                    chapterUrl = url;
                    displayContent(content);
                    progressBar.setVisibility(View.GONE);
                    tvContent.setVisibility(View.VISIBLE);

                    // Save reading progress
                    if (novelId != null && chapterTitle != null) {
                        saveReadingProgress();
                    }
                });
            } catch (Exception e) {
                Log.e(TAG, "Error loading chapter", e);
                runOnUiThread(() -> {
                    progressBar.setVisibility(View.GONE);
                    Toast.makeText(this, "載入失敗：" + e.getMessage(), Toast.LENGTH_SHORT).show();
                });
            }
        }).start();
    }

    private void displayContent(ChapterContent content) {
        tvChapterTitle.setText(content.getTitle() != null ? content.getTitle() : chapterTitle);
        tvContent.setText(content.getContent() != null ? content.getContent() : "無法載入章節內容");

        // Scroll to top
        scrollView.scrollTo(0, 0);
    }

    private void toggleNavigation() {
        if (bottomNav.getVisibility() == View.VISIBLE) {
            bottomNav.setVisibility(View.GONE);
        } else {
            bottomNav.setVisibility(View.VISIBLE);
        }
    }

    private void saveReadingProgress() {
        new Thread(() -> {
            historyDao.saveReadingProgress(novelId, chapterUrl, chapterTitle, scrollView.getScrollY());
        }).start();
    }

    @Override
    protected void onPause() {
        super.onPause();
        if (novelId != null && chapterTitle != null) {
            saveReadingProgress();
        }
    }
}
