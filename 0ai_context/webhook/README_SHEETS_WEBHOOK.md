# Google Sheets Webhook Deployment Guide

Follow these steps to deploy the crowdsource telemetry & video metadata vault webhook.

## 1. Create Google Spreadsheet
1. Open [Google Sheets](https://sheets.new) and create a new blank spreadsheet.
2. Name it `NRA_Video_Uniquifier_Telemetry`.

## 2. Install Apps Script
1. In the spreadsheet menu, navigate to **Extensions** > **Apps Script**.
2. Erase any code inside `Code.gs` and replace it with the code from `google_sheets_webhook.js`.
3. Click the disk icon to **Save** (`Ctrl + S`).

## 3. Deploy as Web App
1. Click the blue **Deploy** button (top right) > **New deployment**.
2. Select type: **Web app** (click gear icon next to "Select type").
3. Configuration:
   - **Description**: `NRA Video Uniquifier Webhook v1`
   - **Execute as**: `Me (your email)`
   - **Who has access**: `Anyone` *(Crucial for anonymous client POST requests)*
4. Click **Deploy**. Authorize permissions if prompted by Google.
5. Copy the generated **Web app URL** (e.g., `https://script.google.com/macros/s/AKfycb.../exec`).

## 4. Configure App Endpoint
Set the webhook URL in the app via `UserInterestService.setWebhookUrl(url)` or store it in SharedPreferences key `nra_telemetry_webhook_url`.

## Sheet Architecture
The script automatically provisions two sheets with styled headers:
1. `User_Interest_Telemetry`: Records search queries, chip filter selections, article opens, and translation switches.
2. `Video_Metadata_Vault`: Stores crowdsourced titles, descriptions, keyword tags, technical specs, and seasonal lead windows.
