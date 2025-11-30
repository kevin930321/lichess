package com.linovelib.reader.activity;

import android.content.Intent;
import android.os.Bundle;
import android.util.Log;
import android.view.View;
import android.widget.ProgressBar;
import android.widget.Toast;

import androidx.appcompat.app.AppCompatActivity;
import androidx.recyclerview.widget.LinearLayoutManager;
import androidx.recyclerview.widget.RecyclerView;

import com.linovelib.reader.R;
import com.linovelib.reader.adapter.ChapterListAdapter;
import com.linovelib.reader.api.LinovelibAPI;
import com.linovelib.reader.model.Chapter;
import com.linovelib.reader.model.Volume;
import com.linovelib.reader.parser.LinovelibParser;

import java.util.List;

public class ChapterListActivity extends AppCompatActivity {
    private static final String TAG = "ChapterListActivity";

    private RecyclerView recyclerView;
    private ProgressBar progressBar;
    private ChapterListAdapter adapter;
    private String novelId;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_chapter_list);

        recyclerView = findViewById(R.id.recyclerView);
        progressBar = findViewById(R.id.progressBar);

        novelId = getIntent().getStringExtra("novel_id");

        adapter = new ChapterListAdapter();
        recyclerView.setLayoutManager(new LinearLayoutManager(this));
        recyclerView.setAdapter(adapter);

        adapter.setOnChapterClickListener(chapter -> {
            Intent intent = new Intent(this, ReaderActivity.class);
            intent.putExtra("novel_id", novelId);
            intent.putExtra("chapter_url", chapter.getChapterUrl());
            intent.putExtra("chapter_title", chapter.getChapterTitle());
            startActivity(intent);
        });

        if (novelId != null) {
            loadChapterList();
        }
    }

    private void loadChapterList() {
        progressBar.setVisibility(View.VISIBLE);
        recyclerView.setVisibility(View.GONE);

        new Thread(() -> {
            try {
                String html = LinovelibAPI.getInstance().fetchCatalog(novelId);
                List<Volume> volumes = LinovelibParser.parseCatalog(html);

                runOnUiThread(() -> {
                    adapter.setVolumes(volumes);
                    progressBar.setVisibility(View.GONE);
                    recyclerView.setVisibility(View.VISIBLE);

                    if (volumes.isEmpty()) {
                        Toast.makeText(this, "沒有找到章節", Toast.LENGTH_SHORT).show();
                    }
                });
            } catch (Exception e) {
                Log.e(TAG, "Error loading chapters", e);
                runOnUiThread(() -> {
                    progressBar.setVisibility(View.GONE);
                    Toast.makeText(this, "載入失敗：" + e.getMessage(), Toast.LENGTH_SHORT).show();
                });
            }
        }).start();
    }
}
