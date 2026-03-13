#!/data/data/com.termux/files/usr/bin/bash

WORKSPACE="$HOME/.apk-forge/workspace"

create_project() {

read -p "Project name: " name

mkdir -p "$WORKSPACE/$name"

echo "package com.apkforge.app;

public class Main {
public static void main(String[] args) {
System.out.println("Hello APK Forge");
}
}" > "$WORKSPACE/$name/Main.java"

echo "Project created:"
echo "$WORKSPACE/$name"

}
