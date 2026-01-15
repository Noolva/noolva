# Assets Directory

This directory contains assets that will be uploaded to S3 during initial setup.

## Structure

- `assets_manifest.json` - JSON file listing all assets to be uploaded
- Asset files (images, icons, etc.)

## Assets Manifest Format

The `assets_manifest.json` file should contain:

```json
{
  "version": "1.0.0",
  "created_at": "2025-01-01T00:00:00Z",
  "description": "Asset manifest description",
  "assets": [
    {
      "file_name": "logo.png",
      "original_name": "logo.png",
      "mime_type": "image/png",
      "is_public": true,
      "description": "Asset description"
    }
  ]
}
```

### Asset Entry Fields

- `file_name`: Name of the file in this directory
- `original_name`: Original filename (can be same as file_name)
- `mime_type`: MIME type of the file (e.g., "image/png", "image/jpeg")
- `is_public`: Boolean indicating if asset should be publicly accessible
- `description`: Optional description of the asset

## Upload Process

During CLI setup, if S3 is configured:
1. The manifest file is read
2. Each asset listed is uploaded to S3 at `assets/{file_name}`
3. Asset metadata is inserted into the `assets` table
4. Public assets get a public URL, private assets require authentication

## Adding New Assets

1. Add the asset file to this directory
2. Add an entry to `assets_manifest.json`
3. Run setup or manually upload using the S3 service
