package com.linovelib.reader.database;

import android.content.ContentValues;
import android.content.Context;
import android.database.Cursor;
import android.database.sqlite.SQLiteDatabase;
import android.database.sqlite.SQLiteOpenHelper;

public class DatabaseHelper extends SQLiteOpenHelper {
    private static final String DATABASE_NAME = "linovelib_reader.db";
    private static final int DATABASE_VERSION = 1;

    // Favorites table
    public static final String TABLE_FAVORITES = "favorites";
    public static final String COL_NOVEL_ID = "novel_id";
    public static final String COL_TITLE = "title";
    public static final String COL_AUTHOR = "author";
    public static final String COL_COVER_URL = "cover_url";
    public static final String COL_ADDED_TIME = "added_time";

    // Reading history table
    public static final String TABLE_READING_HISTORY = "reading_history";
    public static final String COL_ID = "id";
    public static final String COL_CHAPTER_ID = "chapter_id";
    public static final String COL_CHAPTER_TITLE = "chapter_title";
    public static final String COL_LAST_READ_TIME = "last_read_time";
    public static final String COL_SCROLL_POSITION = "scroll_position";

    // Chapter cache table
    public static final String TABLE_CHAPTER_CACHE = "chapter_cache";
    public static final String COL_CHAPTER_URL = "chapter_url";
    public static final String COL_CONTENT = "content";
    public static final String COL_CACHED_TIME = "cached_time";

    private static DatabaseHelper instance;

    public static synchronized DatabaseHelper getInstance(Context context) {
        if (instance == null) {
            instance = new DatabaseHelper(context.getApplicationContext());
        }
        return instance;
    }

    private DatabaseHelper(Context context) {
        super(context, DATABASE_NAME, null, DATABASE_VERSION);
    }

    @Override
    public void onCreate(SQLiteDatabase db) {
        // Create favorites table
        String createFavorites = "CREATE TABLE " + TABLE_FAVORITES + " (" +
                COL_NOVEL_ID + " TEXT PRIMARY KEY," +
                COL_TITLE + " TEXT," +
                COL_AUTHOR + " TEXT," +
                COL_COVER_URL + " TEXT," +
                COL_ADDED_TIME + " INTEGER)";
        db.execSQL(createFavorites);

        // Create reading history table
        String createHistory = "CREATE TABLE " + TABLE_READING_HISTORY + " (" +
                COL_ID + " INTEGER PRIMARY KEY AUTOINCREMENT," +
                COL_NOVEL_ID + " TEXT," +
                COL_CHAPTER_ID + " TEXT," +
                COL_CHAPTER_TITLE + " TEXT," +
                COL_LAST_READ_TIME + " INTEGER," +
                COL_SCROLL_POSITION + " INTEGER)";
        db.execSQL(createHistory);

        // Create chapter cache table
        String createCache = "CREATE TABLE " + TABLE_CHAPTER_CACHE + " (" +
                COL_CHAPTER_URL + " TEXT PRIMARY KEY," +
                COL_CHAPTER_TITLE + " TEXT," +
                COL_CONTENT + " TEXT," +
                COL_CACHED_TIME + " INTEGER)";
        db.execSQL(createCache);
    }

    @Override
    public void onUpgrade(SQLiteDatabase db, int oldVersion, int newVersion) {
        db.execSQL("DROP TABLE IF EXISTS " + TABLE_FAVORITES);
        db.execSQL("DROP TABLE IF EXISTS " + TABLE_READING_HISTORY);
        db.execSQL("DROP TABLE IF EXISTS " + TABLE_CHAPTER_CACHE);
        onCreate(db);
    }
}
