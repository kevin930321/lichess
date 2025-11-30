package com.linovelib.reader.fragment;

import android.content.Intent;
import android.os.Bundle;
import android.util.Log;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.Toast;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.fragment.app.Fragment;
import androidx.recyclerview.widget.LinearLayoutManager;
import androidx.recyclerview.widget.RecyclerView;
import androidx.swiperefreshlayout.widget.SwipeRefreshLayout;

import com.linovelib.reader.R;
import com.linovelib.reader.activity.NovelDetailActivity;
import com.linovelib.reader.adapter.NovelListAdapter;
import com.linovelib.reader.api.LinovelibAPI;
import com.linovelib.reader.model.Novel;
import com.linovelib.reader.parser.LinovelibParser;

import java.util.List;

public class RecommendFragment extends Fragment {
    private static final String TAG = "RecommendFragment";
    
    private RecyclerView recyclerView;
    private SwipeRefreshLayout swipeRefresh;
    private NovelListAdapter adapter;

    @Nullable
    @Override
    public View onCreateView(@NonNull LayoutInflater inflater, @Nullable ViewGroup container, @Nullable Bundle savedInstanceState) {
        return inflater.inflate(R.layout.fragment_novel_list, container, false);
    }

    @Override
    public void onViewCreated(@NonNull View view, @Nullable Bundle savedInstanceState) {
        super.onViewCreated(view, savedInstanceState);

        recyclerView = view.findViewById(R.id.recyclerView);
        swipeRefresh = view.findViewById(R.id.swipeRefresh);

        adapter = new NovelListAdapter(requireContext());
        recyclerView.setLayoutManager(new LinearLayoutManager(requireContext()));
        recyclerView.setAdapter(adapter);

        adapter.setOnItemClickListener(novel -> {
            Intent intent = new Intent(requireContext(), NovelDetailActivity.class);
            intent.putExtra("novel_id", novel.getNovelId());
            intent.putExtra("novel", novel);
            startActivity(intent);
        });

        swipeRefresh.setOnRefreshListener(this::loadNovels);

        loadNovels();
    }

    private void loadNovels() {
        swipeRefresh.setRefreshing(true);

        new Thread(() -> {
            try {
                String html = LinovelibAPI.getInstance().fetchHomePage();
                List<Novel> novels = LinovelibParser.parseNovelList(html);

                requireActivity().runOnUiThread(() -> {
                    adapter.setNovels(novels);
                    swipeRefresh.setRefreshing(false);
                    
                    if (novels.isEmpty()) {
                        Toast.makeText(requireContext(), "沒有找到小說", Toast.LENGTH_SHORT).show();
                    }
                });
            } catch (Exception e) {
                Log.e(TAG, "Error loading novels", e);
                requireActivity().runOnUiThread(() -> {
                    swipeRefresh.setRefreshing(false);
                    Toast.makeText(requireContext(), "加載失敗：" + e.getMessage(), Toast.LENGTH_SHORT).show();
                });
            }
        }).start();
    }
}
