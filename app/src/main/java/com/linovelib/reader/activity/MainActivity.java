package com.linovelib.reader.activity;

import android.os.Bundle;
import androidx.appcompat.app.AppCompatActivity;
import androidx.appcompat.widget.Toolbar;
import androidx.fragment.app.Fragment;
import androidx.viewpager2.adapter.FragmentStateAdapter;
import androidx.viewpager2.widget.ViewPager2;

import com.google.android.material.tabs.TabLayout;
import com.google.android.material.tabs.TabLayoutMediator;
import com.linovelib.reader.R;
import com.linovelib.reader.fragment.FavoritesFragment;
import com.linovelib.reader.fragment.RecommendFragment;

public class MainActivity extends AppCompatActivity {

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);

        Toolbar toolbar = findViewById(R.id.toolbar);
        setSupportActionBar(toolbar);

        ViewPager2 viewPager = findViewById(R.id.viewPager);
        TabLayout tabLayout = findViewById(R.id.tabLayout);

        // Setup ViewPager with fragments
        FragmentStateAdapter pagerAdapter = new FragmentStateAdapter(this) {
            @Override
            public Fragment createFragment(int position) {
                if (position == 0) {
                    return new RecommendFragment();
                } else {
                    return new FavoritesFragment();
                }
            }

            @Override
            public int getItemCount() {
                return 2;
            }
        };

        viewPager.setAdapter(pagerAdapter);

        // Connect TabLayout with ViewPager2
        new TabLayoutMediator(tabLayout, viewPager, (tab, position) -> {
            if (position == 0) {
                tab.setText(R.string.tab_recommend);
            } else {
                tab.setText(R.string.tab_favorites);
            }
        }).attach();
    }
}
