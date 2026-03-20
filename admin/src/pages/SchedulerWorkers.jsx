import React, { useState, useEffect } from 'react';
import { Card, Table, Tag, Button, Space, message } from 'antd';
import { ReloadOutlined, TeamOutlined } from '@ant-design/icons';
import { api } from '../utils/api';

const SchedulerWorkers = () => {
    const [workers, setWorkers] = useState([]);
    const [loading, setLoading] = useState(false);

    const fetchWorkers = async () => {
        try {
            setLoading(true);
            const data = await api.getWorkers();
            setWorkers(Array.isArray(data) ? data : []);
        } catch (error) {
            message.error('Failed to load workers: ' + (error.message || 'Unknown error'));
            setWorkers([]);
        } finally {
            setLoading(false);
        }
    };

    useEffect(() => {
        fetchWorkers();
    }, []);

    const columns = [
        { title: 'Worker ID', dataIndex: 'worker_id', key: 'worker_id', ellipsis: true },
        { title: 'Type', dataIndex: 'worker_type', key: 'worker_type', render: (t) => <Tag>{t}</Tag> },
        { title: 'Hostname', dataIndex: 'hostname', key: 'hostname' },
        { title: 'Status', dataIndex: 'status', key: 'status', render: (s) => <Tag color={s === 'idle' ? 'green' : s === 'busy' ? 'blue' : 'default'}>{s}</Tag> },
        { title: 'Max concurrency', dataIndex: 'max_concurrency', key: 'max_concurrency', width: 120 },
        { title: 'Running jobs', dataIndex: 'running_jobs', key: 'running_jobs', width: 110 },
        { title: 'Last heartbeat', dataIndex: 'last_heartbeat', key: 'last_heartbeat' },
        { title: 'Registered at', dataIndex: 'registered_at', key: 'registered_at' },
    ];

    return (
        <Card
            title={
                <Space>
                    <TeamOutlined />
                    Scheduler Workers
                </Space>
            }
            extra={
                <Button type="primary" icon={<ReloadOutlined />} onClick={fetchWorkers} loading={loading}>
                    Refresh
                </Button>
            }
        >
            <Table
                rowKey="worker_id"
                columns={columns}
                dataSource={workers}
                loading={loading}
                pagination={{ pageSize: 20 }}
                size="small"
            />
        </Card>
    );
};

export default SchedulerWorkers;
