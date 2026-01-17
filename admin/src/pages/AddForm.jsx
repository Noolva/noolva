import React from 'react';
import { Form, Button } from 'antd';
import formPageView from "../views/formPageView.json"
import { useTheme } from '../contexts/ThemeContext';
import { viewComponentRegistry } from '../components/ViewComponents';
import { getComponentKey } from '../components/ViewComponents/vcTypes';

const AddForm = () => {
    const { isDark, color } = useTheme();

    const background = isDark ? '#1f1f1f' : '#fff';
    const textColor = isDark ? '#fff' : '#000';
    const [form] = Form.useForm();
    
    const onFinish = (values) => {
        console.log('Form values:', values);
    };
    
    // Get components to render from view
    const componentsToRender = formPageView?.rows || formPageView || [];

    const renderComponent = (component) => {
        const { type, input_values = {}, children = [], uuid, id } = component;
        const key = getComponentKey(component);

        // Handle button separately
        if (type === "button") {
            return (
                <Form.Item key={key}>
                    <Button type="primary" htmlType="submit">
                        {input_values.label || "Submit"}
                    </Button>
                </Form.Item>
            );
        }

        // Try registry-based render
        if (viewComponentRegistry[type]) {
            const Cmp = viewComponentRegistry[type];
            const hasChildren = children && children.length > 0;
            const renderedChildren = hasChildren ? children.map(renderComponent) : null;
            
            return (
                <Cmp key={key} component={component}>
                    {renderedChildren}
                </Cmp>
            );
        }

        return null;
    };

    return (
        <>
            <div style={{ padding: '5px 10px 4px 16px', background: background }}>
                <h3 style={{ padding: 0 }}>{formPageView.view_title}</h3>
                <Form
                    form={form}
                    onFinish={onFinish}
                    layout="vertical"
                >
                    {componentsToRender.map(renderComponent)}
                </Form>
                import,export,filter,grouping,columns,save current search(global_me_only)
            </div>
        </>

    );
};

export default AddForm;
