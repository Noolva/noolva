/**
 * Data Import Modal for Data Model Fields
 * Two-panel: Left = input (paste/upload, options), Right = preview & validation
 * Features: Dry run, Import preview mandatory before save, Upsert, Flatten relations, Validate FK labels
 */
import React, { useState, useCallback } from 'react';
import {
    Modal,
    Row,
    Col,
    Input,
    Button,
    Space,
    Table,
    Alert,
    Checkbox,
    Upload,
    message,
    Typography,
    Tooltip,
} from 'antd';
import { InboxOutlined, CheckCircleOutlined, CloseCircleOutlined } from '@ant-design/icons';
import * as yaml from 'js-yaml';
import { api } from '../../../utils/api';

const { TextArea } = Input;
const { Text } = Typography;
const { Dragger } = Upload;

const SYSTEM_FIELDS = ['idate', 'created_by', 'last_updated'];

// Flattened field_config keys (must match DataModels FIELD_CONFIG_FLAT_KEYS for round-trip)
const FIELD_CONFIG_FLAT_KEYS = [
    'max_length', 'maximum_digits', 'allowed_decimal_places', 'precision', 'scale',
    'target_model', 'target_field', 'target_model_id', 'relation_type', 'display_field_name',
    'max_line_counts', 'min_value', 'max_value', 'multiple', 'fields',
];

// Parse a single line: tab-separated or CSV (comma with optional quoted values)
function parseDelimitedLine(line) {
    const trim = (s) => String(s).trim().replace(/^["']|["']$/g, '');
    if (line.includes('\t') && !line.includes('"')) return line.split('\t').map(trim);
    if (line.includes(',') && (line.includes('"') || line.includes('\t'))) {
        const sep = line.includes('\t') ? '\t' : ',';
        const out = [];
        let cur = '';
        let inQuotes = false;
        for (let i = 0; i < line.length; i++) {
            const c = line[i];
            if (c === '"') {
                inQuotes = !inQuotes;
                if (line[i + 1] === '"') { cur += '"'; i++; }
            } else if ((c === sep && !inQuotes)) {
                out.push(trim(cur));
                cur = '';
            } else cur += c;
        }
        out.push(trim(cur));
        return out;
    }
    if (line.includes('\t')) return line.split('\t').map(trim);
    if (line.includes(',')) {
        const out = [];
        let cur = '';
        let inQuotes = false;
        for (let i = 0; i < line.length; i++) {
            const c = line[i];
            if (c === '"') {
                inQuotes = !inQuotes;
                if (line[i + 1] === '"') { cur += '"'; i++; }
            } else if (c === ',' && !inQuotes) {
                out.push(trim(cur));
                cur = '';
            } else cur += c;
        }
        out.push(trim(cur));
        return out;
    }
    return [trim(line)];
}

function parseInput(raw, fieldTypes) {
    let trimmed = (raw || '').trim();
    if (!trimmed) return { records: [], error: 'Paste CSV, JSON, or YAML content or upload a file.' };
    if (trimmed.charCodeAt(0) === 0xFEFF) trimmed = trimmed.slice(1).trim();

    // Try JSON
    if ((trimmed.startsWith('[') || trimmed.startsWith('{'))) {
        try {
            const data = JSON.parse(trimmed);
            const records = Array.isArray(data) ? data : [data];
            return { records, error: null };
        } catch (e) {
            return { records: [], error: `JSON parse error: ${e.message}` };
        }
    }

    // Try CSV/TSV before YAML so pasted tab/comma data isn't mis-parsed as YAML
    const lines = trimmed.split(/\r?\n/).filter(Boolean);
    const looksLikeDelimited = lines.length >= 1 && (
        (lines[0].includes('\t') && lines[0].split('\t').length > 2) ||
        (lines[0].includes(',') && lines[0].split(',').length > 2)
    );
    if (looksLikeDelimited) {
        if (lines.length < 1) return { records: [], error: 'Paste at least a header row.' };
        const headers = parseDelimitedLine(lines[0]);
        const firstHeader = (headers[0] || '').trim().replace(/^\uFEFF/, '');
        if (firstHeader.toLowerCase() === 'field_name' || headers.length > 3) {
            const records = [];
            for (let i = 1; i < lines.length; i++) {
                const line = lines[i];
                if (line.trim() === '') continue;
                const values = parseDelimitedLine(line);
                const row = {};
                const cleanHeaders = headers.map((h) => (h || '').trim().replace(/^\uFEFF/, ''));
                cleanHeaders.forEach((h, j) => { row[h] = values[j] !== undefined ? values[j] : ''; });
                const firstVal = (row[firstHeader] != null ? String(row[firstHeader]) : '').trim();
                if (firstVal === '') continue;
                records.push(row);
            }
            if (records.length === 0) return { records: [], error: 'Add at least one data row below the header.' };
            return { records, error: null };
        }
    }

    // Try YAML (js-yaml)
    try {
        const data = yaml.load(trimmed);
        if (data == null) return { records: [], error: 'YAML parsed to empty value.' };
        const records = Array.isArray(data) ? data : [data];
        return { records, error: null };
    } catch (e) {
        if (!looksLikeDelimited) return { records: [], error: 'Could not parse as JSON, YAML, or CSV/TSV. Check format.' };
    }

    // Fallback CSV: any multi-column first line
    if (lines.length >= 1) {
        const headers = parseDelimitedLine(lines[0]);
        const cleanHeaders = headers.map((h) => (h || '').trim().replace(/^\uFEFF/, ''));
        const firstHeader = cleanHeaders[0] || '';
        const records = [];
        for (let i = 1; i < lines.length; i++) {
            const line = lines[i];
            if (line.trim() === '') continue;
            const values = parseDelimitedLine(line);
            const row = {};
            cleanHeaders.forEach((h, j) => { row[h] = values[j] !== undefined ? values[j] : ''; });
            const firstVal = (row[firstHeader] != null ? String(row[firstHeader]) : '').trim();
            if (firstVal === '') continue;
            records.push(row);
        }
        if (records.length > 0) return { records, error: null };
    }
    return { records: [], error: 'Add at least one data row below the header.' };
}

function normalizeRecord(row, fieldTypes, options) {
    const {
        validateFkLabels = true,
        flattenRelations = false,
    } = options || {};
    const errors = [];
    const warnings = [];

    const getStr = (v) => (v == null || v === '') ? '' : String(v).trim();
    const getBool = (v) => {
        if (v == null || v === '') return false;
        const s = String(v).toLowerCase();
        return s === 'true' || s === '1' || s === 'yes' || s === 'y';
    };
    const getInt = (v) => {
        if (v == null || v === '') return undefined;
        const n = parseInt(String(v), 10);
        return Number.isNaN(n) ? undefined : n;
    };

    let field_name = getStr(row.field_name || row.fieldName);
    const display_name = getStr(row.display_name || row.displayName) || field_name;
    if (!field_name) {
        errors.push('field_name is required');
        return { normalized: null, errors, warnings };
    }
    field_name = field_name.toLowerCase().replace(/\s+/g, '_').replace(/[^a-z0-9_]/g, '');
    if (!field_name) {
        errors.push('field_name invalid');
        return { normalized: null, errors, warnings };
    }
    if (SYSTEM_FIELDS.includes(field_name)) {
        errors.push(`Reserved field name: ${field_name}`);
        return { normalized: null, errors, warnings };
    }

    let field_type_id = getInt(row.field_type_id);
    const type_name = getStr(row.type_name || row.typeName);
    const type_code = getStr(row.type_code || row.typeCode);
    if (field_type_id == null && (type_name || type_code)) {
        const ft = fieldTypes.find(f =>
            (type_name && (f.type_name || '').toLowerCase() === type_name.toLowerCase()) ||
            (type_code && (f.type_code || '').toLowerCase() === type_code.toLowerCase())
        );
        if (ft) field_type_id = ft.field_type_id;
        else if (validateFkLabels) errors.push(`Unknown type: ${type_name || type_code}`);
    }
    if (field_type_id == null) errors.push('field_type_id or type_name/type_code required');

    let field_config_json = row.field_config_json;
    if (typeof field_config_json === 'string') {
        try {
            field_config_json = JSON.parse(field_config_json);
        } catch {
            field_config_json = {};
        }
    }
    if (!field_config_json || typeof field_config_json !== 'object') field_config_json = {};

    // Merge flattened config columns (from Excel/CSV export) into field_config_json
    const numericConfigKeys = ['max_length', 'maximum_digits', 'allowed_decimal_places', 'precision', 'scale', 'max_line_counts', 'min_value', 'max_value'];
    FIELD_CONFIG_FLAT_KEYS.forEach((k) => {
        const v = row[k];
        if (v === undefined || v === null) return;
        const s = String(v).trim();
        if (s === '') return;
        if (numericConfigKeys.includes(k)) {
            const n = parseInt(s, 10);
            if (!Number.isNaN(n)) field_config_json[k] = n;
            else field_config_json[k] = s;
        } else if (k === 'multiple') {
            field_config_json[k] = s.toLowerCase() === 'true' || s === '1';
        } else if (k === 'fields' && (s.startsWith('[') || s.startsWith('{'))) {
            try {
                field_config_json[k] = JSON.parse(s);
            } catch {
                field_config_json[k] = s;
            }
        } else {
            field_config_json[k] = s;
        }
    });

    // Resolve target_model (name) to target_model_id when we have dataModels
    if (options.dataModels && field_config_json.target_model && String(field_config_json.target_model).trim() !== '') {
        const name = String(field_config_json.target_model).trim().toLowerCase();
        const id = getInt(field_config_json.target_model);
        if (id != null) {
            field_config_json.target_model_id = id;
        } else {
            const model = (options.dataModels || []).find(m =>
                (m.model_name || '').toLowerCase() === name || (m.table_name || '').toLowerCase() === name
            );
            if (model) field_config_json.target_model_id = model.model_id;
        }
    }

    // Flatten relations: if row has target_model_name / related_model_id etc., build config
    if (flattenRelations && (row.target_model_name || row.related_model_id != null || row.target_model_id != null)) {
        const target = row.target_model_name || row.target_model_id || row.related_model_id;
        if (target != null && target !== '') {
            const id = getInt(target);
            if (id != null) {
                field_config_json.target_model_id = id;
            } else {
                // Resolve model name to id via dataModels (passed from parent)
                const name = String(target).trim().toLowerCase();
                const model = (options.dataModels || []).find(m =>
                    (m.model_name || '').toLowerCase() === name || (m.table_name || '').toLowerCase() === name
                );
                if (model) field_config_json.target_model_id = model.model_id;
                else field_config_json.target_model_id = target;
            }
        }
        if (row.display_field_name != null) field_config_json.display_field_name = getStr(row.display_field_name);
        if (row.relation_type != null) field_config_json.relation_type = getStr(row.relation_type) || 'many_to_one';
    }

    const normalized = {
        field_name,
        display_name: display_name || field_name,
        field_type_id: field_type_id ?? 0,
        field_config_json: field_config_json || {},
        is_required: getBool(row.is_required),
        is_unique: getBool(row.is_unique),
        is_primary_key: getBool(row.is_primary_key),
        default_value: getStr(row.default_value) || null,
        encryption_method: getStr(row.encryption_method) || 'none',
        order_no: getInt(row.order_no) ?? 0,
    };
    return { normalized: errors.length ? null : normalized, errors, warnings };
}

export function FieldsImportModal({
    visible,
    onClose,
    modelId,
    modelName,
    fieldTypes = [],
    dataModels = [],
    existingFields = [],
    onImportDone,
}) {
    const [rawInput, setRawInput] = useState('');
    const [dryRun, setDryRun] = useState(true);
    const [upsert, setUpsert] = useState(true);
    const [flattenRelations, setFlattenRelations] = useState(true);
    const [validateFkLabels, setValidateFkLabels] = useState(true);
    const [validated, setValidated] = useState(false);
    const [previewRows, setPreviewRows] = useState([]);
    const [saving, setSaving] = useState(false);

    const existingByName = useCallback(() => {
        const map = {};
        (existingFields || []).forEach(f => { map[f.field_name] = f; });
        return map;
    }, [existingFields]);

    const runValidate = useCallback(() => {
        const { records, error } = parseInput(rawInput, fieldTypes);
        if (error) {
            setPreviewRows([{ _key: 0, _status: 'error', _message: error }]);
            setValidated(false);
            return;
        }
        const options = { validateFkLabels, flattenRelations, dataModels };
        const byName = existingByName();
        const rows = records.map((row, idx) => {
            const { normalized, errors, warnings } = normalizeRecord(row, fieldTypes, options);
            const status = errors.length ? 'error' : 'ok';
            const message = errors.length ? errors.join('; ') : (warnings.length ? warnings.join('; ') : 'OK');
            return {
                _key: idx,
                _index: idx + 1,
                _status: status,
                _message: message,
                _normalized: normalized,
                _existing: normalized ? byName[normalized.field_name] : null,
            };
        });
        setPreviewRows(rows);
        setValidated(rows.every(r => r._status === 'ok'));
    }, [rawInput, fieldTypes, validateFkLabels, flattenRelations, existingByName]);

    const handleSave = async () => {
        const rowsToSave = previewRows.filter(r => r._status === 'ok' && r._normalized);
        if (!rowsToSave.length) {
            message.warning('No valid records to save.');
            return;
        }
        setSaving(true);
        const byName = existingByName();
        let added = 0;
        let updated = 0;
        try {
            for (let i = 0; i < rowsToSave.length; i++) {
                const { _normalized, _existing } = rowsToSave[i];
                const payload = {
                    ..._normalized,
                    order_no: _normalized.order_no || (i + 1),
                };
                if (upsert && _existing) {
                    await api.updateDataModelField(modelId, _existing.field_id, payload);
                    updated++;
                } else {
                    await api.addDataModelField(modelId, payload);
                    added++;
                }
            }
            message.success(`Saved: ${added} added, ${updated} updated.`);
            onImportDone?.();
            onClose();
        } catch (err) {
            message.error('Import failed: ' + (err.message || 'Unknown error'));
        } finally {
            setSaving(false);
        }
    };

    const handleCancel = () => {
        setRawInput('');
        setPreviewRows([]);
        setValidated(false);
        onClose();
    };

    const uploadProps = {
        name: 'file',
        multiple: false,
        showUploadList: false,
        beforeUpload: (file) => {
            const reader = new FileReader();
            reader.onload = (e) => setRawInput(e.target?.result ?? '');
            reader.readAsText(file);
            return false; // prevent auto upload
        },
    };

    const previewColumns = [
        { title: '#', dataIndex: '_index', key: '_index', width: 48 },
        { title: 'Status', dataIndex: '_status', key: '_status', width: 80, render: (s) => s === 'ok' ? <CheckCircleOutlined style={{ color: 'green' }} /> : <CloseCircleOutlined style={{ color: 'red' }} /> },
        {
            title: 'Message',
            dataIndex: '_message',
            key: '_message',
            width: 220,
            ellipsis: { showTitle: false },
            render: (msg, record) => (
                <Tooltip title={record._message} placement="topLeft">
                    <span style={{ whiteSpace: 'normal', wordBreak: 'break-word', cursor: record._status === 'error' ? 'help' : 'default' }}>
                        {record._message}
                    </span>
                </Tooltip>
            ),
        },
        { title: 'field_name', dataIndex: ['_normalized', 'field_name'], key: 'fn', width: 120 },
        { title: 'type', dataIndex: ['_normalized', 'field_type_id'], key: 'ft', width: 100, render: (id) => fieldTypes.find(f => f.field_type_id === id)?.type_name || id },
    ];

    const canSave = validated && previewRows.some(r => r._status === 'ok' && r._normalized);

    return (
        <Modal
            title="Data Import"
            open={visible}
            onCancel={handleCancel}
            width={960}
            footer={null}
            destroyOnClose
        >
            <style>{`
                .fields-import-dragger-compact.ant-upload-drag,
                .fields-import-dragger-compact.ant-upload-drag .ant-upload-drag-container {
                    min-height: 0 !important;
                    height: 100% !important;
                }
            `}</style>
            <Row gutter={16}>
                <Col span={12}>
                    <div style={{ marginBottom: 8 }}>
                        <Text strong>Input source</Text>
                    </div>
                    <TextArea
                        placeholder="Paste CSV, JSON, or YAML here…"
                        value={rawInput}
                        onChange={(e) => setRawInput(e.target.value)}
                        rows={5}
                        style={{ fontFamily: 'monospace', fontSize: 12 }}
                    />
                    <div style={{ marginTop: 8, height: 52, overflow: 'hidden' }}>
                        <Dragger
                            {...uploadProps}
                            style={{ height: '100%', minHeight: 0, margin: 0, padding: '6px 12px' }}
                            className="fields-import-dragger-compact"
                        >
                            <div style={{ display: 'flex', alignItems: 'center', gap: 8, justifyContent: 'center', height: '100%', minHeight: 0 }}>
                                <InboxOutlined style={{ fontSize: 20 }} />
                                <span style={{ fontSize: 12 }}>Click or drag file to upload</span>
                            </div>
                        </Dragger>
                    </div>
                    <div style={{ marginTop: 12 }}>
                        <Space direction="vertical">
                            <Checkbox checked={dryRun} onChange={(e) => setDryRun(e.target.checked)}>Dry run (preview only, no save)</Checkbox>
                            <Checkbox checked={upsert} onChange={(e) => setUpsert(e.target.checked)}>Upsert (update existing by field_name)</Checkbox>
                            <Checkbox checked={flattenRelations} onChange={(e) => setFlattenRelations(e.target.checked)}>Flatten relations</Checkbox>
                            <Checkbox checked={validateFkLabels} onChange={(e) => setValidateFkLabels(e.target.checked)}>Validate foreign key label against ids</Checkbox>
                        </Space>
                    </div>
                    <Space style={{ marginTop: 12 }}>
                        <Button type="primary" onClick={runValidate}>Validate</Button>
                    </Space>
                </Col>
                <Col span={12}>
                    <div style={{ marginBottom: 8 }}>
                        <Text strong>Preview & validation</Text>
                    </div>
                    {previewRows.length > 0 && (
                        <>
                            <Alert
                                type={validated ? 'success' : 'warning'}
                                message={validated ? 'All records valid' : 'Fix errors before saving'}
                                style={{ marginBottom: 8 }}
                            />
                            <Table
                                size="small"
                                dataSource={previewRows}
                                rowKey="_key"
                                columns={previewColumns}
                                pagination={false}
                                scroll={{ y: 280 }}
                            />
                        </>
                    )}
                    {previewRows.length === 0 && (
                        <div style={{ color: '#999', padding: 24 }}>Run Validate to see parsed records and validation results.</div>
                    )}
                </Col>
            </Row>
            <div style={{ marginTop: 16, textAlign: 'right' }}>
                <Space>
                    <Button onClick={handleCancel}>Cancel</Button>
                    <Button type="primary" onClick={handleSave} disabled={!canSave} loading={saving}>
                        Save records
                    </Button>
                </Space>
            </div>
        </Modal>
    );
}

export default FieldsImportModal;
