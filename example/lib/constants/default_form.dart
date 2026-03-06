Map<String, dynamic> defaultForm() {
  return {
    "type": "single",
    "title": "Welcome",
    "components": [
      {
        "type": "textfield",
        "key": "welcome",
        "label": "Welcome to Dynamic Builder",
        "placeholder": "Paste your custom JSON to begin!",
        "disabled": true
      },
      {
        "type": "select",
        "key": "api_test",
        "label": "Test API Data Source",
        "dataSource": {
          "type": "api",
          "api": {
            "url": "https://potterapi-fedeperin.vercel.app/en/books",
            "method": "GET",
            "labelPath": "title",
            "valuePath": "index"
          }
        }
      },
      {
        "type": "select",
        "key": "db_test",
        "label": "Test DB Data Source",
        "dataSource": {
          "type": "database",
          "database": {
            "query": "SELECT id, name FROM items",
            "labelPath": "name",
            "valuePath": "id"
          }
        }
      },

      // ────────────────────────────────────────────────
      // uploadType: other — simpan URL saja (location)
      // Response: { originalname, filename, location }
      // ────────────────────────────────────────────────
      {
        "id": "comp_test_other_url",
        "type": "file",
        "key": "file_other_url",
        "label": "File (uploadType: other — URL only)",
        "description":
            "responseFileUrlPath: location → form menyimpan URL string saja",
        "uploadTiming": "immediate",
        "uploadUrl": "https://api.escuelajs.co/api/v1/files/upload",
        "uploadType": "other",
        "otherUploadConfig": {
          "method": "POST",
          "headers": [],
          "responseFileUrlPath": "location",
          "fileFieldName": "file",
          "extraBodyFields": []
        },
        "accept": ".pdf"
      },

      // ────────────────────────────────────────────────
      // uploadType: other — simpan full response object
      // Response: { originalname, filename, location }
      // ────────────────────────────────────────────────
      {
        "id": "comp_test_other_full",
        "type": "file",
        "key": "file_other_full",
        "label": "File (uploadType: other — full object)",
        "description":
            "responseFileUrlPath kosong → simpan seluruh object {originalname, filename, location}",
        "uploadTiming": "immediate",
        "uploadUrl": "https://api.escuelajs.co/api/v1/files/upload",
        "uploadType": "other",
        "otherUploadConfig": {
          "method": "POST",
          "headers": [],
          "responseFileUrlPath": "",
          "fileFieldName": "file",
          "extraBodyFields": []
        },
        "accept": ".pdf"
      },

      // ────────────────────────────────────────────────
      // uploadType: other — multiple files
      // ────────────────────────────────────────────────
      {
        "id": "comp_test_other_multi",
        "type": "file",
        "key": "file_other_multi",
        "label": "File (uploadType: other — multiple)",
        "description": "Multiple files, tiap file → seluruh response object",
        "uploadTiming": "immediate",
        "uploadUrl": "https://api.escuelajs.co/api/v1/files/upload",
        "uploadType": "other",
        "multiple": true,
        "otherUploadConfig": {
          "method": "POST",
          "headers": [],
          "responseFileUrlPath": "",
          "fileFieldName": "file",
          "extraBodyFields": []
        },
        "accept": ".pdf"
      }
    ]
  };
}
