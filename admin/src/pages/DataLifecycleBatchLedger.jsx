import React, { useState, useEffect, useCallback } from 'react';
import { Card, Table, Button, Space, InputNumber, Typography, Tag, message } from 'antd';
import { ReloadOutlined } from '@ant-design/icons';
import { api } from '../utils/api';
import ErrorModal from '../components/ErrorModal';

const { Text } = Typography;

const opColor = {
    archive_postgres: 'blue',
    iceberg_export: 'cyan',
    purge_hot: 'orange',
    purge_archived: 'volcano',
};

const DataLifecycleBatchLedger = () => {
    const [items, setItems] = useState([]);
    const [total, setTotal] = useState(0);
    const [loading, setLoading] = useState(false);
    const [policyId, setPolicyId] = useState(null);
    const [page, setPage] = useState(1);
    const [pageSize, setPageSize] = useState(50);
    const [errorModal, setErrorModal] = useState(null);

    const load = useCallback(async () => {
        try {
            setLoading(true);
            const off = (page - 1) * pageSize;
            const data = await api.getLifecycleBatchLedger({
                policy_id: policyId || undefined,
                limit: pageSize,
                offset: off,
            });
            setItems(data.items || []);
            setTotal(data.total ?? 0);
        } catch (e) {
            message.error(e.response?.data?.detail || e.message || 'Failed to load');
            if (e.errorData) setErrorModal(e);
        } finally {
            setLoading(false);
        }
    }, [page, pageSize, policyId]);

    useEffect(() => {
        load();
    }, [load]);

    const cols = [
        { title: 'ID', dataIndex: 'id', width: 80 },
        { title: 'Policy', dataIndex: 'policy_id', width: 80 },
        {
            title: 'Operation',
            dataIndex: 'operation',
            width: 140,
            render: (op) => <Tag color={opColor[op] || 'default'}>{op}</Tag>,
        },
        { title: 'Source', dataIndex: 'source_table', ellipsis: true },
        { title: 'Dest type', dataIndex: 'destination_type', width: 110 },
        { title: 'Detail', dataIndex: 'destination_detail', ellipsis: true },
        { title: 'Rows', dataIndex: 'rows_affected', width: 72 },
        {
            title: 'Status',
            dataIndex: 'status',
            width: 96,
            render: (s) => <Tag color={s === 'failed' ? 'red' : s === 'completed' ? 'green' : 'default'}>{s}</Tag>,
        },
        { title: 'Started', dataIndex: 'started_at', width: 180, ellipsis: true },
        { title: 'Purged at', dataIndex: 'purged_at', width: 160, ellipsis: true, render: (v) => v || '—' },
        {
            title: 'Extra',
            key: 'ex',
            ellipsis: true,
            render: (_, r) => {
                const ex = r.extra;
                if (!ex || typeof ex !== 'object') return '—';
                const p = ex.parquet_path;
                const n = ex.pk_values?.length;
                return (
                    <Text type="secondary" ellipsis style={{ maxWidth: 220 }}>
                        {p ? p : ''}
                        {n != null ? ` pk:${n}` : ''}
                    </Text>
                );
            },
        },
        {
            title: 'Error',
            dataIndex: 'error_message',
            ellipsis: true,
            render: (v) => (v ? <Text type="danger">{v}</Text> : '—'),
        },
    ];

    return (
        <div style={{ padding: 16 }}>
            <Card
                title="Lifecycle batch ledger"
                extra={
                    <Button icon={<ReloadOutlined />} onClick={load}>
                        Refresh
                    </Button>
                }
            >
                <Space style={{ marginBottom: 16 }} wrap>
                    <span>Filter by policy id:</span>
                    <InputNumber
                        min={1}
                        placeholder="All policies"
                        value={policyId}
                        onChange={(v) => {
                            setPolicyId(v || null);
                            setPage(1);
                        }}
                        style={{ width: 160 }}
                    />
                </Space>
                <Table
                    rowKey="id"
                    loading={loading}
                    columns={cols}
                    dataSource={items}
                    pagination={{
                        current: page,
                        pageSize,
                        total,
                        showSizeChanger: true,
                        pageSizeOptions: ['20', '50', '100'],
                        onChange: (p, ps) => {
                            setPage(p);
                            setPageSize(ps);
                        },
                    }}
                    scroll={{ x: 1200 }}
                />
            </Card>
            {errorModal && (
                <ErrorModal visible={!!errorModal} error={errorModal} onClose={() => setErrorModal(null)} />
            )}
        </div>
    );
};

export default DataLifecycleBatchLedger;
