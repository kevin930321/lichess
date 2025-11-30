package com.linovelib.reader.adapter;

import android.content.Context;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ImageView;
import android.widget.TextView;

import androidx.annotation.NonNull;
import androidx.recyclerview.widget.RecyclerView;

import com.bumptech.glide.Glide;
import com.linovelib.reader.R;
import com.linovelib.reader.model.Novel;

import java.util.ArrayList;
import java.util.List;

public class NovelListAdapter extends RecyclerView.Adapter<NovelListAdapter.ViewHolder> {
    private List<Novel> novels;
    private final Context context;
    private OnItemClickListener listener;

    public interface OnItemClickListener {
        void onItemClick(Novel novel);
    }

    public NovelListAdapter(Context context) {
        this.context = context;
        this.novels = new ArrayList<>();
    }

    public void setOnItemClickListener(OnItemClickListener listener) {
        this.listener = listener;
    }

    public void setNovels(List<Novel> novels) {
        this.novels = novels;
        notifyDataSetChanged();
    }

    @NonNull
    @Override
    public ViewHolder onCreateViewHolder(@NonNull ViewGroup parent, int viewType) {
        View view = LayoutInflater.from(parent.getContext())
                .inflate(R.layout.item_novel, parent, false);
        return new ViewHolder(view);
    }

    @Override
    public void onBindViewHolder(@NonNull ViewHolder holder, int position) {
        Novel novel = novels.get(position);
        
        holder.tvTitle.setText(novel.getTitle());
        holder.tvAuthor.setText(novel.getAuthor() != null ? "作者：" + novel.getAuthor() : "");
        holder.tvDescription.setText(novel.getDescription() != null ? novel.getDescription() : "");

        // Load cover image with Glide
        if (novel.getCoverUrl() != null && !novel.getCoverUrl().isEmpty()) {
            Glide.with(context)
                    .load(novel.getCoverUrl())
                    .placeholder(android.R.drawable.ic_menu_gallery)
                    .error(android.R.drawable.ic_menu_gallery)
                    .into(holder.ivCover);
        }

        holder.itemView.setOnClickListener(v -> {
            if (listener != null) {
                listener.onItemClick(novel);
            }
        });
    }

    @Override
    public int getItemCount() {
        return novels.size();
    }

    static class ViewHolder extends RecyclerView.ViewHolder {
        ImageView ivCover;
        TextView tvTitle;
        TextView tvAuthor;
        TextView tvDescription;

        ViewHolder(View itemView) {
            super(itemView);
            ivCover = itemView.findViewById(R.id.ivCover);
            tvTitle = itemView.findViewById(R.id.tvTitle);
            tvAuthor = itemView.findViewById(R.id.tvAuthor);
            tvDescription = itemView.findViewById(R.id.tvDescription);
        }
    }
}
