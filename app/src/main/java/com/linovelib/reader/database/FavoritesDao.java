package com.linovelib.reader.database;

import android.content.ContentValues;
import android.content.Context;
import android.database.Cursor;
import android.database.sqlite.SQLiteDatabase;

import com.linovelib.reader.model.Novel;

import java.util.ArrayList;
import java.util.List;

public class FavoritesDao {
    private final DatabaseHelper dbHelper;

    public FavoritesDao(Context context) {
        this.dbHelper = DatabaseHelper.getInstance(context);
    }

    /**
     * 添加收藏
     */
    public boolean addFavorite(Novel novel) {
        SQLiteDatabase db = dbHelper.getWritableDatabase();
        
        ContentValues values = new ContentValues();
        values.put(DatabaseHelper.COL_NOVEL_ID, novel.getNovelId());
        values.put(DatabaseHelper.COL_TITLE, novel.getTitle());
        values.put(DatabaseHelper.COL_AUTHOR, novel.getAuthor());
        values.put(DatabaseHelper.COL_COVER_URL, novel.getCoverUrl());
        values.put(DatabaseHelper.COL_ADDED_TIME, System.currentTimeMillis());

        long result = db.insert(DatabaseHelper.TABLE_FAVORITES, null, values);
        return result != -1;
    }

    /**
     * 移除收藏
     */
    public boolean removeFavorite(String novelId) {
        SQLiteDatabase db = dbHelper.getWritableDatabase();
        
        int result = db.delete(DatabaseHelper.TABLE_FAVORITES,
                DatabaseHelper.COL_NOVEL_ID + " = ?",
                new String[]{novelId});
        
        return result > 0;
    }

    /**
     * 獲取所有收藏
     */
    public List<Novel> getAllFavorites() {
        List<Novel> favorites = new ArrayList<>();
        SQLiteDatabase db = dbHelper.getReadableDatabase();

        Cursor cursor = db.query(DatabaseHelper.TABLE_FAVORITES,
                null, null, null, null, null,
                DatabaseHelper.COL_ADDED_TIME + " DESC");

        if (cursor != null) {
            while (cursor.moveToNext()) {
                Novel novel = new Novel();
                novel.setNovelId(cursor.getString(cursor.getColumnIndexOrThrow(DatabaseHelper.COL_NOVEL_ID)));
                novel.setTitle(cursor.getString(cursor.getColumnIndexOrThrow(DatabaseHelper.COL_TITLE)));
                novel.setAuthor(cursor.getString(cursor.getColumnIndexOrThrow(DatabaseHelper.COL_AUTHOR)));
                novel.setCoverUrl(cursor.getString(cursor.getColumnIndexOrThrow(DatabaseHelper.COL_COVER_URL)));
                favorites.add(novel);
            }
            cursor.close();
        }

        return favorites;
    }

    /**
     * 檢查是否已收藏
     */
    public boolean isFavorite(String novelId) {
        SQLiteDatabase db = dbHelper.getReadableDatabase();

        Cursor cursor = db.query(DatabaseHelper.TABLE_FAVORITES,
                new String[]{DatabaseHelper.COL_NOVEL_ID},
                DatabaseHelper.COL_NOVEL_ID + " = ?",
                new String[]{novelId},
                null, null, null);

        boolean exists = cursor != null && cursor.getCount() > 0;
        
        if (cursor != null) {
            cursor.close();
        }

        return exists;
    }
}
