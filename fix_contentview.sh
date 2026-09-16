#!/bin/bash
cat << 'PATCH' > contentview.patch
--- Sources/DeskBar/Launchpick/ContentView.swift
+++ Sources/DeskBar/Launchpick/ContentView.swift
@@ -113,8 +113,6 @@
                 Spacer()
             }
         }
-        .background(VisualEffectBackground())
-        .clipShape(RoundedRectangle(cornerRadius: 12))
         .onChange(of: state.searchText) { _ in
             state.selectedIndex = 0
         }
PATCH
patch -p0 < contentview.patch
