# Play Store Submission Checklist

## Before You Start
- [ ] Google Play Developer account registered ($25 one-time fee)
- [ ] Identity verification completed (24-48 hours processing)
- [ ] Two-factor authentication enabled on Google account

## Assets Required
- [ ] App icon (512×512 PNG for Play Store, adaptive icon for in-app)  
  → See `docs/icon_generation_guide.md`
- [ ] Feature graphic (1024×500 PNG for Play Store header)
- [ ] Minimum 2 phone screenshots (1080×1920 portrait)
- [ ] Privacy policy URL (hosted publicly)  
  → Content ready in `docs/privacy_policy.md` and `docs/privacy_policy.html`

## Play Console Setup
- [ ] Create app: NRA Video Uniquifier
- [ ] Default language: English (US)
- [ ] Category: Tools (or Video Players & Editors)
- [ ] Free or Paid: Free

## Store Listing
- [ ] Title: NRA Video Uniquifier (20/30 chars)
- [ ] Short description: (66/80 chars from `docs/play_store_metadata/listing_details.md:9`)
- [ ] Full description: (2694/4000 chars from `docs/play_store_metadata/listing_details.md`)
- [ ] Screenshots: 2+ uploaded
- [ ] Feature graphic: uploaded
- [ ] Icon: 512×512 uploaded

## Data Safety Form
- [ ] Data collected: None
- [ ] Data shared: None
- [ ] Security practices: Data not encrypted in transit (N/A — offline)
- [ ] Data deletion: User can delete via app uninstall

## Content Rating
- [ ] Complete questionnaire
- [ ] Expected rating: Everyone (PEGI 3)
- [ ] User-generated content: No (videos are local user's own)
- [ ] Violence/sexual/profanity: None

## Target Audience
- [ ] Age: 13+ recommended (video processing tool)
- [ ] Not designed for children

## Release
- [ ] Upload `build/app/outputs/bundle/release/app-release.aab` to Internal Testing first
- [ ] Add 5-10 internal testers (email addresses)
- [ ] Release notes copied from `docs/play_store_metadata/release_notes_en_US.txt`
- [ ] Submit for review
- [ ] Wait 24-72 hours for review
- [ ] If approved, promote to Production after 3-7 days of internal testing shows no crashes

## Post-Upload Monitoring (First 14 Days)
- [ ] H+1: Monitor Android Vitals for crash rate
- [ ] H+3: If crash rate > 1%, ship patch defaulting hardware accel OFF
- [ ] H+7: Read user feedback
- [ ] H+14: Promote to Production if stable
