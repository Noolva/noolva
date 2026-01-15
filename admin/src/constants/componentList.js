// componentList.js

export const componentList = [
    {
        type: "label",
        component_name: "Label",
        description: "Display a heading or paragraph",
        possible_inputs: { default_value: "string" }
    },
    {
        type: "text",
        component_name: "Text",
        description: "Basic text input field",
        possible_inputs: { default_value: "string", validation_type: "autonumber,phone,email,number,paragraph", name: "string", label: "string", place_holder: "string" }
    },
    {
        type: "row",
        component_name: "Row",
        description: "A horizontal layout row",
        possible_inputs: { gutter: "16,24" }
    },
    {
        type: "column",
        component_name: "Column",
        description: "A column inside a row",
        possible_inputs: { span: "1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24" },
    },
    {
        type: "form",
        component_name: "Form",
        description: "A container for form items",
        possible_inputs: { layout: "horizontal,vertical,inline" }

    },
    {
        type: "button",
        component_name: "Button",
        description: "Button element",
        possible_inputs: { name: "string", label: "string", type: "button,submit,reset" }
    },
    {
        type: "table",
        component_name: "Table",
        description: "Table element",
        possible_inputs: { name: "string", label: "string", has_checkbox: "boolean" }
    }
];
