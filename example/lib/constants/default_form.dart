Map<String, dynamic> defaultForm() {
  return {
    "type": "single",
    "title": "Comprehensive Components Form",
    "components": [
      {
        "type": "textfield",
        "key": "conditional_trigger",
        "label": "Conditional Trigger",
        "description":
            "Type a book index (e.g., '1') to fetch into the HIDDEN field below",
        "placeholder": "Enter book index"
      },
      {
        "type": "textfield",
        "key": "fetch_target",
        "label": "Hidden Fetch Target",
        "hidden": true,
        "dataSource": {
          "type": "api",
          "api": {
            "url":
                "https://potterapi-fedeperin.vercel.app/en/books?index={{ conditional_trigger }}",
            "method": "GET",
            "valuePath": "title"
          }
        }
      }
    ]
  };
}
