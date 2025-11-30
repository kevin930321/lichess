package com.linovelib.reader.activity;

import android.content.Intent;
import android.os.Bundle;
import android.util.Log;
import android.view.View;
import android.widget.Button;
import android.widget.ImageView;
import android.widget.ProgressBar;
import android.widget.TextView;
import android.widget.Toast;

import androidx.appcompat.app.AppCompatActivity;

import com.bumptech.glide.Glide;
import com.linovelib.reader.R;
import com.linovelib.reader.api.LinovelibAPI;
import com.linovelib.reader.database.FavoritesDao;
import com.linovelib.reader.model.Novel;
import com.linovelib.reader.parser.LinovelibParser;

public class NovelDetailActivity extends AppCompatActivity {
    private static final String TAG = "NovelDetailActivity";

    private ImageView ivCover;
    private TextView tvTitle, tvAuthor, tvIllustrator, tvTranslator, tvDescription;
    private Button btnStartReading, btnFavorite;
    private ProgressBar progressBar;

    private Novel novel;
    private String novelId;
    private FavoritesDao favoritesDao;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_novel_detail);

        initViews();

        favoritesDao = new FavoritesDao(this);

        // Get novel ID and novel object from intent
        novelId = getIntent().getStringExtra("novel_id");
        novel = (Novel) getIntent().getSerializableExtra("novel");

        if (novel != null && novel.getNovelId() != null) {
            novelId = novel.getNovelId();
            displayNovel(novel);
        }

        if (novelId != null) {
            loadNovelDetail();
            updateFavoriteButton();
        }

        btnStartReading.setOnClickListener(v -> {
            if (novel != null && novel.getNovelId() != null) {
                Intent intent = new Intent(this, ChapterListActivity.class);
                intent.putExtra("novel_id", novel.getNovelId());
                startActivity(intent);
            }
        });

        btnFavorite.setOnClickListener(v -> toggleFavorite());
    }

    private void initViews() {
        ivCover = findViewById(R.id.ivCover);
        tvTitle = findViewById(R.id.tvTitle);
        tvAuthor = findViewById(R.id.tvAuthor);
        tvIllustrator = findViewById(R.id.tvIllustrator);
        tvTranslator = findViewById(R.id.tvTranslator);
        tvDescription = findViewById(R.id.tvDescription);
        btnStartReading = findViewById(R.id.btnStartReading);
        btnFavorite = findViewById(R.id.btnFavorite);
        progressBar = findViewById(R.id.progressBar);
    }

    private void loadNovelDetail() {
        progressBar.setVisibility(View.VISIBLE);

        new Thread(() -> {
            try {
                String html = LinovelibAPI.getInstance().fetchNovelDetail(novelId);
                Novel detailedNovel = LinovelibParser.parseNovelDetail(html);
                detailedNovel.setNovelId(novelId);

                // Merge with existing data
                if (novel == null) {
                    novel = detailedNovel;
                } else {
                    // Update with detailed information
                    if (detailedNovel.getAuthor() != null) novel.setAuthor(detailedNovel.getAuthor());
                    if (detailedNovel.getIllustrator() != null) novel.setIllustrator(detailedNovel.getIllustrator());
                    if (detailedNovel.getTranslator() != null) novel.setTranslator(detailedNovel.getTranslator());
                    if (detailedNovel.getDescription() != null) novel.setDescription(detailedNovel.getDescription());
                    if (detailedNovel.getCoverUrl() != null) novel.setCoverUrl(detailedNovel.getCoverUrl());
                }

                runOnUiThread(() -> {
                    displayNovel(novel);
                    progressBar.setVisibility(View.GONE);
                });
            } catch (Exception e) {
                Log.e(TAG, "Error loading novel detail", e);
                runOnUiThread(() -> {
                    progressBar.setVisibility(View.GONE);
                    Toast.makeText(this, "載入失敗：" + e.getMessage(), Toast.LENGTH_SHORT).show();
                });
            }
        }).start();
    }

    private void displayNovel(Novel novel) {
        tvTitle.setText(novel.getTitle());
        tvAuthor.setText(novel.getAuthor() != null ? getString(R.string.author, novel.getAuthor()) : "");
        tvIllustrator.setText(novel.getIllustrator() != null ? getString(R.string.illustrator, novel.getIllustrator()) : "");
        tvTranslator.setText(novel.getTranslator() != null ? getString(R.string.translator, novel.getTranslator()) : "");
        tvDescription.setText(novel.getDescription() != null ? novel.getDescription() : "");

        if (novel.getCoverUrl() != null) {
            Glide.with(this)
                    .load(novel.getCoverUrl())
                    .into(ivCover);
        }
    }

    private void updateFavoriteButton() {
        new Thread(() -> {
            boolean isFavorite = favoritesDao.isFavorite(novelId);
            runOnUiThread(() -> {
                btnFavorite.setText(isFavorite ? R.string.btn_remove_favorite : R.string.btn_add_favorite);
            });
        }).start();
    }

    private void toggleFavorite() {
        new Thread(() -> {
            boolean isFavorite = favoritesDao.isFavorite(novelId);

            if (isFavorite) {
                favoritesDao.removeFavorite(novelId);
                runOnUiThread(() -> {
                    Toast.makeText(this, R.string.favorite_removed, Toast.LENGTH_SHORT).show();
                    btnFavorite.setText(R.string.btn_add_favorite);
                });
            } else {
                if (novel != null) {
                    favoritesDao.addFavorite(novel);
                    runOnUiThread(() -> {
                        Toast.makeText(this, R.string.favorite_added, Toast.LENGTH_SHORT).show();
                        btnFavorite.setText(R.string.btn_remove_favorite);
                    });
                }
            }
        }).start();
    }
}
