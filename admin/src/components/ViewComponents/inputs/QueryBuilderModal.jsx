/**
 * QueryBuilderModal - Modal wrapper for QueryBuilder.
 * Used in DbQuery and ApiEndpoints - same component for both.
 * - DbQuery: showPreviewResults=true - View Top 5 Results, Use Query
 * - ApiEndpoints: showPreviewResults=false - Use Query only
 */
import React, { useState, useEffect } from 'react';
import { Modal, Button, Space, Table, message } from 'antd';
import { PlayCircleOutlined, CheckOutlined, ArrowLeftOutlined } from '@ant-design/icons';
import QueryBuilder from './QueryBuilder';
import { api } from '../../../utils/api';

const QueryBuilderModal = ({
    visible,
    onClose,
    onUseQuery,
    dataSource = 'database',
    dataModels = [],
    showPreviewResults = false,
    initialValue = '',
}) => {
    const [sql, setSql] = useState(initialValue);
    useEffect(() => {
        if (visible) setSql(initialValue || '');
    }, [visible, initialValue]);
    const [previewLoading, setPreviewLoading] = useState(false);
    const [previewRows, setPreviewRows] = useState([]);
    const [previewColumns, setPreviewColumns] = useState([]);

    const handleUseQuery = () => {
        if (!sql?.trim()) {
            message.warning('Please build or enter a query first');
            return;
        }
        onUseQuery?.(sql);
        handleClose();
    };

    const handleViewTop5 = async () => {
        if (!sql?.trim()) {
            message.warning('Please build or enter a query first');
            return;
        }
        try {
            setPreviewLoading(true);
            const response = await api.executeQuery(sql, 5);
            setPreviewRows(response.rows || []);
            setPreviewColumns(response.columns || []);
        } catch (error) {
            message.error('Query failed: ' + (error.message || 'Unknown error'));
        } finally {
            setPreviewLoading(false);
        }
    };

    const handleClose = () => {
        setSql('');
        setPreviewRows([]);
        setPreviewColumns([]);
        onClose?.();
    };

    const tableColumns = (previewColumns || []).map((col) => ({
        title: col,
        dataIndex: col,
        key: col,
        ellipsis: true,
    }));

    return (
        <Modal
            title="Query Builder"
            open={visible}
            onCancel={handleClose}
            width="90%"
            style={{ maxWidth: 1200 }}
            centered
            footer={
                <Space>
                    <Button icon={<ArrowLeftOutlined />} onClick={handleClose}>
                        Cancel
                    </Button>
                    {showPreviewResults && (
                        <Button
                            icon={<PlayCircleOutlined />}
                            onClick={handleViewTop5}
                            loading={previewLoading}
                            disabled={!sql?.trim()}
                        >
                            View Top 5 Results
                        </Button>
                    )}
                    <Button type="primary" icon={<CheckOutlined />} onClick={handleUseQuery} disabled={!sql?.trim()}>
                        Use Query
                    </Button>
                </Space>
            }
        >
            <div style={{ maxHeight: 'calc(100vh - 200px)', overflowY: 'auto' }}>
                <QueryBuilder
                    value={sql}
                    onChange={(s) => setSql(s)}
                    dataSource={dataSource}
                    dataModels={dataModels}
                    showExecute={false}
                    showGeneratedSql={true}
                    showRawSqlTab={true}
                />
            </div>
            {showPreviewResults && previewRows.length > 0 && (
                <div style={{ marginTop: 24 }}>
                    <h4>Preview (Top 5 Results)</h4>
                    <Table
                        columns={tableColumns}
                        dataSource={previewRows.map((r, i) => ({ key: i, ...r }))}
                        size="small"
                        pagination={false}
                        scroll={{ x: 'max-content' }}
                    />
                </div>
            )}
        </Modal>
    );
};

export default QueryBuilderModal;
