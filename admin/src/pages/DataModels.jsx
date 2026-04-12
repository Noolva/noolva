import React, { useMemo, useState, useEffect } from 'react';
import {
    Card,
    Table,
    Button,
    Space,
    Modal,
    Form,
    Input,
    Select,
    Switch,
    message,
    Popconfirm,
    Drawer,
    Tag,
    Typography,
    Row,
    Col,
    Tabs,
    Alert,
    Image,
    Dropdown,
    Segmented,
} from 'antd';
import {
    PlusOutlined,
    EditOutlined,
    DeleteOutlined,
    DatabaseOutlined,
    FieldTimeOutlined,
    OrderedListOutlined,
    ExclamationCircleOutlined,
    ReloadOutlined,
    ImportOutlined,
    DownloadOutlined,
    CopyOutlined,
    UnorderedListOutlined,
} from '@ant-design/icons';
import { api } from '../utils/api';
import { resolveApiAssetUrl } from '../config/runtimeApi';
import { VCDragSortList } from '../components/ViewComponents/displays/VCDragSortList';
import { FieldConfigJsonEditor } from '../components/ViewComponents/inputs/FieldConfigJsonEditor';
import { FieldsImportModal } from '../components/ViewComponents/inputs/FieldsImportModal';
import yaml from 'js-yaml';

const { Option } = Select;
const { TextArea } = Input;
const { Title, Text } = Typography;
const { TabPane } = Tabs;

const DataModels = () => {
    const [dataModels, setDataModels] = useState([]);
    const [loading, setLoading] = useState(false);
    const [fieldTypes, setFieldTypes] = useState([]);
    const [modalVisible, setModalVisible] = useState(false);
    const [fieldDrawerVisible, setFieldDrawerVisible] = useState(false);
    const [fieldEditorDrawerVisible, setFieldEditorDrawerVisible] = useState(false);
    const [fieldOrderingDrawerVisible, setFieldOrderingDrawerVisible] = useState(false);
    const [editingModel, setEditingModel] = useState(null);
    const [selectedModel, setSelectedModel] = useState(null);
    const [fields, setFields] = useState([]);
    const [orderingItems, setOrderingItems] = useState([]);
    const [editingField, setEditingField] = useState(null);
    const [form] = Form.useForm();
    const [fieldForm] = Form.useForm();
    const [confirmModalVisible, setConfirmModalVisible] = useState(false);
    const [pendingChanges, setPendingChanges] = useState(null);
    const [searchText, setSearchText] = useState('');
    const [fieldConfigJson, setFieldConfigJson] = useState({});
    const [selectedFieldType, setSelectedFieldType] = useState(null);
    const [deleteCheckModalVisible, setDeleteCheckModalVisible] = useState(false);
    const [deleteCheckInfo, setDeleteCheckInfo] = useState(null);
    const [pendingDeleteModelId, setPendingDeleteModelId] = useState(null);
    const [selectedFieldRowKeys, setSelectedFieldRowKeys] = useState([]);
    const [importModalVisible, setImportModalVisible] = useState(false);
    const [fieldTypesRefVisible, setFieldTypesRefVisible] = useState(false);
    const isFlattenedSelectedModel = useMemo(() => {
        const name = (selectedModel?.model_name || '').toLowerCase();
        const desc = ((selectedModel?.description || '') + '').toLowerCase();
        return name.startsWith('flattened_') || desc.includes('generated_by_flattening_table_policy_id=');
    }, [selectedModel]);
    const [fieldTypesRefFormat, setFieldTypesRefFormat] = useState('yaml');

    // Helper function to get asset URL
    const getAssetUrl = (assetPath) => {
        if (!assetPath) return null;
        return resolveApiAssetUrl(assetPath);
    };

    useEffect(() => {
        loadDataModels();
        loadFieldTypes();
    }, []);

    // Set form values when edit drawer opens (ensures Form is mounted and values display)
    useEffect(() => {
        if (fieldEditorDrawerVisible && editingField) {
            const recordFieldTypeId = Number(editingField.field_type_id);
            const fieldType = fieldTypes.find(ft => ft.field_type_id === recordFieldTypeId) || {
                field_type_id: editingField.field_type_id,
                type_name: editingField.type_name,
                type_code: editingField.type_code,
                actual_db_type: editingField.actual_db_type,
                input_type_image: editingField.input_type_image,
                default_props_json: {}
            };
            setSelectedFieldType(fieldType);
            fieldForm.setFieldsValue({
                field_name: editingField.field_name,
                display_name: editingField.display_name,
                field_type_id: recordFieldTypeId,
                is_required: editingField.is_required,
                is_unique: editingField.is_unique,
                is_primary_key: editingField.is_primary_key,
                default_value: editingField.default_value,
                encryption_method: editingField.encryption_method || 'none',
                ui_component: editingField.ui_component,
            });
        }
    }, [fieldEditorDrawerVisible, editingField, fieldTypes]);

    const loadDataModels = async () => {
        try {
            setLoading(true);
            const limit = 500;
            let offset = 0;
            const all = [];
            // Fetch in chunks (500 max per request)
            // eslint-disable-next-line no-constant-condition
            while (true) {
                const response = await api.getDataModels({ limit, offset });
                const batch = response.data_models || [];
                all.push(...batch);
                offset += batch.length;
                if (!response.has_more || batch.length === 0) break;
            }
            // Default sort by model_name client-side (so API can avoid expensive DB sort)
            all.sort((a, b) => (a.model_name || '').localeCompare(b.model_name || ''));
            setDataModels(all);
        } catch (error) {
            message.error('Failed to load data models: ' + (error.message || 'Unknown error'));
        } finally {
            setLoading(false);
        }
    };

    const loadFieldTypes = async () => {
        try {
            const response = await api.getFieldTypes();
            setFieldTypes(response.field_types || []);
        } catch (error) {
            console.error('Failed to load field types:', error);
        }
    };

    const loadModelFields = async (modelId) => {
        try {
            const response = await api.getDataModel(modelId);
            // Filter out system fields (idate, created_by, last_updated, row_exposure_mode_id) from UI display
            const allFields = response.fields || [];
            const visibleFields = allFields.filter(f =>
                f.field_name !== 'idate' &&
                f.field_name !== 'created_by' &&
                f.field_name !== 'last_updated' &&
                f.field_name !== 'row_exposure_mode_id'
            );
            setFields(visibleFields);
        } catch (error) {
            message.error('Failed to load fields: ' + (error.message || 'Unknown error'));
        }
    };

    const handleCreate = () => {
        setEditingModel(null);
        form.resetFields();
        // Set initial values for new model creation
        form.setFieldsValue({
            model_scope: 'saas',
            is_public: false,
            is_active: true,
            is_system_model: false,
            id_field_name: 'id', // Default ID field name
        });
        setModalVisible(true);
    };

    const handleEdit = async (record) => {
        try {
            setEditingModel(record);
            const response = await api.getDataModel(record.model_id);
            form.setFieldsValue({
                model_name: response.model_name,
                display_name: response.display_name,
                table_name: response.table_name, // Should match model_name
                table_alias: response.table_alias,
                model_scope: response.model_scope,
                is_public: response.is_public,
                is_system_model: response.is_system_model,
                is_active: response.is_active,
                description: response.description,
            });
            // Filter out system fields (idate, created_by, last_updated, row_exposure_mode_id) from UI display
            const allFields = response.fields || [];
            const visibleFields = allFields.filter(f =>
                f.field_name !== 'idate' &&
                f.field_name !== 'created_by' &&
                f.field_name !== 'last_updated' &&
                f.field_name !== 'row_exposure_mode_id'
            );
            setFields(visibleFields);
            setModalVisible(true);
        } catch (error) {
            message.error('Failed to load data model: ' + (error.message || 'Unknown error'));
        }
    };

    const handleDelete = async (modelId) => {
        try {
            // Check deletion safety first
            const checkResult = await api.checkModelDeletion(modelId);
            setDeleteCheckInfo(checkResult);
            setPendingDeleteModelId(modelId);
            setDeleteCheckModalVisible(true);
        } catch (error) {
            message.error('Failed to check model deletion: ' + (error.message || 'Unknown error'));
        }
    };

    const confirmDeleteModel = async (deleteTable = false, confirmDeleteData = false) => {
        if (!pendingDeleteModelId) return;

        try {
            await api.deleteDataModel(pendingDeleteModelId, deleteTable, confirmDeleteData);
            message.success('Data model deleted successfully');
            setDeleteCheckModalVisible(false);
            setDeleteCheckInfo(null);
            setPendingDeleteModelId(null);
            loadDataModels();
        } catch (error) {
            message.error('Failed to delete data model: ' + (error.message || 'Unknown error'));
        }
    };

    const handleSubmit = async (values) => {
        try {
            if (editingModel) {
                // Check if table_name changed
                if (values.table_name !== editingModel.table_name) {
                    setPendingChanges({
                        type: 'update',
                        modelId: editingModel.model_id,
                        oldTableName: editingModel.table_name,
                        newTableName: values.table_name,
                        values
                    });
                    setConfirmModalVisible(true);
                    return;
                }

                await api.updateDataModel(editingModel.model_id, values);
                message.success('Data model updated successfully');
            } else {
                // For new model creation, include id field and essential fields
                const submitValues = {
                    ...values,
                    id_field_name: values.id_field_name || 'id'
                };
                await api.createDataModel(submitValues);
                message.success('Data model created successfully');
            }
            setModalVisible(false);
            loadDataModels();
        } catch (error) {
            message.error('Failed to save data model: ' + (error.message || 'Unknown error'));
        }
    };

    const handleConfirmChanges = async () => {
        try {
            if (pendingChanges.type === 'update') {
                await api.updateDataModel(pendingChanges.modelId, pendingChanges.values);
                message.success('Data model updated successfully. Table renamed.');
                setModalVisible(false);
                loadDataModels();
            } else if (pendingChanges.type === 'add_field') {
                await api.addDataModelField(pendingChanges.modelId, pendingChanges.values);
                message.success('Field added successfully. Table modified.');
                await loadModelFields(pendingChanges.modelId);
                fieldForm.resetFields();
                setFieldEditorDrawerVisible(false);
                setEditingField(null);
            } else if (pendingChanges.type === 'delete_field') {
                await api.deleteDataModelField(
                    pendingChanges.modelId,
                    pendingChanges.fieldId,
                    true // delete_column = true
                );
                message.success('Field deleted successfully. Column removed from table.');
                await loadModelFields(pendingChanges.modelId);
            }
            setConfirmModalVisible(false);
            setPendingChanges(null);
        } catch (error) {
            message.error('Failed to apply changes: ' + (error.message || 'Unknown error'));
        }
    };

    const handleViewFields = async (record) => {
        setSelectedModel(record);
        await loadModelFields(record.model_id);
        setFieldDrawerVisible(true);
    };

    const openAddFieldDrawer = () => {
        setEditingField(null);
        setSelectedFieldType(null);
        setFieldConfigJson({});
        fieldForm.resetFields();
        fieldForm.setFieldsValue({
            encryption_method: 'none',
            is_required: false,
            is_unique: false,
            is_primary_key: false,
        });
        setFieldEditorDrawerVisible(true);
    };

    const handleFieldSubmit = async (values) => {
        try {
            if (!selectedModel) return;

            // Include field_config_json in values
            const submitValues = {
                ...values,
                field_config_json: Object.keys(fieldConfigJson).length > 0 ? fieldConfigJson : {}
            };

            if (editingField) {
                await api.updateDataModelField(selectedModel.model_id, editingField.field_id, submitValues);
                message.success('Field updated successfully');
                await loadModelFields(selectedModel.model_id);
                setFieldEditorDrawerVisible(false);
                setEditingField(null);
                setFieldConfigJson({});
                return;
            }

            // Adding a field will modify the table -> confirm
            setPendingChanges({ type: 'add_field', modelId: selectedModel.model_id, values: submitValues });
            setConfirmModalVisible(true);
        } catch (error) {
            message.error('Failed to add field: ' + (error.message || 'Unknown error'));
        }
    };

    // Generate SQL preview based on field type and config
    const generateSQLPreview = () => {
        if (!selectedFieldType || !fieldForm.getFieldValue('field_name')) {
            return null;
        }

        const fieldName = fieldForm.getFieldValue('field_name');
        const isRequired = fieldForm.getFieldValue('is_required');
        const defaultValue = fieldForm.getFieldValue('default_value');
        const dbType = selectedFieldType.actual_db_type;
        const tableName = selectedModel?.table_name || 'table_name';

        let colDef = `"${fieldName}"`;

        // Handle VARCHAR with max_length
        if (dbType === 'VARCHAR') {
            const maxLength = fieldConfigJson.max_length || 255;
            colDef += ` VARCHAR(${maxLength})`;
        } else if (dbType === 'NUMERIC') {
            // Handle NUMERIC with precision and scale
            const precision = fieldConfigJson.maximum_digits || fieldConfigJson.precision || 10;
            const scale = fieldConfigJson.allowed_decimal_places || fieldConfigJson.scale || 2;
            colDef += ` NUMERIC(${precision}, ${scale})`;
        } else {
            colDef += ` ${dbType}`;
        }

        if (isRequired && !fieldForm.getFieldValue('is_primary_key')) {
            colDef += ' NOT NULL';
        }

        if (defaultValue) {
            colDef += ` DEFAULT '${defaultValue}'`;
        }

        if (editingField) {
            return `ALTER TABLE public."${tableName}" ALTER COLUMN ${colDef};`;
        } else {
            return `ALTER TABLE public."${tableName}" ADD COLUMN ${colDef};`;
        }
    };

    const handleDeleteField = async (fieldId, fieldName) => {
        try {
            if (!selectedModel) return;

            setPendingChanges({
                type: 'delete_field',
                modelId: selectedModel.model_id,
                fieldId,
                fieldName
            });
            setConfirmModalVisible(true);
        } catch (error) {
            message.error('Failed to delete field: ' + (error.message || 'Unknown error'));
        }
    };

    const handleEditField = (record) => {
        setEditingField(record);
        fieldForm.resetFields();
        // Parse field_config_json (API may return it as JSON string) and pass a deep clone so the editor always gets options
        let config = {};
        if (record.field_config_json != null) {
            try {
                const raw = typeof record.field_config_json === 'string'
                    ? JSON.parse(record.field_config_json)
                    : record.field_config_json;
                config = JSON.parse(JSON.stringify(raw || {}));
            } catch (e) {
                console.error('Failed to parse field_config_json:', e);
            }
        }
        setFieldConfigJson(config);
        setFieldEditorDrawerVisible(true);
        // Form values are set in useEffect when drawer opens (ensures Form is mounted)
    };

    const openOrderingDrawer = () => {
        const sorted = [...fields].sort((a, b) => (a.order_no || 0) - (b.order_no || 0));
        setOrderingItems(
            sorted.map((f) => ({
                id: f.field_id,
                primary: f.display_name || f.field_name,
                secondary: f.field_name,
            }))
        );
        setFieldOrderingDrawerVisible(true);
    };

    const saveOrdering = async () => {
        try {
            if (!selectedModel) return;
            const fieldIds = orderingItems.map((i) => Number(i.id)).filter((n) => !Number.isNaN(n));
            if (fieldIds.length === 0) {
                message.warning('No valid field order to save');
                return;
            }
            await api.reorderDataModelFields(selectedModel.model_id, fieldIds);
            message.success('Field ordering updated');
            await loadModelFields(selectedModel.model_id);
            setFieldOrderingDrawerVisible(false);
        } catch (error) {
            const raw = error.response?.data?.detail ?? error.errorData?.description ?? error.message;
            const msg = Array.isArray(raw) ? raw.map((e) => e?.msg ?? e).join(', ') : (raw ?? (typeof error === 'object' ? JSON.stringify(error) : String(error)));
            message.error('Failed to update ordering: ' + (msg || 'Unknown error'));
        }
    };

    // Flattened field_config keys used in Excel/CSV export and rehydrated on import
    const FIELD_CONFIG_FLAT_KEYS = [
        'max_length', 'maximum_digits', 'allowed_decimal_places', 'precision', 'scale',
        'target_model', 'target_field', 'target_model_id', 'relation_type', 'display_field_name',
        'max_line_counts', 'min_value', 'max_value', 'multiple', 'fields',
    ];

    // Export: build array of field objects; useForeignKeyId = include field_type_id, else use type_name/type_code
    const getExportFields = (useForeignKeyId) => {
        const list = fields.map((f) => {
            const cfg = typeof f.field_config_json === 'string' ? (() => { try { return JSON.parse(f.field_config_json); } catch { return {}; } })() : (f.field_config_json || {});
            const base = {
                field_name: f.field_name,
                display_name: f.display_name,
                is_required: !!f.is_required,
                is_unique: !!f.is_unique,
                is_primary_key: !!f.is_primary_key,
                default_value: f.default_value || null,
                encryption_method: f.encryption_method || 'none',
                order_no: f.order_no ?? 0,
                field_config_json: cfg,
            };
            if (useForeignKeyId) base.field_type_id = f.field_type_id;
            else {
                base.type_name = f.type_name;
                base.type_code = f.type_code;
            }
            return base;
        });
        return list;
    };

    // Flat export for Excel/CSV: base columns + flattened field_config_json keys
    const getExportFieldsFlat = (useForeignKeyId) => {
        const list = getExportFields(useForeignKeyId);
        const allConfigKeys = new Set(FIELD_CONFIG_FLAT_KEYS);
        list.forEach((r) => {
            const cfg = r.field_config_json || {};
            Object.keys(cfg).forEach((k) => allConfigKeys.add(k));
        });
        const configKeys = [...allConfigKeys].sort();
        return list.map((r) => {
            const flat = { ...r };
            delete flat.field_config_json;
            const cfg = r.field_config_json || {};
            configKeys.forEach((k) => {
                const v = cfg[k];
                flat[k] = v === undefined || v === null ? '' : (typeof v === 'object' ? JSON.stringify(v) : v);
            });
            return flat;
        });
    };

    const handleExportDownload = (format, useForeignKeyId) => {
        const modelName = (selectedModel?.model_name || selectedModel?.display_name || 'fields').replace(/[^a-z0-9_-]/gi, '_');
        let blob; let filename;
        if (format === 'json') {
            const data = getExportFields(useForeignKeyId);
            blob = new Blob([JSON.stringify(data, null, 2)], { type: 'application/json' });
            filename = `${modelName}_fields.json`;
        } else if (format === 'yaml') {
            const data = getExportFields(useForeignKeyId);
            blob = new Blob([yaml.dump(data)], { type: 'text/yaml' });
            filename = `${modelName}_fields.yaml`;
        } else if (format === 'csv' || format === 'excel') {
            const dataFlat = getExportFieldsFlat(useForeignKeyId);
            const delimiter = format === 'csv' ? ',' : '\t';
            const headers = dataFlat.length ? Object.keys(dataFlat[0]) : [];
            const rows = dataFlat.map((r) => headers.map((h) => (r[h] != null ? String(r[h]) : '')));
            const body = format === 'csv'
                ? [headers.map(escapeCsvValue).join(delimiter), ...rows.map((row) => row.map(escapeCsvValue).join(delimiter))].join('\n')
                : [headers.join(delimiter), ...rows.map((row) => row.join(delimiter))].join('\n');
            blob = new Blob([body], { type: format === 'csv' ? 'text/csv' : 'text/tab-separated-values' });
            filename = format === 'csv' ? `${modelName}_fields.csv` : `${modelName}_fields.txt`;
        } else {
            const data = getExportFields(useForeignKeyId);
            blob = new Blob([JSON.stringify(data, null, 2)], { type: 'application/json' });
            filename = `${modelName}_fields.json`;
        }
        const a = document.createElement('a');
        a.href = URL.createObjectURL(blob);
        a.download = filename;
        a.click();
        URL.revokeObjectURL(a.href);
        message.success('Download started');
    };

    const escapeCsvValue = (v) => {
        const s = v == null ? '' : String(v);
        if (s.includes(',') || s.includes('"') || s.includes('\n') || s.includes('\r')) return '"' + s.replace(/"/g, '""') + '"';
        return s;
    };

    const handleCopyAs = (as) => {
        const selected = selectedFieldRowKeys.length ? fields.filter((f) => selectedFieldRowKeys.includes(f.field_id)) : fields;
        if (!selected.length) {
            message.warning('Select at least one field or leave none selected to copy all.');
            return;
        }
        const data = getExportFields(false);
        const dataFlat = getExportFieldsFlat(false);
        const subset = selected.map((f) => data.find((d) => d.field_name === f.field_name)).filter(Boolean);
        const subsetFlat = selected.map((f) => dataFlat.find((d) => d.field_name === f.field_name)).filter(Boolean);
        const tableName = selectedModel?.table_name || 'table_name';
        let text = '';
        if (as === 'excel' || as === 'csv') {
            const delimiter = as === 'csv' ? ',' : '\t';
            const headers = subsetFlat.length ? Object.keys(subsetFlat[0]) : [];
            const rows = subsetFlat.map((r) => headers.map((h) => (r[h] != null ? String(r[h]) : '')));
            if (as === 'csv') {
                text = [headers.map(escapeCsvValue).join(delimiter), ...rows.map((row) => row.map(escapeCsvValue).join(delimiter))].join('\n');
            } else {
                text = [headers.join(delimiter), ...rows.map((row) => row.join(delimiter))].join('\n');
            }
        } else if (as === 'json') {
            text = JSON.stringify(subset, null, 2);
        } else if (as === 'yaml') {
            text = yaml.dump(subset);
        } else if (as === 'sql') {
            const lines = selected.map((f) => {
                const dbType = f.actual_db_type || (fieldTypes.find((ft) => ft.field_type_id === f.field_type_id)?.actual_db_type) || 'TEXT';
                let col = `"${f.field_name}" ${dbType}`;
                if (f.is_required && !f.is_primary_key) col += ' NOT NULL';
                if (f.default_value) col += ` DEFAULT '${String(f.default_value).replace(/'/g, "''")}'`;
                return `ALTER TABLE public."${tableName}" ADD COLUMN ${col};`;
            });
            text = lines.join('\n');
        }
        navigator.clipboard.writeText(text).then(() => message.success(`Copied as ${as.toUpperCase()}`)).catch(() => message.error('Clipboard copy failed'));
    };

    const getFieldTypesReferenceText = (format) => {
        const list = (fieldTypes || []).map((ft) => ({
            field_type_id: ft.field_type_id,
            type_name: ft.type_name,
            type_code: ft.type_code,
            actual_db_type: ft.actual_db_type,
            category: ft.category || '',
        }));
        if (format === 'yaml') return yaml.dump(list);
        if (format === 'tab') {
            const headers = ['field_type_id', 'type_name', 'type_code', 'actual_db_type', 'category'];
            const rows = list.map((r) => headers.map((h) => (r[h] != null ? String(r[h]) : '')).join('\t'));
            return [headers.join('\t'), ...rows].join('\n');
        }
        if (format === 'csv') {
            const headers = ['field_type_id', 'type_name', 'type_code', 'actual_db_type', 'category'];
            const rows = list.map((r) => headers.map((h) => escapeCsvValue(r[h] != null ? String(r[h]) : '')).join(','));
            return [headers.map(escapeCsvValue).join(','), ...rows].join('\n');
        }
        return '';
    };

    const handleCopyFieldTypesRef = () => {
        const text = getFieldTypesReferenceText(fieldTypesRefFormat);
        if (!text) return;
        navigator.clipboard.writeText(text).then(() => message.success('Field types list copied')).catch(() => message.error('Copy failed'));
    };

    const columns = [
        {
            title: 'Model Name',
            dataIndex: 'model_name',
            key: 'model_name',
            width: 140,
            ellipsis: true,
            sorter: (a, b) => a.model_name.localeCompare(b.model_name),
        },
        {
            title: 'Display Name',
            dataIndex: 'display_name',
            key: 'display_name',
            width: 140,
            ellipsis: true,
        },
        {
            title: 'Table Name',
            dataIndex: 'table_name',
            key: 'table_name',
            width: 120,
            ellipsis: true,
            render: (text) => <Tag color="blue">{text}</Tag>,
        },
        {
            title: 'Model Scope',
            dataIndex: 'model_scope',
            key: 'model_scope',
            width: 100,
            render: (text) => <Tag>{text}</Tag>,
        },
        {
            title: 'Alias',
            dataIndex: 'table_alias',
            key: 'table_alias',
            width: 80,
            ellipsis: true,
            render: (text) => text ? <Tag color="purple">{text}</Tag> : <Text type="secondary">—</Text>,
        },
        {
            title: 'Fields',
            dataIndex: 'field_count',
            key: 'field_count',
            width: 70,
            render: (count) => <Text>{count || 0}</Text>,
        },
        {
            title: 'Status',
            dataIndex: 'is_active',
            key: 'is_active',
            width: 80,
            render: (isActive) => (
                <Tag color={isActive ? 'green' : 'red'}>
                    {isActive ? 'Active' : 'Inactive'}
                </Tag>
            ),
        },
        {
            title: 'Actions',
            key: 'actions',
            fixed: 'right',
            width: 200,
            render: (_, record) => (
                <Space>
                    <Button
                        type="link"
                        icon={<FieldTimeOutlined />}
                        onClick={() => handleViewFields(record)}
                    >
                        Fields
                    </Button>
                    <Button
                        type="link"
                        icon={<EditOutlined />}
                        onClick={() => handleEdit(record)}
                        disabled={record.is_system_model}
                    >
                        Edit
                    </Button>
                    <Button
                        type="link"
                        danger
                        icon={<DeleteOutlined />}
                        onClick={() => handleDelete(record.model_id)}
                        disabled={record.is_system_model}
                    >
                        Delete
                    </Button>
                </Space>
            ),
        },
    ];

    const fieldColumns = [
        {
            title: 'Field Name',
            dataIndex: 'field_name',
            key: 'field_name',
            width: 180,
        },
        {
            title: 'Display Name',
            dataIndex: 'display_name',
            key: 'display_name',
            width: 180,
        },
        {
            title: 'Type',
            dataIndex: 'type_name',
            key: 'type_name',
            width: 200,
            ellipsis: true,
            render: (text, record) => (
                <Space size="small" wrap={false}>
                    {record.input_type_image && (
                        <Image
                            src={getAssetUrl(record.input_type_image)}
                            alt={text}
                            width={24}
                            height={24}
                            preview={false}
                            style={{ objectFit: 'contain', flexShrink: 0 }}
                        />
                    )}
                    <Tag style={{ maxWidth: 160, overflow: 'hidden', textOverflow: 'ellipsis' }}>{text} ({record.actual_db_type})</Tag>
                </Space>
            ),
        },
        {
            title: 'Required',
            dataIndex: 'is_required',
            key: 'is_required',
            width: 90,
            render: (required) => required ? <Tag color="red">Yes</Tag> : <Tag>No</Tag>,
        },
        {
            title: 'Unique',
            dataIndex: 'is_unique',
            key: 'is_unique',
            width: 80,
            render: (unique) => unique ? <Tag color="blue">Yes</Tag> : null,
        },
        {
            title: 'Primary Key',
            dataIndex: 'is_primary_key',
            key: 'is_primary_key',
            width: 100,
            render: (pk) => pk ? <Tag color="green">PK</Tag> : null,
        },
        {
            title: 'Actions',
            key: 'actions',
            fixed: 'right',
            width: 140,
            render: (_, record) => (
                <Space>
                    <Button
                        type="link"
                        size="small"
                        icon={<EditOutlined />}
                        onClick={() => handleEditField(record)}
                        disabled={record.is_primary_key || isFlattenedSelectedModel}
                    >
                        Edit
                    </Button>
                    <Popconfirm
                        title="Are you sure? This will also delete the column from the table."
                        onConfirm={() => handleDeleteField(record.field_id, record.field_name)}
                        okText="Yes"
                        cancelText="No"
                        disabled={record.is_primary_key || isFlattenedSelectedModel}
                    >
                        <Button
                            type="link"
                            danger
                            size="small"
                            icon={<DeleteOutlined />}
                            disabled={record.is_primary_key || isFlattenedSelectedModel}
                        >
                            Delete
                        </Button>
                    </Popconfirm>
                </Space>
            ),
        },
    ];

    const filteredModels = useMemo(() => {
        const q = searchText.trim().toLowerCase();
        if (!q) return dataModels;
        return dataModels.filter((m) => {
            const a = (m.model_name || '').toLowerCase();
            const b = (m.display_name || '').toLowerCase();
            const c = (m.table_name || '').toLowerCase();
            return a.includes(q) || b.includes(q) || c.includes(q);
        });
    }, [dataModels, searchText]);

    return (
        <div style={{ padding: 0 }}>
            <Card>
                <div style={{ marginBottom: 16, display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                    <Title level={4} style={{ margin: 0 }}>
                        <DatabaseOutlined /> Data Models
                    </Title>
                    <Space>
                        <Input
                            placeholder="Search model name / display name / table name"
                            allowClear
                            value={searchText}
                            onChange={(e) => setSearchText(e.target.value)}
                            style={{ width: 360 }}
                        />
                        <Button
                            icon={<ReloadOutlined />}
                            onClick={loadDataModels}
                            loading={loading}
                        >
                            Refresh
                        </Button>
                        <Button
                            type="primary"
                            icon={<PlusOutlined />}
                            onClick={handleCreate}
                        >
                            Create Data Model
                        </Button>
                    </Space>
                </div>

                <Table
                    columns={columns}
                    dataSource={filteredModels}
                    rowKey="model_id"
                    loading={loading}
                    pagination={false}
                    scroll={{ x: 830 }}
                />
            </Card>

            {/* Create/Edit Modal */}
            <Modal
                title={editingModel ? 'Edit Data Model' : 'Create Data Model'}
                open={modalVisible}
                onCancel={() => setModalVisible(false)}
                footer={null}
                width={800}
            >
                <Form
                    form={form}
                    layout="vertical"
                    onFinish={handleSubmit}
                >
                    <Row gutter={16}>
                        <Col span={12}>
                            <Form.Item
                                name="display_name"
                                label="Display Name"
                                rules={[{ required: true, message: 'Please enter display name' }]}
                            >
                                <Input
                                    placeholder="e.g., Users"
                                    onChange={(e) => {
                                        if (!editingModel) {
                                            // Auto-populate model_name and table_name from display_name
                                            const displayName = e.target.value;
                                            const modelName = displayName
                                                .trim()
                                                .toLowerCase()
                                                .replace(/\s+/g, '_')
                                                .replace(/[^a-z0-9_]/g, '');
                                            // model_name and table_name must be the same
                                            form.setFieldsValue({
                                                model_name: modelName,
                                                table_name: modelName  // Enforce same value
                                            });

                                            // Auto-populate id field name based on first word
                                            const firstWord = displayName.trim().split(/\s+/)[0].toLowerCase();
                                            const idFieldName = firstWord ? `${firstWord}_id` : 'id';
                                            form.setFieldsValue({ id_field_name: idFieldName });
                                        }
                                    }}
                                />
                            </Form.Item>
                        </Col>
                        <Col span={12}>
                            <Form.Item
                                name="model_name"
                                label="Model Name"
                                rules={[
                                    { required: true, message: 'Please enter model name' },
                                    {
                                        validator: (_, value) => {
                                            const tableName = form.getFieldValue('table_name');
                                            if (value && tableName && value !== tableName) {
                                                return Promise.reject(new Error('Model name and table name must be the same'));
                                            }
                                            return Promise.resolve();
                                        }
                                    }
                                ]}
                            >
                                <Input
                                    disabled={!!editingModel}
                                    placeholder="Auto-generated from display name"
                                    onChange={(e) => {
                                        // Keep table_name in sync with model_name (for both create and edit)
                                        form.setFieldsValue({ table_name: e.target.value });
                                    }}
                                />
                            </Form.Item>
                        </Col>
                    </Row>

                    {!editingModel && (
                        <Row gutter={16}>
                            <Col span={12}>
                                <Form.Item
                                    name="id_field_name"
                                    label="ID Field Name"
                                    initialValue="id"
                                    rules={[{ required: true, message: 'Please enter ID field name' }]}
                                >
                                    <Input placeholder="Auto-generated from display name" />
                                </Form.Item>
                            </Col>
                        </Row>
                    )}

                    <Row gutter={16}>
                        <Col span={12}>
                            <Form.Item
                                name="table_name"
                                label="Table Name"
                                rules={[
                                    { required: true, message: 'Please enter table name' },
                                    {
                                        validator: (_, value) => {
                                            const modelName = form.getFieldValue('model_name');
                                            if (value && modelName && value !== modelName) {
                                                return Promise.reject(new Error('Table name and model name must be the same'));
                                            }
                                            return Promise.resolve();
                                        }
                                    }
                                ]}
                            >
                                <Input
                                    disabled={!!editingModel}
                                    placeholder="Auto-generated from display name"
                                    onChange={(e) => {
                                        if (!editingModel) {
                                            // Keep model_name in sync with table_name
                                            form.setFieldsValue({ model_name: e.target.value });
                                        } else {
                                            // For editing, also sync model_name with table_name
                                            form.setFieldsValue({ model_name: e.target.value });
                                        }
                                    }}
                                />
                            </Form.Item>
                        </Col>
                        <Col span={12}>
                            <Form.Item
                                name="model_scope"
                                label="Model Scope"
                                rules={[{ required: true }]}
                            >
                                <Select>
                                    <Option value="saas">SaaS</Option>
                                    <Option value="tenant">Tenant</Option>
                                    <Option value="both">Both</Option>
                                </Select>
                            </Form.Item>
                        </Col>
                    </Row>

                    <Row gutter={16}>
                        <Col span={12}>
                            <Form.Item
                                name="table_alias"
                                label="Table Alias"
                            >
                                <Input placeholder="e.g., sc" />
                            </Form.Item>
                        </Col>
                    </Row>

                    <Row gutter={16}>
                        <Col span={8}>
                            <Form.Item
                                name="is_public"
                                valuePropName="checked"
                            >
                                <Switch checkedChildren="Public" unCheckedChildren="Private" />
                            </Form.Item>
                        </Col>
                        <Col span={8}>
                            <Form.Item
                                name="is_active"
                                valuePropName="checked"
                                initialValue={true}
                            >
                                <Switch checkedChildren="Active" unCheckedChildren="Inactive" />
                            </Form.Item>
                        </Col>
                        <Col span={8}>
                            <Form.Item
                                name="is_system_model"
                                valuePropName="checked"
                            >
                                <Switch checkedChildren="System" unCheckedChildren="Custom" disabled={!!editingModel} />
                            </Form.Item>
                        </Col>
                    </Row>

                    <Form.Item
                        name="description"
                        label="Description"
                    >
                        <TextArea rows={3} placeholder="Description of the data model" />
                    </Form.Item>

                    <Form.Item>
                        <Space>
                            <Button type="primary" htmlType="submit">
                                {editingModel ? 'Update' : 'Create'}
                            </Button>
                            <Button onClick={() => setModalVisible(false)}>Cancel</Button>
                        </Space>
                    </Form.Item>
                </Form>
            </Modal>

            {/* Fields Drawer */}
            <Drawer
                title={`Fields: ${selectedModel?.display_name || selectedModel?.model_name}`}
                placement="right"
                width={1000}
                open={fieldDrawerVisible}
                onClose={() => {
                    setFieldDrawerVisible(false);
                    setFieldEditorDrawerVisible(false);
                    setFieldOrderingDrawerVisible(false);
                    setSelectedModel(null);
                    setFields([]);
                    setOrderingItems([]);
                    setEditingField(null);
                    setSelectedFieldRowKeys([]);
                    setImportModalVisible(false);
                    setFieldTypesRefVisible(false);
                }}
            >
                <div style={{ marginBottom: 16 }}>
                    <Space wrap>
                        <Button
                            type="primary"
                            icon={<PlusOutlined />}
                            onClick={openAddFieldDrawer}
                            disabled={isFlattenedSelectedModel}
                        >
                            Add Field
                        </Button>
                        <Button
                            icon={<OrderedListOutlined />}
                            onClick={openOrderingDrawer}
                            disabled={!fields.length || isFlattenedSelectedModel}
                        >
                            Ordering
                        </Button>
                        <Button icon={<ImportOutlined />} onClick={() => setImportModalVisible(true)} disabled={isFlattenedSelectedModel}>
                            Import
                        </Button>
                        <Dropdown
                            menu={{
                                items: [
                                    { key: 'json-label', label: 'Download JSON (type name)', onClick: () => handleExportDownload('json', false) },
                                    { key: 'json-fk', label: 'Download JSON (foreign key id)', onClick: () => handleExportDownload('json', true) },
                                    { key: 'yaml-label', label: 'Download YAML (type name)', onClick: () => handleExportDownload('yaml', false) },
                                    { key: 'yaml-fk', label: 'Download YAML (foreign key id)', onClick: () => handleExportDownload('yaml', true) },
                                    { key: 'csv-label', label: 'Download CSV (type name, flattened)', onClick: () => handleExportDownload('csv', false) },
                                    { key: 'excel-label', label: 'Download Excel / tab (type name, flattened)', onClick: () => handleExportDownload('excel', false) },
                                ],
                            }}
                        >
                            <Button icon={<DownloadOutlined />}>Export / Download</Button>
                        </Dropdown>
                        <Dropdown
                            menu={{
                                items: [
                                    { key: 'excel', label: 'Excel friendly (tab-separated)', onClick: () => handleCopyAs('excel') },
                                    { key: 'csv', label: 'Comma separated (CSV)', onClick: () => handleCopyAs('csv') },
                                    { key: 'json', label: 'JSON', onClick: () => handleCopyAs('json') },
                                    { key: 'yaml', label: 'YAML', onClick: () => handleCopyAs('yaml') },
                                    { key: 'sql', label: 'SQL (ALTER TABLE)', onClick: () => handleCopyAs('sql') },
                                ],
                            }}
                        >
                            <Button icon={<CopyOutlined />}>
                                Copy {selectedFieldRowKeys.length ? `(${selectedFieldRowKeys.length})` : ''}
                            </Button>
                        </Dropdown>
                        <Button
                            icon={<UnorderedListOutlined />}
                            onClick={() => setFieldTypesRefVisible(true)}
                            title="View or copy the list of field types (for import/export reference)"
                        >
                            Field types reference
                        </Button>
                    </Space>
                    {isFlattenedSelectedModel && (
                        <Alert
                            type="warning"
                            showIcon
                            style={{ marginTop: 12 }}
                            message="This is a flattened system model. Fields are managed by Flattened Datas policies and are read-only here."
                        />
                    )}
                </div>

                <Modal
                    title="Field types reference"
                    open={fieldTypesRefVisible}
                    onCancel={() => setFieldTypesRefVisible(false)}
                    width={640}
                    footer={[
                        <Button key="close" onClick={() => setFieldTypesRefVisible(false)}>Close</Button>,
                        <Button key="copy" type="primary" icon={<CopyOutlined />} onClick={handleCopyFieldTypesRef}>
                            Copy to clipboard
                        </Button>,
                    ]}
                >
                    <div style={{ marginBottom: 12 }}>
                        <Segmented
                            options={[
                                { label: 'YAML', value: 'yaml' },
                                { label: 'Tab-separated', value: 'tab' },
                                { label: 'Comma-separated', value: 'csv' },
                            ]}
                            value={fieldTypesRefFormat}
                            onChange={setFieldTypesRefFormat}
                        />
                    </div>
                    <Input.TextArea
                        readOnly
                        value={getFieldTypesReferenceText(fieldTypesRefFormat)}
                        rows={14}
                        style={{ fontFamily: 'monospace', fontSize: 12 }}
                    />
                </Modal>

                <Table
                    rowSelection={{
                        selectedRowKeys: selectedFieldRowKeys,
                        onChange: (keys) => setSelectedFieldRowKeys(keys),
                    }}
                    columns={fieldColumns}
                    dataSource={fields}
                    rowKey="field_id"
                    pagination={false}
                    size="small"
                    scroll={{ x: 970 }}
                />

                <FieldsImportModal
                    visible={importModalVisible}
                    onClose={() => setImportModalVisible(false)}
                    modelId={selectedModel?.model_id}
                    modelName={selectedModel?.display_name || selectedModel?.model_name}
                    fieldTypes={fieldTypes}
                    dataModels={dataModels}
                    existingFields={fields}
                    onImportDone={() => selectedModel && loadModelFields(selectedModel.model_id)}
                />
            </Drawer>

            {/* Field Editor Drawer (Add/Edit) */}
            <Drawer
                key={editingField ? `edit-${editingField.field_id}` : 'add'}
                title={editingField ? `Edit Field: ${editingField.field_name}` : 'Add Field'}
                placement="right"
                width={520}
                open={fieldEditorDrawerVisible}
                onClose={() => {
                    setFieldEditorDrawerVisible(false);
                    setEditingField(null);
                    setFieldConfigJson({});
                    setSelectedFieldType(null);
                }}
                mask={false}
            >
                <Form
                    form={fieldForm}
                    layout="vertical"
                    onFinish={handleFieldSubmit}
                >
                    <Form.Item
                        name="display_name"
                        label="Display Name"
                        rules={[{ required: true, message: 'Please enter display name' }]}
                    >
                        <Input
                            placeholder="e.g., Email Address"
                            onChange={(e) => {
                                if (!editingField) {
                                    const displayName = e.target.value;
                                    const fieldName = displayName
                                        .trim()
                                        .toLowerCase()
                                        .replace(/\s+/g, '_');
                                    fieldForm.setFieldsValue({ field_name: fieldName });
                                }
                            }}
                        />
                    </Form.Item>

                    <Form.Item
                        name="field_name"
                        label="Field Name"
                        rules={[{ required: true, message: 'Please enter field name' }]}
                    >
                        <Input disabled={!!editingField} placeholder="Auto-generated from display name" />
                    </Form.Item>

                    <Form.Item
                        name="field_type_id"
                        label="Field Type"
                        initialValue={editingField ? Number(editingField.field_type_id) : undefined}
                        rules={[{ required: true, message: 'Please select field type' }]}
                    >
                        <Select
                            showSearch
                            placeholder="Select field type"
                            {...(editingField && editingField.field_type_id != null && {
                                value: fieldForm.getFieldValue('field_type_id') ?? Number(editingField.field_type_id)
                            })}
                            optionFilterProp="label"
                            filterOption={(input, option) =>
                                (option?.label ?? '').toString().toLowerCase().includes(input.toLowerCase())
                            }
                            onChange={(value) => {
                                fieldForm.setFieldsValue({ field_type_id: value });
                                const ft = fieldTypes.find(f => f.field_type_id === value);
                                setSelectedFieldType(ft);
                                // Reset config when field type changes
                                if (ft?.default_props_json) {
                                    try {
                                        const defaultConfig = typeof ft.default_props_json === 'string'
                                            ? JSON.parse(ft.default_props_json)
                                            : ft.default_props_json;
                                        setFieldConfigJson(defaultConfig || {});
                                    } catch (e) {
                                        setFieldConfigJson({});
                                    }
                                } else {
                                    setFieldConfigJson({});
                                }
                            }}
                        >
                            {fieldTypes.map(ft => (
                                <Option
                                    key={ft.field_type_id}
                                    value={ft.field_type_id}
                                    label={`${ft.type_name} (${ft.actual_db_type})`}
                                >
                                    <Space>
                                        {ft.input_type_image && (
                                            <img
                                                src={getAssetUrl(ft.input_type_image)}
                                                alt={ft.type_name}
                                                width={20}
                                                height={20}
                                                style={{ objectFit: 'contain', verticalAlign: 'middle' }}
                                                onError={(e) => {
                                                    e.target.style.display = 'none';
                                                }}
                                            />
                                        )}
                                        <span>{ft.type_name} ({ft.actual_db_type})</span>
                                    </Space>
                                </Option>
                            ))}
                        </Select>
                        {selectedFieldType?.input_type_image && (
                            <div style={{ marginTop: 8, textAlign: 'center' }}>
                                <Image
                                    src={getAssetUrl(selectedFieldType.input_type_image)}
                                    alt={selectedFieldType.type_name}
                                    width={64}
                                    height={64}
                                    preview={false}
                                    style={{ objectFit: 'contain' }}
                                />
                            </div>
                        )}
                    </Form.Item>

                    {selectedFieldType && (
                        <Form.Item label="Field Configuration">
                            <FieldConfigJsonEditor
                                key={editingField ? `field-${editingField.field_id}` : 'field-new'}
                                fieldTypeId={selectedFieldType.field_type_id}
                                fieldTypeCode={selectedFieldType.type_code}
                                defaultPropsJson={selectedFieldType.default_props_json}
                                value={fieldConfigJson}
                                onChange={setFieldConfigJson}
                            />
                        </Form.Item>
                    )}

                    <Row gutter={16}>
                        <Col span={12}>
                            <Form.Item
                                name="is_required"
                                valuePropName="checked"
                            >
                                <Switch checkedChildren="Required" unCheckedChildren="Optional" />
                            </Form.Item>
                        </Col>
                        <Col span={12}>
                            <Form.Item
                                name="is_unique"
                                valuePropName="checked"
                            >
                                <Switch checkedChildren="Unique" unCheckedChildren="Not Unique" />
                            </Form.Item>
                        </Col>
                    </Row>

                    <Form.Item
                        name="encryption_method"
                        label="Encryption"
                    >
                        <Select>
                            <Option value="none">None</Option>
                            <Option value="aes">AES</Option>
                            <Option value="xor_cipher">XOR Cipher</Option>
                        </Select>
                    </Form.Item>

                    <Form.Item
                        name="default_value"
                        label="Default Value"
                    >
                        <Input placeholder="Default value (optional)" />
                    </Form.Item>

                    {generateSQLPreview() && (
                        <Form.Item label="SQL Preview">
                            <TextArea
                                value={generateSQLPreview()}
                                readOnly
                                rows={2}
                                style={{ fontFamily: 'monospace', fontSize: '12px' }}
                            />
                        </Form.Item>
                    )}

                    <Form.Item>
                        <Space>
                            <Button type="primary" htmlType="submit">
                                {editingField ? 'Update Field' : 'Add Field'}
                            </Button>
                            <Button onClick={() => {
                                fieldForm.resetFields();
                                setFieldConfigJson({});
                                setSelectedFieldType(null);
                            }}>Reset</Button>
                        </Space>
                    </Form.Item>
                </Form>
            </Drawer>

            {/* Field Ordering Drawer */}
            <Drawer
                title="Field Ordering"
                placement="right"
                width={520}
                open={fieldOrderingDrawerVisible}
                onClose={() => setFieldOrderingDrawerVisible(false)}
                mask={false}
                extra={
                    <Space>
                        <Button onClick={() => setFieldOrderingDrawerVisible(false)}>Cancel</Button>
                        <Button type="primary" onClick={saveOrdering}>Save</Button>
                    </Space>
                }
            >
                <VCDragSortList
                    items={orderingItems}
                    onReorder={setOrderingItems}
                />
            </Drawer>

            {/* Delete Model Warning Modal */}
            <Modal
                title="Delete Data Model"
                open={deleteCheckModalVisible}
                onCancel={() => {
                    setDeleteCheckModalVisible(false);
                    setDeleteCheckInfo(null);
                    setPendingDeleteModelId(null);
                }}
                footer={null}
                width={700}
            >
                {deleteCheckInfo && (
                    <div>
                        <Alert
                            message="Warning: This action cannot be undone"
                            description={
                                <div>
                                    <p><strong>Model:</strong> {deleteCheckInfo.display_name || deleteCheckInfo.model_name}</p>
                                    <p><strong>Table:</strong> {deleteCheckInfo.table_name}</p>
                                </div>
                            }
                            type="warning"
                            showIcon
                            style={{ marginBottom: 16 }}
                        />

                        {/* Row Count */}
                        <div style={{ marginBottom: 16 }}>
                            <Text strong>Data Records:</Text>
                            <div style={{ marginTop: 8 }}>
                                {deleteCheckInfo.row_count === 0 ? (
                                    <Tag color="green">No records (0 rows) - Safe to delete</Tag>
                                ) : (
                                    <div>
                                        <Tag color="red">{deleteCheckInfo.row_count} record(s) found</Tag>
                                        <div style={{ marginTop: 8 }}>
                                            <Text type="danger">
                                                This model contains {deleteCheckInfo.row_count} record(s).
                                                Deleting will permanently remove all data.
                                            </Text>
                                        </div>
                                    </div>
                                )}
                            </div>
                        </div>

                        {/* Relations */}
                        {deleteCheckInfo.relations && deleteCheckInfo.relations.length > 0 && (
                            <div style={{ marginBottom: 16 }}>
                                <Text strong>Referenced by Relation Fields:</Text>
                                <div style={{ marginTop: 8 }}>
                                    <Alert
                                        message="This model is used in relation fields"
                                        description={
                                            <ul style={{ marginTop: 8, paddingLeft: 20 }}>
                                                {deleteCheckInfo.relations.map((rel, idx) => (
                                                    <li key={idx}>
                                                        <Text>
                                                            <strong>{rel.display_name || rel.model_name}</strong>
                                                            {' → '}
                                                            <strong>{rel.field_display_name || rel.field_name}</strong>
                                                        </Text>
                                                    </li>
                                                ))}
                                            </ul>
                                        }
                                        type="error"
                                        showIcon
                                    />
                                    <div style={{ marginTop: 8 }}>
                                        <Text type="danger">
                                            Please unlink these relation fields before deleting this model.
                                        </Text>
                                    </div>
                                </div>
                            </div>
                        )}

                        {/* Other References */}
                        {deleteCheckInfo.other_references && deleteCheckInfo.other_references.length > 0 && (
                            <div style={{ marginBottom: 16 }}>
                                <Text strong>Other references</Text>
                                <div style={{ marginTop: 8 }}>
                                    {deleteCheckInfo.other_references.map((ref, idx) => (
                                        <div key={idx} style={{ marginBottom: 12 }}>
                                            <Tag color="orange">{ref.type}: {ref.count}</Tag>
                                            {ref.reason && (
                                                <div style={{ marginTop: 4, color: 'rgba(0,0,0,0.65)', fontSize: 13 }}>
                                                    {ref.reason}
                                                </div>
                                            )}
                                        </div>
                                    ))}
                                </div>
                            </div>
                        )}

                        {/* Action Buttons */}
                        <div style={{ marginTop: 24, textAlign: 'right' }}>
                            <Space>
                                <Button onClick={() => {
                                    setDeleteCheckModalVisible(false);
                                    setDeleteCheckInfo(null);
                                    setPendingDeleteModelId(null);
                                }}>
                                    Cancel
                                </Button>
                                {deleteCheckInfo.can_delete || (deleteCheckInfo.row_count > 0 && deleteCheckInfo.relations.length === 0) ? (
                                    <Button
                                        type="primary"
                                        danger
                                        onClick={() => {
                                            const hasData = deleteCheckInfo.row_count > 0;
                                            confirmDeleteModel(true, hasData);
                                        }}
                                    >
                                        {deleteCheckInfo.row_count > 0
                                            ? `Delete Model & ${deleteCheckInfo.row_count} Record(s)`
                                            : 'Delete Model'}
                                    </Button>
                                ) : (
                                    <Button type="primary" disabled>
                                        Cannot Delete
                                    </Button>
                                )}
                            </Space>
                        </div>
                    </div>
                )}
            </Modal>

            {/* Confirmation Modal for Table Changes */}
            <Modal
                title="Confirm Table Modification"
                open={confirmModalVisible}
                onOk={handleConfirmChanges}
                onCancel={() => {
                    setConfirmModalVisible(false);
                    setPendingChanges(null);
                }}
                okText="Confirm & Apply"
                cancelText="Cancel"
                width={600}
                okButtonProps={{ danger: pendingChanges?.type === 'delete_field' }}
            >
                {pendingChanges && (
                    <div>
                        <Alert
                            message="Warning: This will modify the database table"
                            description={
                                pendingChanges.type === 'update' ? (
                                    <div>
                                        <p>You are about to rename the table:</p>
                                        <p><strong>{pendingChanges.oldTableName}</strong> → <strong>{pendingChanges.newTableName}</strong></p>
                                        <p>This action cannot be easily undone. Are you sure you want to continue?</p>
                                    </div>
                                ) : pendingChanges.type === 'add_field' ? (
                                    <div>
                                        <p>You are about to add a new column to the table:</p>
                                        <p><strong>Field:</strong> {pendingChanges.values.field_name}</p>
                                        <p>This will modify the table structure. Are you sure you want to continue?</p>
                                    </div>
                                ) : pendingChanges.type === 'delete_field' ? (
                                    <div>
                                        <p>You are about to delete a field and remove its column from the table:</p>
                                        <p><strong>Field:</strong> {pendingChanges.fieldName}</p>
                                        <p><strong style={{ color: 'red' }}>This will permanently delete the column and all its data!</strong></p>
                                        <p>Are you sure you want to continue?</p>
                                    </div>
                                ) : null
                            }
                            type="warning"
                            showIcon
                            icon={<ExclamationCircleOutlined />}
                        />
                    </div>
                )}
            </Modal>
        </div>
    );
};

export default DataModels;
