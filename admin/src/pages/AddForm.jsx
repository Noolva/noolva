import React from 'react';
import { Form, Input, Button, Card } from 'antd';
import DynamicRenderer from '../components/DynamicViewRenderer';
import formPageView from "../views/formPageView.json"
import { useTheme } from '../contexts/ThemeContext';
const AddForm = () => {
    const { isDark, color } = useTheme();

    const background = isDark ? '#1f1f1f' : '#fff';
    const textColor = isDark ? '#fff' : '#000';
    const onFinish = (values) => {
        console.log('Form values:', values);
    };

    return (
        <>
            <div style={{ padding: '5px 10px 4px 16px', background: background }}>
                <h3 style={{ padding: 0 }}>{formPageView.view_title}</h3>
                <DynamicRenderer view={formPageView} />
                import,export,filter,grouping,columns,save current search(global_me_only)
            </div>
        </>

    );
};

export default AddForm;
