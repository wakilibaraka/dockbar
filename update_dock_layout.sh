#!/bin/bash
# First, we need to inspect TaskbarContentView.swift to safely write a sed/patch to remove RunningAppTrayView
cat Sources/DeskBar/Views/TaskbarContentView.swift | grep -n "runningAppTrayView"
