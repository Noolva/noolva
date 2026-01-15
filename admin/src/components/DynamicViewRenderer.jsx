import React from "react";
import { Row, Col, Typography, Input, Form, Button } from "antd";
import Table from './ViewComponents/Table'
const { Paragraph } = Typography;

const validationRules = {
    phone: [{ pattern: /^[0-9]{10}$/, message: "Invalid phone number" }],
    email: [{ type: "email", message: "Invalid email" }],
    number: [{ pattern: /^[0-9]+$/, message: "Only numbers allowed" }],
};

const DynamicRenderer = ({ view }) => {
    const renderComponent = (component) => {
        const { type, input_values = {}, children = [], uuid, id } = component;
        const key = uuid || id; // fallback if uuid not provided

        switch (type) {
            case "row":
                return (
                    <Row
                        key={key}
                        gutter={parseInt(input_values.gutter) || 0}
                        style={{ marginBottom: 16 }}
                    >
                        {children && children.map(renderComponent)}
                    </Row>
                );

            case "column":
                return (
                    <Col key={key} span={parseInt(input_values.span) || 24}>
                        {children && children.map(renderComponent)}
                    </Col>
                );

            case "label":
                return (
                    <Paragraph key={key} strong>
                        {input_values.default_value}
                    </Paragraph>
                );

            case "text":
                return (
                    <Form.Item
                        key={key}
                        name={input_values.name}
                        label={input_values.label}
                        rules={validationRules[input_values.validation_type] || []}
                    >
                        <Input
                            placeholder={input_values.place_holder}
                            defaultValue={input_values.default_value}
                        />
                    </Form.Item>
                );

            case "button":
                return (
                    <Form.Item key={key}>
                        <Button type="primary" htmlType="submit">
                            {input_values.label || "Submit"}
                        </Button>
                    </Form.Item>
                );

            case "form":
                return (
                    <Form
                        key={key}
                        layout={input_values.layout || "vertical"}
                        onFinish={(values) => console.log("Form Submitted:", values)}
                    >
                        {children && children.map(renderComponent)}
                    </Form>
                );
            case "table":
                return (
                    <Table
                        key={key}
                        component={component}
                    // layout={input_values.layout || "vertical"}
                    // onFinish={(values) => console.log("Form Submitted:", values)}
                    >
                        {children && children.map(renderComponent)}
                    </Table>
                );

            default:
                return null;
        }
    };

    // If full view object is passed, use `rows`; else assume array of components
    const componentsToRender = view?.rows || view;

    return <>{componentsToRender.map(renderComponent)}</>;
};

export default DynamicRenderer;