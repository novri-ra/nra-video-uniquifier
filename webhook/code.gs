/**
 * Google Apps Script - Microstock & Video Telemetry Webhook
 * Handles POST requests from NRA Video Uniquifier.
 * Routes telemetry events and metadata vault payloads to separate sheets.
 */

function doPost(e) {
  var lock = LockService.getScriptLock();
  lock.tryLock(10000);

  try {
    if (!e || !e.postData || !e.postData.contents) {
      return ContentService.createTextOutput(JSON.stringify({
        status: "error",
        message: "Empty payload"
      })).setMimeType(ContentService.MimeType.JSON);
    }

    var payload = JSON.parse(e.postData.contents);
    var ss = SpreadsheetApp.getActiveSpreadsheet();
    var now = new Date();

    if (payload.type === "video_metadata_vault") {
      recordVideoMetadataVault(ss, payload, now);
    } else {
      recordUserInterestTelemetry(ss, payload, now);
    }

    return ContentService.createTextOutput(JSON.stringify({
      status: "success",
      timestamp: now.toISOString()
    })).setMimeType(ContentService.MimeType.JSON);

  } catch (err) {
    return ContentService.createTextOutput(JSON.stringify({
      status: "error",
      message: err.toString()
    })).setMimeType(ContentService.MimeType.JSON);

  } finally {
    lock.releaseLock();
  }
}

function recordUserInterestTelemetry(ss, data, timestamp) {
  var sheetName = "User_Interest_Telemetry";
  var sheet = ss.getSheetByName(sheetName) || ss.insertSheet(sheetName);

  if (sheet.getLastRow() === 0) {
    sheet.appendRow([
      "Timestamp",
      "Event Type",
      "Query / Keyword",
      "Article Title",
      "Category",
      "Lang Mode"
    ]);
    sheet.getRange(1, 1, 1, 6).setFontWeight("bold");
  }

  sheet.appendRow([
    timestamp.toISOString(),
    data.eventType || "unknown",
    data.query || data.keyword || "",
    data.articleTitle || "",
    data.category || "",
    data.langMode || "id"
  ]);
}

function recordVideoMetadataVault(ss, data, timestamp) {
  var sheetName = "Video_Metadata_Vault";
  var sheet = ss.getSheetByName(sheetName) || ss.insertSheet(sheetName);

  if (sheet.getLastRow() === 0) {
    sheet.appendRow([
      "Timestamp",
      "Title",
      "Description",
      "Keywords",
      "Platforms",
      "Tech Specs",
      "Category",
      "Lead Window"
    ]);
    sheet.getRange(1, 1, 1, 8).setFontWeight("bold");
  }

  sheet.appendRow([
    timestamp.toISOString(),
    data.title || "",
    data.description || "",
    Array.isArray(data.keywords) ? data.keywords.join(", ") : (data.keywords || ""),
    Array.isArray(data.platforms) ? data.platforms.join(", ") : (data.platforms || ""),
    data.techSpecs || "",
    data.category || "",
    data.leadWindow || ""
  ]);
}
