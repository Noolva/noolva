import React, { useState, useEffect } from 'react';
import {
    Input,
    List,
    Card,
    Button,
    Space,
    message,
    Spin,
    Form,
    InputNumber,
    Switch,
    Select,
    Drawer
} from 'antd';
import { SearchOutlined, DatabaseOutlined, SaveOutlined, ReloadOutlined, EditOutlined, PlusOutlined, DeleteOutlined } from '@ant-design/icons';
import { VCTable } from '../components/ViewComponents/displays/VCTable';
import { VCText } from '../components/ViewComponents/inputs/VCText';
import { VCTextArea } from '../components/ViewComponents/inputs/VCTextArea';
import { VCNumber } from '../components/ViewComponents/inputs/VCNumber';
import { VCDate } from '../components/ViewComponents/inputs/VCDate';
import { VCTimestampUTC } from '../components/ViewComponents/inputs/VCTimestampUTC';
import { VCSwitch } from '../components/ViewComponents/inputs/VCSwitch';
import { VCSelect } from '../components/ViewComponents/inputs/VCSelect';
import { api } from '../utils/api';

const { Search } = Input;
const { Option } = Select;

const Database = () => {
    const [tables, setTables] = useState([]);
    const [filteredTables, setFilteredTables] = useState([]);
    const [selectedTable, setSelectedTable] = useState(null);
    const [tableStructure, setTableStructure] = useState(null);
    const [loading, setLoading] = useState(false);
    const [structureLoading, setStructureLoading] = useState(false);
    const [editForm] = Form.useForm();
    const [originalStructure, setOriginalStructure] = useState(null);
    const [editDrawerVisible, setEditDrawerVisible] = useState(false);

    // Fetch all tables on mount
    useEffect(() => {
        fetchTables();
    }, []);

    // Fetch table structure when table is selected
    useEffect(() => {
        if (selectedTable) {
            fetchTableStructure(selectedTable);
        }
    }, [selectedTable]);

    const fetchTables = async () => {
        try {
            setLoading(true);
            const response = await api.getDatabaseTables(null); // Fetch all tables
            setTables(response.tables || []);
            setFilteredTables(response.tables || []); // Initially show all tables
        } catch (error) {
            message.error(`Failed to fetch tables: ${error.message}`);
        } finally {
            setLoading(false);
        }
    };

    const fetchTableStructure = async (tableName) => {
        try {
            setStructureLoading(true);
            const response = await api.getTableStructure(tableName);
            setTableStructure(response);
            setOriginalStructure(JSON.parse(JSON.stringify(response))); // Deep copy for reset
        } catch (error) {
            message.error(`Failed to fetch table structure: ${error.message}`);
            setTableStructure(null);
            setOriginalStructure(null);
        } finally {
            setStructureLoading(false);
        }
    };

    const handleSearch = (value) => {
        if (!value.trim()) {
            setFilteredTables(tables);
            return;
        }
        const filtered = tables.filter(table =>
            table.table_name.toLowerCase().includes(value.toLowerCase())
        );
        setFilteredTables(filtered);
    };

    const handleTableSelect = (tableName) => {
        setSelectedTable(tableName);
        editForm.resetFields();
    };


    const handleSaveSchema = async () => {
        try {
            const values = await editForm.validateFields();
            const columns = values.columns || [];

            // Prepare schema changes
            const changes = [];
            const originalColumns = originalStructure?.columns || [];
            const editedColumns = columns;

            // Compare original and edited to find changes
            for (let i = 0; i < editedColumns.length; i++) {
                const edited = editedColumns[i];
                const original = originalColumns[i];

                if (original) {
                    // Existing column - check for changes
                    if (edited.column_name !== original.column_name) {
                        changes.push({
                            type: 'rename_column',
                            old_name: original.column_name,
                            new_name: edited.column_name
                        });
                    }
                    if (edited.data_type !== original.data_type ||
                        edited.max_length !== original.max_length) {
                        changes.push({
                            type: 'alter_column_type',
                            column_name: edited.column_name,
                            data_type: edited.data_type,
                            max_length: edited.max_length
                        });
                    }
                    if (edited.is_nullable !== original.is_nullable) {
                        changes.push({
                            type: 'alter_column_nullable',
                            column_name: edited.column_name,
                            is_nullable: edited.is_nullable
                        });
                    }
                    if (edited.default_value !== original.default_value) {
                        changes.push({
                            type: 'alter_column_default',
                            column_name: edited.column_name,
                            default_value: edited.default_value
                        });
                    }
                } else {
                    // New column
                    changes.push({
                        type: 'add_column',
                        column_name: edited.column_name,
                        data_type: edited.data_type,
                        max_length: edited.max_length,
                        is_nullable: edited.is_nullable,
                        default_value: edited.default_value
                    });
                }
            }

            // Check for deleted columns
            for (const original of originalColumns) {
                if (!editedColumns.find(e => e.column_name === original.column_name)) {
                    changes.push({
                        type: 'drop_column',
                        column_name: original.column_name
                    });
                }
            }

            if (changes.length === 0) {
                message.info('No changes to save');
                return;
            }

            await api.updateTableSchema(selectedTable, changes);
            message.success('Schema updated successfully');

            // Refresh structure
            await fetchTableStructure(selectedTable);
            setEditDrawerVisible(false);
        } catch (error) {
            if (error.errorFields) {
                return; // Form validation errors
            }
            message.error(`Failed to update schema: ${error.message}`);
        }
    };

    const handleReset = () => {
        if (originalStructure) {
            setTableStructure(JSON.parse(JSON.stringify(originalStructure)));
            const columns = originalStructure.columns.map(col => ({
                column_name: col.column_name,
                data_type: col.data_type,
                max_length: col.max_length,
                is_nullable: col.is_nullable,
                default_value: col.default_value || '',
                is_primary_key: col.is_primary_key
            }));
            editForm.setFieldsValue({ columns });
        } else {
            editForm.resetFields();
        }
    };

    const handleAddColumn = () => {
        const currentColumns = editForm.getFieldValue('columns') || [];
        editForm.setFieldsValue({
            columns: [...currentColumns, {
                column_name: '',
                data_type: 'varchar',
                max_length: 255,
                is_nullable: true,
                default_value: '',
                is_primary_key: false
            }]
        });
    };

    const handleRemoveColumn = (index) => {
        const currentColumns = editForm.getFieldValue('columns') || [];
        const column = currentColumns[index];

        // Warn if trying to remove primary key
        if (column.is_primary_key) {
            message.warning('Cannot remove primary key column');
            return;
        }

        const newColumns = currentColumns.filter((_, i) => i !== index);
        editForm.setFieldsValue({ columns: newColumns });
    };

    // Prepare structure table data for VCTable
    const structureTableData = tableStructure ? {
        columns: [
            { title: 'Column Name', dataIndex: 'column_name', key: 'column_name' },
            { title: 'Data Type', dataIndex: 'data_type', key: 'data_type' },
            { title: 'Max Length', dataIndex: 'max_length', key: 'max_length' },
            { title: 'Nullable', dataIndex: 'is_nullable', key: 'is_nullable' },
            { title: 'Default Value', dataIndex: 'default_value', key: 'default_value' },
            { title: 'Primary Key', dataIndex: 'is_primary_key', key: 'is_primary_key' },
        ],
        dataSource: tableStructure.columns.map(col => ({
            key: col.column_name,
            column_name: col.column_name,
            data_type: col.data_type,
            max_length: col.max_length || '-',
            is_nullable: col.is_nullable ? 'YES' : 'NO',
            default_value: col.default_value || '-',
            is_primary_key: col.is_primary_key ? 'YES' : 'NO',
        })),
        pagination: false
    } : null;

    // Map PostgreSQL data types to VC component types
    const getComponentTypeFromDataType = (dataType, column, value) => {
        const normalizedType = dataType?.toLowerCase()?.trim() || '';
        const columnName = column.column_name?.toLowerCase() || '';


        // Map based on PostgreSQL data types from information_schema
        // PostgreSQL information_schema.columns.data_type returns base types like:
        // 'timestamp', 'timestamp without time zone', 'timestamp with time zone', etc.

        // Timestamp types - CHECK FIRST before other checks
        // PostgreSQL returns "timestamp without time zone" (exact string from schema)
        // Explicit check for idate/last_updated columns first (guaranteed match)
        if (columnName === 'idate' || columnName === 'last_updated') {
            return {
                type: 'timestamp',
                inputValues: {
                    format: 'YYYY-MM-DD HH:mm:ss',
                    show_time: true,
                    default_value: value
                }
            };
        }

        // Check timestamp types by data_type
        if (normalizedType === 'timestamp' ||
            normalizedType === 'timestamp without time zone' ||
            normalizedType === 'timestamp with time zone' ||
            normalizedType.startsWith('timestamp')) {
            return {
                type: 'timestamp',
                inputValues: {
                    format: 'YYYY-MM-DD HH:mm:ss',
                    show_time: true,
                    default_value: value
                }
            };
        }

        // Numeric types
        if (normalizedType.includes('int') ||
            normalizedType === 'numeric' ||
            normalizedType === 'decimal' ||
            normalizedType === 'real' ||
            normalizedType === 'double precision' ||
            normalizedType === 'float' ||
            normalizedType === 'smallint' ||
            normalizedType === 'bigint' ||
            normalizedType === 'serial' ||
            normalizedType === 'bigserial') {
            return { type: 'number', inputValues: {} };
        }

        // Boolean types
        if (normalizedType === 'boolean' || normalizedType === 'bool') {
            return {
                type: 'switch',
                inputValues: {
                    default_value: value === true || value === 'true' || value === 1 || value === '1'
                }
            };
        }

        // Time types (without date)
        if (normalizedType === 'time' ||
            normalizedType === 'time without time zone' ||
            normalizedType === 'time with time zone') {
            return {
                type: 'datetime',
                inputValues: {
                    format: 'HH:mm:ss',
                    show_time: true,
                    default_value: value
                }
            };
        }

        // Date types (without time)
        if (normalizedType === 'date') {
            return {
                type: 'date',
                inputValues: {
                    format: 'YYYY-MM-DD',
                    default_value: value ? (value instanceof Date ? value : new Date(value)) : null
                }
            };
        }

        // Text types
        if (normalizedType === 'text' ||
            (normalizedType.includes('varchar') && column.max_length && column.max_length > 100) ||
            (normalizedType === 'character varying' && column.max_length && column.max_length > 100)) {
            return { type: 'textarea', inputValues: {} };
        }

        // UUID type
        if (normalizedType === 'uuid') {
            return { type: 'text', inputValues: { place_holder: 'UUID format' } };
        }

        // JSON types
        if (normalizedType === 'json' || normalizedType === 'jsonb') {
            return { type: 'textarea', inputValues: { place_holder: 'JSON format' } };
        }

        // Default fallback: check column name patterns only if no type matched
        const isDateTimeColumnName = columnName.includes('date') ||
            columnName.includes('time') ||
            columnName.includes('created') ||
            columnName.includes('updated');

        if (isDateTimeColumnName) {
            // Check if value looks like a datetime
            const looksLikeDateTime = typeof value === 'string' &&
                value.match(/^\d{4}-\d{2}-\d{2}[T ]\d{2}:\d{2}:\d{2}/);
            const canParseAsDate = value && (
                value instanceof Date ||
                (typeof value === 'string' && !isNaN(Date.parse(value)))
            );

            if (looksLikeDateTime || canParseAsDate) {
                return {
                    type: 'datetime',
                    inputValues: {
                        format: 'YYYY-MM-DD HH:mm:ss',
                        show_time: true,
                        default_value: value
                    }
                };
            }
        }

        // Default: text input
        return { type: 'text', inputValues: {} };
    };

    // Render VC component directly based on component type
    const renderVCComponent = (componentType, inputValues) => {
        const component = {
            input_values: inputValues
        };

        switch (componentType) {
            case 'timestamp':
            case 'timestamputc':
                return <VCTimestampUTC key={inputValues.name} component={component} />;
            case 'datetime':
                // Note: If you have a datetime component, import and use it here
                return <VCTimestampUTC key={inputValues.name} component={component} />;
            case 'date':
                return <VCDate key={inputValues.name} component={component} />;
            case 'number':
                return <VCNumber key={inputValues.name} component={component} />;
            case 'switch':
                return <VCSwitch key={inputValues.name} component={component} />;
            case 'textarea':
                return <VCTextArea key={inputValues.name} component={component} />;
            case 'select':
                return <VCSelect key={inputValues.name} component={component} />;
            case 'text':
            default:
                return <VCText key={inputValues.name} component={component} />;
        }
    };


    // Common data types
    const dataTypes = [
        'varchar', 'char', 'text', 'integer', 'bigint', 'smallint',
        'numeric', 'decimal', 'real', 'double precision',
        'boolean', 'date', 'timestamp', 'time',
        'jsonb', 'uuid', 'bytea'
    ];

    return (
        <div style={{ padding: '20px', height: 'calc(100vh - 100px)', display: 'flex', flexDirection: 'column' }}>
            <h2 style={{ marginBottom: '16px', marginTop: 0 }}>
                <DatabaseOutlined /> Database Administration
            </h2>

            <div style={{ display: 'flex', gap: '20px', flex: 1, minHeight: 0 }}>
                {/* Tables List */}
                <div style={{ width: '300px', minWidth: '300px', display: 'flex', flexDirection: 'column' }}>
                    <Card
                        title={
                            <div style={{ display: 'flex', alignItems: 'center', gap: '8px', width: '100%' }}>
                                <Search
                                    placeholder="Search tables..."
                                    allowClear
                                    enterButton={<SearchOutlined />}
                                    size="small"
                                    onChange={(e) => handleSearch(e.target.value)}
                                    style={{ flex: 1 }}
                                />
                                <span style={{ float: 'right', marginLeft: 'auto', whiteSpace: 'nowrap' }}>
                                    ({filteredTables.length})
                                </span>
                            </div>
                        }
                        size="small"
                        styles={{ body: { padding: 0, flex: 1, display: 'flex', flexDirection: 'column', minHeight: 0 } }}
                    >
                        {loading ? (
                            <div style={{ textAlign: 'center', padding: '20px' }}>
                                <Spin />
                            </div>
                        ) : (
                            <List
                                style={{ flex: 1, overflowY: 'auto' }}
                                dataSource={filteredTables}
                                renderItem={(table) => (
                                    <List.Item
                                        style={{
                                            cursor: 'pointer',
                                            backgroundColor: selectedTable === table.table_name ? '#e6f7ff' : 'transparent',
                                            padding: '12px 16px',
                                        }}
                                        onClick={() => handleTableSelect(table.table_name)}
                                    >
                                        <List.Item.Meta
                                            title={table.table_name}
                                            description={table.table_type}
                                        />
                                    </List.Item>
                                )}
                            />
                        )}
                    </Card>
                </div>

                {/* Table Structure - Displayed Directly */}
                <div style={{ flex: 1, display: 'flex', flexDirection: 'column', minHeight: 0 }}>
                    {selectedTable ? (
                        <Card
                            title={
                                <Space>
                                    <DatabaseOutlined />
                                    {selectedTable}
                                </Space>
                            }
                            extra={
                                <Space>
                                    <Button
                                        icon={<ReloadOutlined />}
                                        onClick={() => fetchTableStructure(selectedTable)}
                                        loading={structureLoading}
                                    >
                                        Refresh
                                    </Button>
                                    <Button
                                        type="primary"
                                        icon={<EditOutlined />}
                                        onClick={() => {
                                            // Initialize form with current structure
                                            const columns = tableStructure.columns.map(col => ({
                                                column_name: col.column_name,
                                                data_type: col.data_type,
                                                max_length: col.max_length || null,
                                                is_nullable: col.is_nullable,
                                                default_value: col.default_value || '',
                                                is_primary_key: col.is_primary_key
                                            }));
                                            editForm.setFieldsValue({ columns });
                                            setEditDrawerVisible(true);
                                        }}
                                        disabled={!tableStructure}
                                    >
                                        Edit Schema
                                    </Button>
                                </Space>
                            }
                            style={{ flex: 1, display: 'flex', flexDirection: 'column', minHeight: 0 }}
                            styles={{ body: { flex: 1, display: 'flex', flexDirection: 'column', minHeight: 0, overflow: 'auto' } }}
                        >
                                        {structureLoading ? (
                                            <div style={{ textAlign: 'center', padding: '40px' }}>
                                                <Spin size="large" />
                                            </div>
                                        ) : structureTableData ? (
                                            <VCTable
                                                component={{
                                                    input_values: structureTableData
                                                }}
                                            />
                                        ) : (
                                            <div style={{ textAlign: 'center', padding: '40px', color: '#999' }}>
                                                No structure data available
                                            </div>
                                        )}
                        </Card>
                    ) : (
                        <Card style={{ flex: 1, display: 'flex', flexDirection: 'column' }}>
                            <div style={{ textAlign: 'center', padding: '40px', color: '#999' }}>
                                Select a table from the list to view and edit its schema
                            </div>
                        </Card>
                    )}
                </div>
            </div>

            {/* Edit Schema Drawer */}
            <Drawer
                title={`Edit Schema - ${selectedTable}`}
                open={editDrawerVisible}
                onClose={() => setEditDrawerVisible(false)}
                width={900}
                extra={
                    <Space>
                        <Button onClick={() => setEditDrawerVisible(false)}>Cancel</Button>
                        <Button type="primary" onClick={handleSaveSchema}>Save</Button>
                    </Space>
                }
            >
                {tableStructure && (
                    <Form
                        form={editForm}
                        layout="vertical"
                        initialValues={{
                            columns: tableStructure.columns.map(col => ({
                                column_name: col.column_name,
                                data_type: col.data_type,
                                max_length: col.max_length || null,
                                is_nullable: col.is_nullable,
                                default_value: col.default_value || '',
                                is_primary_key: col.is_primary_key
                            }))
                        }}
                    >
                        <Form.List name="columns">
                                                        {(fields, { add, remove }) => (
                                                            <>
                                                                {fields.map(({ key, name, ...restField }, index) => {
                                                                    const column = editForm.getFieldValue(['columns', name]);
                                                                    const isPrimaryKey = column?.is_primary_key;

                                                                    return (
                                                                        <Card
                                                                            key={key}
                                                                            size="small"
                                                                            style={{ marginBottom: '16px' }}
                                                                            extra={
                                                                                !isPrimaryKey && (
                                                                                    <Button
                                                                                        type="text"
                                                                                        danger
                                                                                        icon={<DeleteOutlined />}
                                                                                        onClick={() => handleRemoveColumn(name)}
                                                                                    />
                                                                                )
                                                                            }
                                                                        >
                                                                            <Space direction="vertical" style={{ width: '100%' }} size="small">
                                                                                <Form.Item
                                                                                    {...restField}
                                                                                    name={[name, 'column_name']}
                                                                                    label="Column Name"
                                                                                    rules={[{ required: true, message: 'Column name is required' }]}
                                                                                >
                                                                                    <Input
                                                                                        placeholder="column_name"
                                                                                        disabled={isPrimaryKey}
                                                                                    />
                                                                                </Form.Item>

                                                                                <Space style={{ width: '100%' }}>
                                                                                    <Form.Item
                                                                                        {...restField}
                                                                                        name={[name, 'data_type']}
                                                                                        label="Data Type"
                                                                                        rules={[{ required: true, message: 'Data type is required' }]}
                                                                                        style={{ flex: 1 }}
                                                                                    >
                                                                                        <Select placeholder="Select data type">
                                                                                            {dataTypes.map(dt => (
                                                                                                <Option key={dt} value={dt}>{dt}</Option>
                                                                                            ))}
                                                                                        </Select>
                                                                                    </Form.Item>

                                                                                    <Form.Item
                                                                                        {...restField}
                                                                                        name={[name, 'max_length']}
                                                                                        label="Max Length"
                                                                                        style={{ width: '150px' }}
                                                                                    >
                                                                                        <InputNumber
                                                                                            placeholder="Length"
                                                                                            min={1}
                                                                                            style={{ width: '100%' }}
                                                                                        />
                                                                                    </Form.Item>
                                                                                </Space>

                                                                                <Space style={{ width: '100%' }}>
                                                                                    <Form.Item
                                                                                        {...restField}
                                                                                        name={[name, 'is_nullable']}
                                                                                        label="Nullable"
                                                                                        valuePropName="checked"
                                                                                        style={{ width: '150px' }}
                                                                                    >
                                                                                        <Switch />
                                                                                    </Form.Item>

                                                                                    <Form.Item
                                                                                        {...restField}
                                                                                        name={[name, 'default_value']}
                                                                                        label="Default Value"
                                                                                        style={{ flex: 1 }}
                                                                                    >
                                                                                        <Input placeholder="Default value (optional)" />
                                                                                    </Form.Item>
                                                                                </Space>

                                                                                {isPrimaryKey && (
                                                                                    <div style={{ color: '#1890ff', fontSize: '12px' }}>
                                                                                        Primary Key (cannot be modified)
                                                                                    </div>
                                                                                )}
                                                                            </Space>
                                                                        </Card>
                                                                    );
                                                                })}

                                                                <Button
                                                                    type="dashed"
                                                                    onClick={handleAddColumn}
                                                                    icon={<PlusOutlined />}
                                                                    style={{ width: '100%', marginTop: '16px' }}
                                                                >
                                                                    Add Column
                                                                </Button>
                                                            </>
                                                        )}
                        </Form.List>

                        <Form.Item style={{ marginTop: '24px' }}>
                            <Space>
                                <Button
                                    type="primary"
                                    icon={<SaveOutlined />}
                                    onClick={handleSaveSchema}
                                >
                                    Save Schema
                                </Button>
                                <Button
                                    icon={<ReloadOutlined />}
                                    onClick={handleReset}
                                >
                                    Reset
                                </Button>
                            </Space>
                        </Form.Item>
                    </Form>
                )}
            </Drawer>
        </div>
    );
};

export default Database;
