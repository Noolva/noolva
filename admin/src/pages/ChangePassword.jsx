import React, { useState } from 'react';
import { Card, Form, Input, Button, Typography, App } from 'antd';
import { LockOutlined } from '@ant-design/icons';
import { api } from '../utils/api';
import { useAuth } from '../contexts/AuthContext';
import ErrorModal from '../components/ErrorModal';

const { Title, Text } = Typography;

export default function ChangePassword() {
  const { message: messageApi } = App.useApp();
  const { user } = useAuth();
  const [form] = Form.useForm();
  const [loading, setLoading] = useState(false);
  const [errorModalVisible, setErrorModalVisible] = useState(false);
  const [errorDetails, setErrorDetails] = useState(null);

  const onFinish = async (values) => {
    setLoading(true);
    try {
      await api.changeMyPassword(values.current_password, values.new_password);
      messageApi.success('Password changed successfully');
      form.resetFields();
    } catch (err) {
      setErrorDetails(err);
      setErrorModalVisible(true);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div style={{ maxWidth: 480, margin: '0 auto' }}>
      <Card>
        <Title level={4} style={{ marginTop: 0 }}>
          Change password
        </Title>
        {user?.username ? (
          <Text type="secondary" style={{ display: 'block', marginBottom: 16 }}>
            Signed in as <Text strong>{user.username}</Text>
          </Text>
        ) : null}
        <Text type="secondary" style={{ display: 'block', marginBottom: 20 }}>
          Enter your current password, then choose a new one (at least 5 characters).
        </Text>
        <Form form={form} layout="vertical" onFinish={onFinish} requiredMark="optional">
          <Form.Item
            label="Current password"
            name="current_password"
            rules={[{ required: true, message: 'Enter your current password' }]}
          >
            <Input.Password prefix={<LockOutlined />} placeholder="Current password" autoComplete="current-password" />
          </Form.Item>
          <Form.Item
            label="New password"
            name="new_password"
            rules={[
              { required: true, message: 'Enter a new password' },
              { min: 5, message: 'Use at least 5 characters' },
            ]}
          >
            <Input.Password prefix={<LockOutlined />} placeholder="New password" autoComplete="new-password" />
          </Form.Item>
          <Form.Item
            label="Confirm new password"
            name="confirm_password"
            dependencies={['new_password']}
            rules={[
              { required: true, message: 'Confirm your new password' },
              ({ getFieldValue }) => ({
                validator(_, value) {
                  if (!value || getFieldValue('new_password') === value) {
                    return Promise.resolve();
                  }
                  return Promise.reject(new Error('Passwords do not match'));
                },
              }),
            ]}
          >
            <Input.Password prefix={<LockOutlined />} placeholder="Confirm new password" autoComplete="new-password" />
          </Form.Item>
          <Form.Item style={{ marginBottom: 0 }}>
            <Button type="primary" htmlType="submit" loading={loading}>
              Update password
            </Button>
          </Form.Item>
        </Form>
      </Card>
      <ErrorModal
        visible={errorModalVisible}
        onClose={() => {
          setErrorModalVisible(false);
          setErrorDetails(null);
        }}
        error={errorDetails}
      />
    </div>
  );
}
