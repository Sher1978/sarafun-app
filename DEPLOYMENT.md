# SaraFun Deployment Guide (app.sarafun.site)

This document explains the standard deployment flow for the SaraFun application to ensure stability and prevent regressions.

## 1. Automated Pipeline (GitHub Actions)

The primary way to deploy the application is by pushing to the `main` branch. This triggers the automated workflow in `.github/workflows/deploy.yml`.

### Deployment Artifacts
- **Target Path**: `build/web/`
- **Sanity Check**: The workflow automatically verifies that `build/web/index.html` exists before proceeding. If the file is missing, the build will fail, and no changes will be pushed to production.

### Hosting (GitHub Pages)
- **Source**: **GitHub Actions** (configured in Repository Settings -> Pages).
- **Custom Domain**: `app.sarafun.site`
- **Enforce HTTPS**: Enabled.

### Hosting (Firebase)
- The app is also mirrored to Firebase Hosting (`sarafun-f9616`) during the same workflow.

## 2. Manual Deployment (Temporary/Emergency)

If the CI/CD pipeline is down, you can build manually:

```powershell
# In project root
flutter build web --release --base-href "/"
```

**WARNING**: Never deploy manually by pushing files directly to a branch if possible. Always use the automated Actions pipeline.

## 3. Configuration Files

- **.github/workflows/deploy.yml**: Core pipeline logic.
- **web/CNAME**: Crucial for GitHub Pages to identify the `app.sarafun.site` subdomain correctly. **Never delete or change this file.**
