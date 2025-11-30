package com.linovelib.reader.adapter;

import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.TextView;

import androidx.annotation.NonNull;
import androidx.recyclerview.widget.RecyclerView;

import com.linovelib.reader.R;
import com.linovelib.reader.model.Chapter;
import com.linovelib.reader.model.Volume;

import java.util.ArrayList;
import java.util.List;

public class ChapterListAdapter extends RecyclerView.Adapter<RecyclerView.ViewHolder> {
    private static final int TYPE_VOLUME = 0;
    private static final int TYPE_CHAPTER = 1;

    private final List<Object> items;
    private OnChapterClickListener listener;

    public interface OnChapterClickListener {
        void onChapterClick(Chapter chapter);
    }

    public ChapterListAdapter() {
        this.items = new ArrayList<>();
    }

    public void setOnChapterClickListener(OnChapterClickListener listener) {
        this.listener = listener;
    }

    public void setVolumes(List<Volume> volumes) {
        items.clear();
        for (Volume volume : volumes) {
            items.add(volume);
            items.addAll(volume.getChapters());
        }
        notifyDataSetChanged();
    }

    @Override
    public int getItemViewType(int position) {
        if (items.get(position) instanceof Volume) {
            return TYPE_VOLUME;
        } else {
            return TYPE_CHAPTER;
        }
    }

    @NonNull
    @Override
    public RecyclerView.ViewHolder onCreateViewHolder(@NonNull ViewGroup parent, int viewType) {
        if (viewType == TYPE_VOLUME) {
            View view = LayoutInflater.from(parent.getContext())
                    .inflate(android.R.layout.simple_list_item_1, parent, false);
            return new VolumeViewHolder(view);
        } else {
            View view = LayoutInflater.from(parent.getContext())
                    .inflate(R.layout.item_chapter, parent, false);
            return new ChapterViewHolder(view);
        }
    }

    @Override
    public void onBindViewHolder(@NonNull RecyclerView.ViewHolder holder, int position) {
        if (holder instanceof VolumeViewHolder) {
            Volume volume = (Volume) items.get(position);
            ((VolumeViewHolder) holder).tvVolumeName.setText(volume.getVolumeName());
        } else if (holder instanceof ChapterViewHolder) {
            Chapter chapter = (Chapter) items.get(position);
            ChapterViewHolder chapterHolder = (ChapterViewHolder) holder;
            
            chapterHolder.tvChapterTitle.setText(chapter.getChapterTitle());
            chapterHolder.readIndicator.setVisibility(chapter.isRead() ? View.VISIBLE : View.GONE);
            
            chapterHolder.itemView.setOnClickListener(v -> {
                if (listener != null) {
                    listener.onChapterClick(chapter);
                }
            });
        }
    }

    @Override
    public int getItemCount() {
        return items.size();
    }

    static class VolumeViewHolder extends RecyclerView.ViewHolder {
        TextView tvVolumeName;

        VolumeViewHolder(View itemView) {
            super(itemView);
            tvVolumeName = itemView.findViewById(android.R.id.text1);
            tvVolumeName.setTextSize(18);
            tvVolumeName.setPadding(32, 24, 32, 24);
        }
    }

    static class ChapterViewHolder extends RecyclerView.ViewHolder {
        TextView tvChapterTitle;
        View readIndicator;

        ChapterViewHolder(View itemView) {
            super(itemView);
            tvChapterTitle = itemView.findViewById(R.id.tvChapterTitle);
            readIndicator = itemView.findViewById(R.id.readIndicator);
        }
    }
}
