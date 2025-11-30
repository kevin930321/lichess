package com.linovelib.reader.fragment;

import android.content.Intent;
import android.os.Bundle;
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
import com.linovelib.reader.database.FavoritesDao;
import com.linovelib.reader.model.Novel;

import java.util.List;

public class FavoritesFragment extends Fragment {
    private RecyclerView recyclerView;
    private SwipeRefreshLayout swipeRefresh;
    private NovelListAdapter adapter;
    private FavoritesDao favoritesDao;

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

        favoritesDao = new FavoritesDao(requireContext());

        adapter = new NovelListAdapter(requireContext());
        recyclerView.setLayoutManager(new LinearLayoutManager(requireContext()));
        recyclerView.setAdapter(adapter);

        adapter.setOnItemClickListener(novel -> {
            Intent intent = new Intent(requireContext(), NovelDetailActivity.class);
            intent.putExtra("novel_id", novel.getNovelId());
            intent.putExtra("novel", novel);
            startActivity(intent);
        });

        swipeRefresh.setOnRefreshListener(this::loadFavorites);

        loadFavorites();
    }

    @Override
    public void onResume() {
        super.onResume();
        loadFavorites();
    }

    private void loadFavorites() {
        swipeRefresh.setRefreshing(true);

        new Thread(() -> {
            List<Novel> favorites = favoritesDao.getAllFavorites();

            requireActivity().runOnUiThread(() -> {
                adapter.setNovels(favorites);
                swipeRefresh.setRefreshing(false);

                if (favorites.isEmpty()) {
                    Toast.makeText(requireContext(), R.string.empty_favorites, Toast.LENGTH_SHORT).show();
                }
            });
        }).start();
    }
}
