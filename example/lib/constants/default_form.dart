Map<String, dynamic> defaultForm() {
  return {
    "type": "single",
    "title": "Comprehensive Components Form",
    "components": [
      {
        "type": "textfield",
        "key": "welcome",
        "label": "Welcome to Dynamic Builder",
        "placeholder": "This form demonstrates all available components.",
        "disabled": true
      },
      {
        "type": "textfield",
        "key": "text_input",
        "label": "Text Input",
        "description": "Standard text input field",
        "placeholder": "Enter some text"
      },
      {
        "type": "select",
        "key": "select_input",
        "label": "Select Dropdown",
        "description": "Choose an option from the list",
        "options": [
          {"label": "Option A", "value": "A"},
          {"label": "Option B", "value": "B"}
        ]
      },
      {
        "type": "radio",
        "key": "radio_input",
        "label": "Radio Buttons",
        "description": "Select exactly one option",
        "options": [
          {"label": "Choice 1", "value": "1"},
          {"label": "Choice 2", "value": "2"}
        ]
      },
      {
        "type": "checkbox",
        "key": "checkbox_input",
        "label": "Checkbox",
        "description": "Check to confirm"
      },
      {
        "type": "selectboxes",
        "key": "selectboxes_input",
        "label": "Select Boxes",
        "description": "Select multiple options",
        "options": [
          {"label": "Item X", "value": "X"},
          {"label": "Item Y", "value": "Y"}
        ]
      },
      {
        "type": "tags",
        "key": "tags_input",
        "label": "Tags Field",
        "description": "Type and press enter to add tags",
        "placeholder": "Add tags..."
      },
      {
        "type": "datetime",
        "key": "date_input",
        "label": "Date & Time Picker",
        "description": "Select a date",
        "enableDate": true,
        "enableTime": true
      },
      {
        "type": "location",
        "key": "location_input",
        "label": "Location Detection",
        "description": "Detect your current GPS coordinates"
      },
      {
        "type": "file",
        "key": "file_upload",
        "label": "File Upload",
        "description": "Upload a document or photo",
        "uploadUrl": "https://api.escuelajs.co/api/v1/files/upload"
      },
      {
        "type": "camera",
        "key": "camera_input",
        "label": "Camera Field",
        "description": "Take a photo directly from browser",
        "uploadUrl": "https://api.escuelajs.co/api/v1/files/upload"
      },
      {
        "type": "signature",
        "key": "signature_input",
        "label": "Signature Pad",
        "description": "Sign using your mouse or touch screen"
      },
      {
        "type": "panel",
        "key": "panel_input",
        "label": "Collapsible Panel",
        "description": "This panel groups related fields",
        "components": [
          {
            "type": "textfield",
            "key": "panel_text",
            "label": "Text inside Panel",
            "placeholder": "Nested text field"
          }
        ]
      },
      {
        "type": "select",
        "key": "api_test",
        "label": "Test API Data Source",
        "description": "Values fetched from remote API",
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
        "type": "textfield",
        "key": "cond_trigger",
        "label": "Conditional Trigger",
        "description": "Type '1' to show the conditional field below",
        "placeholder": "Type '1' here"
      },
      {
        "type": "textfield",
        "key": "cond_target",
        "label": "Conditional Field (Target)",
        "description": "Shows because you typed '1'",
        "conditional": {
          "show": true,
          "conditions": [
            {
              "whenSource": "api",
              "whenApi": {
                "url":
                    "https://potterapi-fedeperin.vercel.app/en/books?index=1",
                "method": "GET",
                "valuePath": "index"
              },
              "operator": "eq",
              "valueSource": "field",
              "valueFieldKey": "cond_trigger",
              "logicWithPrevious": "and"
            }
          ]
        }
      }
    ]
  };
}
