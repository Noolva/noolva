import React, { useState, useEffect } from 'react';
import { Card, Table, Tag, Button, Space, message, Select, Modal } from 'antd';
import { ReloadOutlined, UnorderedListOutlined, EyeOutlined } from '@ant-design/icons';
import { api } from '../utils/api';
import { VCJsonViewer } from '../components/ViewComponents/displays/VCJsonViewer';
import dayjs from 'dayjs';
import utc from 'dayjs/plugin/utc';
import timezone from 'dayjs/plugin/timezone';

dayjs.extend(utc);
dayjs.extend(timezone);

const Jobs = () => {
    const [jobs, setJobs] = useState([]);
    const [loading, setLoading] = useState(false);
    const [statusFilter, setStatusFilter] = useState(undefined);
    const [displayConfig, setDisplayConfig] = useState({ timezone: 'Asia/Kolkata', time_format: 'DD/MM/YYYY h:mm A' });
    const [resultModal, setResultModal] = useState({ visible: false, data: null });

    const fetchDisplayConfig = async () => {
        try {
            const cfg = await api.getDisplayConfig();
            setDisplayConfig({ timezone: cfg.timezone || 'Asia/Kolkata', time_format: cfg.time_format || 'DD/MM/YYYY h:mm A' });
        } catch {
            setDisplayConfig({ timezone: 'Asia/Kolkata', time_format: 'DD/MM/YYYY h:mm A' });
        }
    };

    const fetchJobs = async () => {
        try {
            setLoading(true);
            const data = await api.getJobs({ limit: 200, status: statusFilter });
            setJobs(Array.isArray(data) ? data : []);
        } catch (error) {
            message.error('Failed to load jobs: ' + (error.message || 'Unknown error'));
            setJobs([]);
        } finally {
            setLoading(false);
        }
    };

    useEffect(() => {
        fetchDisplayConfig();
    }, []);

    useEffect(() => {
        fetchJobs();
    }, [statusFilter]);

    const formatTime = (isoStr) => {
        if (!isoStr) return '—';
        try {
            return dayjs.utc(isoStr).tz(displayConfig.timezone).format(displayConfig.time_format);
        } catch {
            return isoStr;
        }
    };

    const statusColors = { pending: 'default', queued: 'blue', running: 'processing', success: 'success', failed: 'error', cancelled: 'default' };

    const columns = [
        { title: 'Job ID', dataIndex: 'job_id', key: 'job_id', ellipsis: true, width: 280 },
        { title: 'Template', dataIndex: 'template_name', key: 'template_name', ellipsis: true },
        { title: 'Status', dataIndex: 'status', key: 'status', render: (s) => <Tag color={statusColors[s] || 'default'}>{s}</Tag> },
        { title: 'Retries', dataIndex: 'retry_count', key: 'retry_count', width: 80 },
        { title: 'Created at', dataIndex: 'created_at', key: 'created_at', render: formatTime },
        {
            title: 'Result',
            dataIndex: 'result',
            key: 'result',
            width: 80,
            render: (result, record) =>
                result != null ? (
                    <Button type="link" size="small" icon={<EyeOutlined />} onClick={() => setResultModal({ visible: true, data: result })}>
                        View
                    </Button>
                ) : (
                    '—'
                ),
        },
    ];

    return (
        <Card
            title={
                <Space>
                    <UnorderedListOutlined />
                    Jobs
                </Space>
            }
            extra={
                <Space>
                    <Select
                        placeholder="Status"
                        allowClear
                        style={{ width: 120 }}
                        value={statusFilter}
                        onChange={setStatusFilter}
                        options={[
                            { value: 'pending', label: 'Pending' },
                            { value: 'queued', label: 'Queued' },
                            { value: 'running', label: 'Running' },
                            { value: 'success', label: 'Success' },
                            { value: 'failed', label: 'Failed' },
                            { value: 'cancelled', label: 'Cancelled' },
                        ]}
                    />
                    <Button type="primary" icon={<ReloadOutlined />} onClick={fetchJobs} loading={loading}>
                        Refresh
                    </Button>
                </Space>
            }
        >
            <Table
                rowKey="job_id"
                columns={columns}
                dataSource={jobs}
                loading={loading}
                pagination={{ pageSize: 20 }}
                size="small"
            />

            <Modal
                title="Job Result"
                open={resultModal.visible}
                onCancel={() => setResultModal({ visible: false, data: null })}
                footer={<Button onClick={() => setResultModal({ visible: false, data: null })}>Close</Button>}
                width={600}
            >
                {resultModal.data != null && (
                    <VCJsonViewer component={{ input_values: { data: resultModal.data, copy: true, collapse: true } }} />
                )}
            </Modal>
        </Card>
    );
};

export default Jobs;
