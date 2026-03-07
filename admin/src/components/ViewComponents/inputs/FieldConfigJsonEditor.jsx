import React, { useState, useEffect, useMemo, useRef } from 'react';
import {
    Form,
    Input,
    InputNumber,
    Select,
    Switch,
    Button,
    Space,
    Row,
    Col,
    Modal,
    Table,
    Tag,
    Divider,
    Typography,
    Card,
    Alert,
    message
} from 'antd';
import {
    PlusOutlined,
    DeleteOutlined,
    UpOutlined,
    DownOutlined,
    SearchOutlined
} from '@ant-design/icons';
import { api } from '../../../utils/api';

const { Option } = Select;
const { TextArea } = Input;
const { Text } = Typography;

// Shared: build initial config from value + defaults (used for both initial state and effect sync)
function buildConfigFromValue(value, defaultPropsJson) {
    let parsedValue = {};
    if (value != null) {
        try {
            const v = typeof value === 'string' ? JSON.parse(value) : value;
            parsedValue = typeof v === 'object' && v !== null ? v : {};
        } catch (e) {
            console.error('Failed to parse field_config_json:', e);
        }
    }
    let parsedDefaults = {};
    if (defaultPropsJson) {
        try {
            parsedDefaults = typeof defaultPropsJson === 'string' ? JSON.parse(defaultPropsJson) : defaultPropsJson;
        } catch (e) {
            console.error('Failed to parse default_props_json:', e);
        }
    }
    let initialConfig = { ...parsedDefaults, ...parsedValue };
    const rawOptions = Array.isArray(parsedValue.options) && parsedValue.options.length > 0
        ? parsedValue.options
        : Array.isArray(parsedValue.items) && parsedValue.items.length > 0
            ? parsedValue.items
            : null;
    const savedOptions = rawOptions
        ? rawOptions.map((item) => {
            if (item && typeof item === 'object' && ('label' in item || 'value' in item || 'key' in item)) {
                return { value: item.value ?? item.key ?? '', label: item.label ?? item.value ?? item.key ?? '' };
            }
            return { value: String(item), label: String(item) };
        })
        : null;
    if (savedOptions && savedOptions.length > 0) {
        initialConfig = { ...initialConfig, options: savedOptions };
    } else if (Array.isArray(initialConfig.items) && (!Array.isArray(initialConfig.options) || initialConfig.options.length === 0)) {
        initialConfig = {
            ...initialConfig,
            options: initialConfig.items.map((item) => {
                if (item && typeof item === 'object' && ('label' in item || 'value' in item)) {
                    return { value: item.value ?? item.key ?? '', label: item.label ?? item.value ?? item.key ?? '' };
                }
                return { value: String(item), label: String(item) };
            }),
        };
    }
    return initialConfig;
}

export function FieldConfigJsonEditor({ fieldTypeId, fieldTypeCode, defaultPropsJson, value, onChange }) {
    const [config, setConfig] = useState(() => buildConfigFromValue(value, defaultPropsJson));
    const [dataModels, setDataModels] = useState([]);
    const [selectedModel, setSelectedModel] = useState(null);
    const [modelFields, setModelFields] = useState([]);
    const [modelModalVisible, setModelModalVisible] = useState(false);
    const [fieldModalVisible, setFieldModalVisible] = useState(false);
    const [searchText, setSearchText] = useState('');
    const [collections, setCollections] = useState([]);
    const [collectionsLoading, setCollectionsLoading] = useState(false);
    const isSyncingFromValue = useRef(false);
    const prevValueRef = useRef(undefined);

    // Sync config when value or defaults change (e.g. switching field or type)
    useEffect(() => {
        const initialConfig = buildConfigFromValue(value, defaultPropsJson);
        const valueKey = JSON.stringify(initialConfig);
        if (prevValueRef.current !== valueKey) {
            prevValueRef.current = valueKey;
            isSyncingFromValue.current = true;
            setConfig(initialConfig);
        }
    }, [value, defaultPropsJson, fieldTypeCode]);

    // Notify parent of changes (skip when syncing from value to prevent effect loop)
    useEffect(() => {
        if (isSyncingFromValue.current) {
            isSyncingFromValue.current = false;
            return;
        }
        if (onChange) {
            onChange(config);
        }
    }, [config, onChange]);

    // Load data models for relation field
    useEffect(() => {
        if (fieldTypeCode === 'relation') {
            loadDataModels();
        }
    }, [fieldTypeCode]);

    // Load collections for single_choice / multi_choice
    useEffect(() => {
        if (fieldTypeCode === 'single_choice' || fieldTypeCode === 'multi_choice') {
            loadCollections();
        }
    }, [fieldTypeCode]);

    // Load fields for selected model
    useEffect(() => {
        if (selectedModel && fieldTypeCode === 'relation') {
            loadModelFields(selectedModel.model_id);
        }
    }, [selectedModel, fieldTypeCode]);

    const loadDataModels = async () => {
        try {
            const response = await api.getDataModels({ limit: 500 });
            setDataModels(response.data_models || []);
        } catch (error) {
            console.error('Failed to load data models:', error);
        }
    };

    const loadModelFields = async (modelId) => {
        try {
            const response = await api.getDataModel(modelId, true);
            setModelFields(response.fields || []);
        } catch (error) {
            console.error('Failed to load model fields:', error);
        }
    };

    const loadCollections = async () => {
        setCollectionsLoading(true);
        try {
            const limit = 500;
            let offset = 0;
            const all = [];
            // eslint-disable-next-line no-constant-condition
            while (true) {
                const response = await api.getCollections({ limit, offset });
                const batch = response.collections || [];
                all.push(...batch);
                offset += batch.length;
                if (!response.has_more || batch.length === 0) break;
            }
            all.sort((a, b) => (a.collection_name || '').localeCompare(b.collection_name || ''));
            setCollections(all);
        } catch (error) {
            console.error('Failed to load collections:', error);
            setCollections([]);
        } finally {
            setCollectionsLoading(false);
        }
    };

    const updateConfig = (key, val) => {
        setConfig(prev => ({ ...prev, [key]: val }));
    };

    const updateNestedConfig = (key, nestedKey, val) => {
        setConfig(prev => ({
            ...prev,
            [key]: { ...(prev[key] || {}), [nestedKey]: val }
        }));
    };

    const updateArrayConfig = (key, index, val) => {
        setConfig(prev => {
            const arr = [...(prev[key] || [])];
            arr[index] = val;
            return { ...prev, [key]: arr };
        });
    };

    const addArrayItem = (key, defaultItem = {}) => {
        setConfig(prev => ({
            ...prev,
            [key]: [...(prev[key] || []), defaultItem]
        }));
    };

    const removeArrayItem = (key, index) => {
        setConfig(prev => {
            const arr = [...(prev[key] || [])];
            arr.splice(index, 1);
            return { ...prev, [key]: arr };
        });
    };

    const moveArrayItem = (key, index, direction) => {
        setConfig(prev => {
            const arr = [...(prev[key] || [])];
            if (direction === 'up' && index > 0) {
                [arr[index - 1], arr[index]] = [arr[index], arr[index - 1]];
            } else if (direction === 'down' && index < arr.length - 1) {
                [arr[index], arr[index + 1]] = [arr[index + 1], arr[index]];
            }
            return { ...prev, [key]: arr };
        });
    };

    // Render based on field type
    const renderConfig = () => {
        switch (fieldTypeCode) {
            case 'audio':
                return (
                    <Form.Item label="Multiple Files">
                        <Switch
                            checked={config.multiple || false}
                            onChange={(checked) => updateConfig('multiple', checked)}
                        />
                        <Text type="secondary" style={{ marginLeft: 8 }}>Allow multiple audio files</Text>
                    </Form.Item>
                );

            case 'address':
                const addressFields = ['street', 'city', 'state', 'zip', 'country'];
                return (
                    <Form.Item label="Address Fields">
                        <Select
                            mode="multiple"
                            value={config.fields || []}
                            onChange={(vals) => updateConfig('fields', vals)}
                            style={{ width: '100%' }}
                        >
                            {addressFields.map(f => (
                                <Option key={f} value={f}>{f.charAt(0).toUpperCase() + f.slice(1)}</Option>
                            ))}
                        </Select>
                    </Form.Item>
                );

            case 'relation':
                const relationValue = config.target_model ? `${config.target_model}${config.target_field ? '.' + config.target_field : ''}` : '';
                return (
                    <>
                        <Form.Item label="Relation Type">
                            <Select
                                value={config.relation_type || 'one_to_many'}
                                onChange={(val) => updateConfig('relation_type', val)}
                                style={{ width: '100%' }}
                            >
                                <Option value="one_to_many">One to Many</Option>
                                <Option value="many_to_one">Many to One</Option>
                            </Select>
                        </Form.Item>
                        <Form.Item label="Target Model & Field">
                            <Space>
                                <Input
                                    value={relationValue}
                                    readOnly
                                    placeholder="Select model and field"
                                    style={{ width: 300 }}
                                />
                                <Button onClick={() => setModelModalVisible(true)}>Select Model</Button>
                            </Space>
                        </Form.Item>
                        <Modal
                            title="Select Data Model"
                            open={modelModalVisible}
                            onOk={() => {
                                if (selectedModel) {
                                    setModelModalVisible(false);
                                    setFieldModalVisible(true);
                                } else {
                                    message.warning('Please select a model');
                                }
                            }}
                            onCancel={() => {
                                setModelModalVisible(false);
                                setSelectedModel(null);
                            }}
                            width={600}
                        >
                                <Input
                                    placeholder="Search models..."
                                    prefix={<SearchOutlined />}
                                    value={searchText}
                                    onChange={(e) => setSearchText(e.target.value)}
                                    style={{ marginBottom: 16 }}
                                />
                                <Table
                                    columns={[
                                        { title: 'Model Name', dataIndex: 'model_name', key: 'model_name' },
                                        { title: 'Display Name', dataIndex: 'display_name', key: 'display_name' },
                                        {
                                            title: 'Action',
                                            key: 'action',
                                            render: (_, record) => (
                                                <Button
                                                    size="small"
                                                    onClick={() => setSelectedModel(record)}
                                                    type={selectedModel?.model_id === record.model_id ? 'primary' : 'default'}
                                                >
                                                    Select
                                                </Button>
                                            )
                                        }
                                    ]}
                                    dataSource={dataModels.filter(m =>
                                        !searchText || m.model_name?.toLowerCase().includes(searchText.toLowerCase()) ||
                                        m.display_name?.toLowerCase().includes(searchText.toLowerCase())
                                    )}
                                    rowKey="model_id"
                                    pagination={{ pageSize: 10 }}
                                />
                        </Modal>
                        <Modal
                            title={`Select Field from ${selectedModel?.display_name || selectedModel?.model_name || ''}`}
                            open={fieldModalVisible}
                            onOk={() => {
                                const selectedField = modelFields.find(f => f.field_id === parseInt(document.querySelector('input[name="selected_field"]:checked')?.value || '0'));
                                if (selectedField && selectedModel) {
                                    updateConfig('target_model', selectedModel.model_name);
                                    updateConfig('target_field', selectedField.field_name);
                                    setFieldModalVisible(false);
                                    setSelectedModel(null);
                                    message.success('Model and field selected');
                                } else {
                                    message.warning('Please select a field');
                                }
                            }}
                            onCancel={() => {
                                setFieldModalVisible(false);
                                setSelectedModel(null);
                            }}
                            width={600}
                        >
                                <Table
                                    columns={[
                                        { title: 'Field Name', dataIndex: 'field_name', key: 'field_name' },
                                        { title: 'Display Name', dataIndex: 'display_name', key: 'display_name' },
                                        { title: 'Type', dataIndex: 'type_name', key: 'type_name' },
                                        {
                                            title: 'Action',
                                            key: 'action',
                                            render: (_, record) => (
                                                <input
                                                    type="radio"
                                                    name="selected_field"
                                                    value={record.field_id}
                                                />
                                            )
                                        }
                                    ]}
                                    dataSource={modelFields}
                                    rowKey="field_id"
                                    pagination={{ pageSize: 10 }}
                                />
                        </Modal>
                    </>
                );

            case 'multi_choice':
            case 'single_choice':
                const optionsMode = config.options_mode || 'custom_collection';
                const isCustomCollection = optionsMode === 'custom_collection';
                const options = config.options || [];

                return (
                    <>
                        <Form.Item label="Options Mode">
                            <Select
                                value={optionsMode}
                                onChange={(val) => {
                                    updateConfig('options_mode', val);
                                    updateConfig('options_format', undefined);
                                    if (val !== 'custom_collection') {
                                        updateConfig('options', []);
                                    }
                                    updateConfig('collection_id', undefined);
                                }}
                                style={{ width: '100%' }}
                            >
                                <Option value="collections">Collection</Option>
                                <Option value="custom_collection">Custom Collection</Option>
                            </Select>
                        </Form.Item>
                        {optionsMode === 'collections' && (
                            <Form.Item label="Select Collection">
                                <Select
                                    showSearch
                                    placeholder="Select a collection"
                                    value={config.collection_id ?? undefined}
                                    onChange={(val) => updateConfig('collection_id', val)}
                                    loading={collectionsLoading}
                                    notFoundContent={collectionsLoading ? 'Loading...' : 'No collections found'}
                                    filterOption={(input, option) =>
                                        (option?.label ?? '').toString().toLowerCase().includes(input.toLowerCase())
                                    }
                                    optionFilterProp="label"
                                    style={{ width: '100%' }}
                                    allowClear
                                    options={collections.map((c) => ({
                                        value: c.collection_id,
                                        label: `${c.collection_name} (${c.collection_code})`,
                                        key: c.collection_id
                                    }))}
                                />
                            </Form.Item>
                        )}
                        {isCustomCollection && (
                            <Form.Item label="Options (Key-Value Pairs)">
                                {options.map((opt, idx) => (
                                    <Row key={idx} gutter={8} style={{ marginBottom: 8 }}>
                                        <Col span={10}>
                                            <Input
                                                placeholder="Key"
                                                value={opt.value || ''}
                                                onChange={(e) => updateArrayConfig('options', idx, { ...opt, value: e.target.value })}
                                            />
                                        </Col>
                                        <Col span={10}>
                                            <Input
                                                placeholder="Label"
                                                value={opt.label || ''}
                                                onChange={(e) => updateArrayConfig('options', idx, { ...opt, label: e.target.value })}
                                            />
                                        </Col>
                                        <Col span={4}>
                                            <Button
                                                icon={<DeleteOutlined />}
                                                onClick={() => removeArrayItem('options', idx)}
                                                danger
                                            />
                                        </Col>
                                    </Row>
                                ))}
                                <Button
                                    icon={<PlusOutlined />}
                                    onClick={() => addArrayItem('options', { value: '', label: '' })}
                                    type="dashed"
                                    block
                                >
                                    Add Option
                                </Button>
                            </Form.Item>
                        )}
                    </>
                );

            case 'auto_code':
                const pattern = config.pattern || [];
                return (
                    <Form.Item label="Pattern">
                        {pattern.map((item, idx) => (
                            <Card key={idx} size="small" style={{ marginBottom: 8 }}>
                                <Row gutter={8} align="middle">
                                    <Col span={6}>
                                        <Select
                                            value={item.type}
                                            onChange={(val) => updateArrayConfig('pattern', idx, { ...item, type: val })}
                                            style={{ width: '100%' }}
                                        >
                                            <Option value="prefix">Prefix</Option>
                                            <Option value="separator">Separator</Option>
                                            <Option value="date">Date</Option>
                                            <Option value="increment">Increment</Option>
                                        </Select>
                                    </Col>
                                    <Col span={item.type === 'date' ? 8 : item.type === 'increment' ? 16 : 10}>
                                        {item.type === 'prefix' || item.type === 'separator' ? (
                                            <Input
                                                placeholder="Value"
                                                value={item.value || ''}
                                                onChange={(e) => updateArrayConfig('pattern', idx, { ...item, value: e.target.value })}
                                            />
                                        ) : item.type === 'date' ? (
                                            <Input
                                                placeholder="Format (e.g., YYYY-MM)"
                                                value={item.format || ''}
                                                onChange={(e) => updateArrayConfig('pattern', idx, { ...item, format: e.target.value })}
                                            />
                                        ) : item.type === 'increment' ? (
                                            <Row gutter={8}>
                                                <Col span={12}>
                                                    <InputNumber
                                                        placeholder="Start"
                                                        value={item.start}
                                                        onChange={(val) => updateArrayConfig('pattern', idx, { ...item, start: val })}
                                                        style={{ width: '100%' }}
                                                    />
                                                </Col>
                                                <Col span={12}>
                                                    <InputNumber
                                                        placeholder="Padding"
                                                        value={item.padding}
                                                        onChange={(val) => updateArrayConfig('pattern', idx, { ...item, padding: val })}
                                                        style={{ width: '100%' }}
                                                    />
                                                </Col>
                                            </Row>
                                        ) : null}
                                    </Col>
                                    <Col span={8}>
                                        <Space>
                                            <Button
                                                icon={<UpOutlined />}
                                                size="small"
                                                onClick={() => moveArrayItem('pattern', idx, 'up')}
                                                disabled={idx === 0}
                                            />
                                            <Button
                                                icon={<DownOutlined />}
                                                size="small"
                                                onClick={() => moveArrayItem('pattern', idx, 'down')}
                                                disabled={idx === pattern.length - 1}
                                            />
                                            <Button
                                                icon={<DeleteOutlined />}
                                                size="small"
                                                danger
                                                onClick={() => removeArrayItem('pattern', idx)}
                                            />
                                        </Space>
                                    </Col>
                                </Row>
                            </Card>
                        ))}
                        <Button
                            icon={<PlusOutlined />}
                            onClick={() => addArrayItem('pattern', { type: 'prefix', value: '' })}
                            type="dashed"
                            block
                        >
                            Add Pattern Item
                        </Button>
                    </Form.Item>
                );

            case 'text':
                return (
                    <Form.Item label="Max Length">
                        <InputNumber
                            value={config.max_length}
                            onChange={(val) => updateConfig('max_length', val)}
                            min={1}
                            style={{ width: '100%' }}
                        />
                    </Form.Item>
                );

            case 'paragraph':
                return (
                    <Form.Item label="Max Line Count">
                        <InputNumber
                            value={config.max_line_counts}
                            onChange={(val) => updateConfig('max_line_counts', val)}
                            min={1}
                            style={{ width: '100%' }}
                        />
                    </Form.Item>
                );

            case 'currency':
                return (
                    <>
                        <Row gutter={16}>
                            <Col span={12}>
                                <Form.Item label="Maximum Digits">
                                    <InputNumber
                                        value={config.maximum_digits || config.precision}
                                        onChange={(val) => updateConfig('maximum_digits', val)}
                                        min={1}
                                        style={{ width: '100%' }}
                                    />
                                </Form.Item>
                            </Col>
                            <Col span={12}>
                                <Form.Item label="Decimal Places">
                                    <InputNumber
                                        value={config.allowed_decimal_places || config.scale}
                                        onChange={(val) => updateConfig('allowed_decimal_places', val)}
                                        min={0}
                                        style={{ width: '100%' }}
                                    />
                                </Form.Item>
                            </Col>
                        </Row>
                        <Form.Item label="Currency Symbol">
                            <Select
                                value={config.currency_symbol || '₹'}
                                onChange={(val) => updateConfig('currency_symbol', val)}
                                style={{ width: '100%' }}
                            >
                                <Option value="$">$ (USD)</Option>
                                <Option value="€">€ (EUR)</Option>
                                <Option value="£">£ (GBP)</Option>
                                <Option value="¥">¥ (JPY)</Option>
                                <Option value="₹">₹ (INR)</Option>
                                <Option value="₽">₽ (RUB)</Option>
                                <Option value="₩">₩ (KRW)</Option>
                                <Option value="₨">₨ (PKR)</Option>
                            </Select>
                        </Form.Item>
                    </>
                );

            case 'number':
                return (
                    <Row gutter={16}>
                        <Col span={12}>
                            <Form.Item label="Maximum Digits">
                                <InputNumber
                                    value={config.maximum_digits}
                                    onChange={(val) => updateConfig('maximum_digits', val)}
                                    min={1}
                                    style={{ width: '100%' }}
                                />
                            </Form.Item>
                        </Col>
                        <Col span={12}>
                            <Form.Item label="Decimal Places">
                                <InputNumber
                                    value={config.allowed_decimal_places}
                                    onChange={(val) => updateConfig('allowed_decimal_places', val)}
                                    min={0}
                                    style={{ width: '100%' }}
                                />
                            </Form.Item>
                        </Col>
                    </Row>
                );

            case 'image':
                const fileExtensions = ['.jpg', '.jpeg', '.png', '.gif', '.webp', '.svg', '.bmp'];
                return (
                    <>
                        <Form.Item label="Multiple Files">
                            <Switch
                                checked={config.is_multiple || config.multiple || false}
                                onChange={(checked) => updateConfig('is_multiple', checked)}
                            />
                            <Text type="secondary" style={{ marginLeft: 8 }}>Allow multiple images</Text>
                        </Form.Item>
                        <Form.Item label="Allow Crop">
                            <Switch
                                checked={config.allow_crop || false}
                                onChange={(checked) => updateConfig('allow_crop', checked)}
                            />
                        </Form.Item>
                        {config.allow_crop && (
                            <>
                                <Form.Item label="Crop Shape">
                                    <Select
                                        value={config.crop_shape || 'free'}
                                        onChange={(val) => updateConfig('crop_shape', val)}
                                        style={{ width: '100%' }}
                                    >
                                        <Option value="square">Square</Option>
                                        <Option value="circle">Circle</Option>
                                        <Option value="rectangle">Rectangle</Option>
                                        <Option value="free">Free</Option>
                                    </Select>
                                </Form.Item>
                                <Form.Item label="Crop Ratio">
                                    <Input
                                        placeholder="e.g., 16:9"
                                        value={config.crop_ratio || ''}
                                        onChange={(e) => updateConfig('crop_ratio', e.target.value)}
                                    />
                                </Form.Item>
                            </>
                        )}
                        <Form.Item label="Generate Thumbnail">
                            <Switch
                                checked={config.generate_thumbnail || false}
                                onChange={(checked) => updateConfig('generate_thumbnail', checked)}
                            />
                            <Text type="secondary" style={{ marginLeft: 8 }}>Auto-generate thumbnail on upload (saved as &lt;filename&gt;_thumb.&lt;ext&gt;)</Text>
                        </Form.Item>
                        <Form.Item label="Max Size (MB)">
                            <InputNumber
                                value={config.max_size_mb}
                                onChange={(val) => updateConfig('max_size_mb', val)}
                                min={0.1}
                                step={0.1}
                                style={{ width: '100%' }}
                            />
                        </Form.Item>
                        <Form.Item label="Allowed File Types">
                            <Select
                                mode="multiple"
                                value={config.filters || []}
                                onChange={(vals) => updateConfig('filters', vals)}
                                style={{ width: '100%' }}
                            >
                                {fileExtensions.map(ext => (
                                    <Option key={ext} value={ext}>{ext}</Option>
                                ))}
                            </Select>
                        </Form.Item>
                    </>
                );

            case 'file':
                const allExtensions = ['.pdf', '.doc', '.docx', '.xls', '.xlsx', '.txt', '.csv', '.zip', '.rar', '.jpg', '.png', '.gif'];
                return (
                    <>
                        <Form.Item label="Multiple Files">
                            <Switch
                                checked={config.is_multiple || config.multiple || false}
                                onChange={(checked) => updateConfig('is_multiple', checked)}
                            />
                            <Text type="secondary" style={{ marginLeft: 8 }}>Allow multiple files</Text>
                        </Form.Item>
                        <Form.Item label="Max Size (MB)">
                            <InputNumber
                                value={config.max_size_mb}
                                onChange={(val) => updateConfig('max_size_mb', val)}
                                min={0.1}
                                step={0.1}
                                style={{ width: '100%' }}
                            />
                        </Form.Item>
                        <Form.Item label="Allowed File Types">
                            <Select
                                mode="multiple"
                                value={config.filters || []}
                                onChange={(vals) => updateConfig('filters', vals)}
                                style={{ width: '100%' }}
                            >
                                {allExtensions.map(ext => (
                                    <Option key={ext} value={ext}>{ext}</Option>
                                ))}
                            </Select>
                        </Form.Item>
                    </>
                );

            case 'rich_text':
                return (
                    <Form.Item label="Content Type">
                        <Select
                            value={config.content_type || 'markdown'}
                            onChange={(val) => updateConfig('content_type', val)}
                            style={{ width: '100%' }}
                        >
                            <Option value="markdown">Markdown</Option>
                            <Option value="html">HTML</Option>
                        </Select>
                    </Form.Item>
                );

            case 'email':
                return (
                    <Form.Item label="Validation Regex">
                        <Input
                            value={config.validation_regex || ''}
                            onChange={(e) => updateConfig('validation_regex', e.target.value)}
                            placeholder="^[^@]+@[^@]+\\.[^@]+$"
                        />
                    </Form.Item>
                );

            default:
                return (
                    <Alert
                        message="No configuration required"
                        description="This field type does not require additional configuration."
                        type="info"
                        showIcon
                    />
                );
        }
    };

    return (
        <div>
            {renderConfig()}
        </div>
    );
}
