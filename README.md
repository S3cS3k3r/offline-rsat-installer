# Offline RSAT Installer for Windows

[Русская версия / Russian version](README.ru.md)

PowerShell script to install RSAT offline on Windows using a Language and Optional Features ISO.

## What this script does

This script:

- downloads a Windows Language and Optional Features ISO
- mounts the ISO automatically
- finds the correct package source path
- installs all missing RSAT components offline
- avoids using WSUS and Windows Update during installation
- dismounts the ISO after installation
- deletes the downloaded ISO file

## Why use it

This is useful when:

- RSAT installation fails through WSUS
- Windows Update is restricted by corporate policy
- you need to install RSAT offline
- you are working on VDI or hardened enterprise workstations

## Important

You must choose the ISO download link according to the target Windows build/version.

Before running the script, replace the `$IsoUrl` value with the correct **Language and Optional Features ISO** URL for the Windows version you are targeting.

## Usage

1. Open PowerShell as Administrator
2. Update the ISO URL inside the script
3. Run the script

## Result

The script installs all missing RSAT components available through Windows Features on Demand.

After installation, you can open Active Directory Users and Computers with:

```powershell
dsa.msc

## Keywords

RSAT, offline RSAT installer, PowerShell, Windows 11, Windows 10, Features on Demand, FoD, WSUS, offline install
