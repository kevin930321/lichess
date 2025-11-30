package com.linovelib.reader.database;

import android.content.ContentValues;
import android.content.Context;
import android.database.Cursor;
import android.database.sqlite.SQLiteDatabase;

public class ReadingHistoryDao {
    private final DatabaseHelper dbHelper;

    public ReadingHistoryDao(Context context) {
        this.dbHelper = DatabaseHelper.getInstance(context);
    }

    /**
     * 保存閱讀進度
     */
    public boolean saveReadingProgress(String novelId, String chapterId, String chapterTitle, int scrollPosition) {
        SQLiteDatabase db = dbHelper.getWritableDatabase();

        // 先刪除舊記錄
        db.delete(DatabaseHelper.TABLE_READING_HISTORY,
                DatabaseHelper.COL_NOVEL_ID + " = ?",
                new String[]{novelId});

        // 插入新記錄
        ContentValues values = new ContentValues();
        values.put(DatabaseHelper.COL_NOVEL_ID, novelId);
        values.put(DatabaseHelper.COL_CHAPTER_ID, chapterId);
        values.put(DatabaseHelper.COL_CHAPTER_TITLE, chapterTitle);
        values.put(DatabaseHelper.COL_LAST_READ_TIME, System.currentTimeMillis());
        values.put(DatabaseHelper.COL_SCROLL_POSITION, scrollPosition);

        long result = db.insert(DatabaseHelper.TABLE_READING_HISTORY, null, values);
        return result != -1;
    }

    /**
     * 獲取閱讀進度
     */
    public ReadingProgress getReadingProgress(String novelId) {
        SQLiteDatabase db = dbHelper.getReadableDatabase();

        Cursor cursor = db.query(DatabaseHelper.TABLE_READING_HISTORY,
                null,
                DatabaseHelper.COL_NOVEL_ID + " = ?",
                new String[]{novelId},
                null, null, null);

        ReadingProgress progress = null;
        
        if (cursor != null && cursor.moveToFirst()) {
            progress = new ReadingProgress();
            progress.novelId = novelId;
            progress.chapterId = cursor.getString(cursor.getColumnIndexOrThrow(DatabaseHelper.COL_CHAPTER_ID));
            progress.chapterTitle = cursor.getString(cursor.getColumnIndexOrThrow(DatabaseHelper.COL_CHAPTER_TITLE));
            progress.scrollPosition = cursor.getInt(cursor.getColumnIndexOrThrow(DatabaseHelper.COL_SCROLL_POSITION));
            progress.lastReadTime = cursor.getLong(cursor.getColumnIndexOrThrow(DatabaseHelper.COL_LAST_READ_TIME));
        }

        if (cursor != null) {
            cursor.close();
        }

        return progress;
    }

    /**
     * 清除歷史記錄
     */
    public boolean clearHistory() {
        SQLiteDatabase db = dbHelper.getWritableDatabase();
        int result = db.delete(DatabaseHelper.TABLE_READING_HISTORY, null, null);
        return result > 0;
    }

    /**
     * 閱讀進度數據類
     */
    public static class ReadingProgress {
        public String novelId;
        public String chapterId;
        public String chapterTitle;
        public int scrollPosition;
        public long lastReadTime;
    }
}
