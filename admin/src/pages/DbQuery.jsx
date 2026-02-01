import React, { useState, useEffect, useRef, useMemo } from 'react';
import {
    Card,
    Button,
    Space,
    message,
    Spin,
    Table as AntTable,
    Input,
    Select,
    Form,
    Collapse,
    Tag,
    Divider,
    Row,
    Col,
    Modal,
    Drawer,
    Switch,
    InputNumber,
    Typography,
    Tooltip
} from 'antd';
import {
    CodeOutlined,
    PlayCircleOutlined,
    ClearOutlined,
    SaveOutlined,
    DatabaseOutlined,
    SearchOutlined,
    PlusOutlined,
    DeleteOutlined,
    EditOutlined,
    UpOutlined,
    DownOutlined,
    MoreOutlined
} from '@ant-design/icons';
import { VCText } from '../components/ViewComponents/inputs/VCText';
import { VCTextArea } from '../components/ViewComponents/inputs/VCTextArea';
import { VCNumber } from '../components/ViewComponents/inputs/VCNumber';
import { VCDate } from '../components/ViewComponents/inputs/VCDate';
import { VCTimestampUTC } from '../components/ViewComponents/inputs/VCTimestampUTC';
import { VCSwitch } from '../components/ViewComponents/inputs/VCSwitch';
import { VCJsonEditor } from '../components/ViewComponents/inputs/VCJsonEditor';
import { VCJsonViewer } from '../components/ViewComponents/displays/VCJsonViewer';
import QueryBuilderModal from '../components/ViewComponents/inputs/QueryBuilderModal';
import { api } from '../utils/api';

const { TextArea } = Input;
const { Option } = Select;
const { Panel } = Collapse;
const { Text, Paragraph } = Typography;

const DbQuery = () => {
    const [query, setQuery] = useState('');
    const [results, setResults] = useState([]);
    const [columns, setColumns] = useState([]);
    const [loading, setLoading] = useState(false);
    const [suggestions, setSuggestions] = useState(null);
    const [showSuggestions, setShowSuggestions] = useState(false);
    const [suggestionPosition, setSuggestionPosition] = useState({ top: 0, left: 0 });
    const textAreaRef = useRef(null);
    const [cursorPosition, setCursorPosition] = useState(0);
    const [queryHistory, setQueryHistory] = useState([]);
    const [currentTableName, setCurrentTableName] = useState(null);
    const [tableStructure, setTableStructure] = useState(null);
    const [editModalVisible, setEditModalVisible] = useState(false);
    const [addModalVisible, setAddModalVisible] = useState(false);
    const [editingRecord, setEditingRecord] = useState(null);
    const [primaryKey, setPrimaryKey] = useState(null);
    const [editForm] = Form.useForm();
    const [addForm] = Form.useForm();
    const [expandedCells, setExpandedCells] = useState({}); // Track expanded cells: { "rowIndex_columnName": true }
    const [showQueryPanel, setShowQueryPanel] = useState(true); // Track query panel visibility
    const [fkSelectionModalVisible, setFkSelectionModalVisible] = useState(false);
    const [currentFkColumn, setCurrentFkColumn] = useState(null); // { columnName, foreignKey: { referenced_table, referenced_column } }
    const [fkTableRecords, setFkTableRecords] = useState([]);
    const [fkTableColumns, setFkTableColumns] = useState([]);
    const [fkTableColumnsFull, setFkTableColumnsFull] = useState([]); // Full column info with FK detection
    const [fkTableLoading, setFkTableLoading] = useState(false);
    const [fkFilters, setFkFilters] = useState([]); // Array of filter objects: [{ column, operator, value }]
    const [fkSelectedColumns, setFkSelectedColumns] = useState([]); // Columns to display
    const [fkPagination, setFkPagination] = useState({ current: 1, pageSize: 10, total: 0 });
    const [jsonViewerModalVisible, setJsonViewerModalVisible] = useState(false);
    const [jsonViewerData, setJsonViewerData] = useState(null);
    const [jsonViewerTitle, setJsonViewerTitle] = useState('');
    const [tablePagination, setTablePagination] = useState({ current: 1, pageSize: 50 });
    const [queryBuilderModalVisible, setQueryBuilderModalVisible] = useState(false);

    useEffect(() => {
        loadSuggestions();
    }, []);

    const loadSuggestions = async () => {
        try {
            const response = await api.getQuerySuggestions();
            setSuggestions(response);
        } catch (error) {
            console.error('Failed to load suggestions:', error);
        }
    };

    const handleExecuteQuery = async (customQuery = null) => {
        const queryToExecute = customQuery || query;
        if (!queryToExecute.trim()) {
            message.warning('Please enter a query');
            return;
        }

        try {
            setLoading(true);
            const response = await api.executeQuery(queryToExecute);

            setResults(response.rows || []);
            setColumns(response.columns || []);

            // Parse table name from query (simple extraction)
            const tableNameMatch = queryToExecute.match(/FROM\s+["]?(\w+)["]?/i) ||
                queryToExecute.match(/FROM\s+public\.["]?(\w+)["]?/i);
            const detectedTable = tableNameMatch ? tableNameMatch[1] : null;

            if (detectedTable && suggestions?.tables.includes(detectedTable)) {
                setCurrentTableName(detectedTable);
                // Fetch table structure for edit/add operations
                try {
                    const structureResponse = await api.getTableStructure(detectedTable);
                    setTableStructure(structureResponse);
                    setPrimaryKey(structureResponse.primary_keys?.[0] || null);
                } catch (err) {
                    console.error('Failed to fetch table structure:', err);
                }
            } else {
                setCurrentTableName(null);
                setTableStructure(null);
                setPrimaryKey(null);
            }

            // Add to history
            if (!queryHistory.includes(queryToExecute)) {
                setQueryHistory([queryToExecute, ...queryHistory].slice(0, 10)); // Keep last 10
            }

            // Update query state if custom query was used
            if (customQuery) {
                setQuery(queryToExecute);
            }

            // Hide query panel when results are shown
            if (response.rows && response.rows.length > 0) {
                setShowQueryPanel(false);
            }

            // Reset pagination to first page when new query is executed
            setTablePagination({ current: 1, pageSize: 50 });

            message.success(`Query executed successfully. ${response.row_count || 0} rows returned.`);
        } catch (error) {
            message.error(`Query failed: ${error.message}`);
            setResults([]);
            setColumns([]);
        } finally {
            setLoading(false);
        }
    };

    const handleClear = () => {
        setQuery('');
        setResults([]);
        setColumns([]);
    };

    const handleInsertSuggestion = (suggestion) => {
        const textarea = textAreaRef.current?.resizableTextArea?.textArea;
        if (!textarea) return;

        const start = textarea.selectionStart;
        const end = textarea.selectionEnd;
        const textBefore = query.substring(0, start);
        const textAfter = query.substring(end);

        // Find the word being typed
        const words = textBefore.split(/\s+/);
        const lastWord = words[words.length - 1] || '';

        // Replace last word with suggestion
        const newQuery = textBefore.substring(0, textBefore.length - lastWord.length) + suggestion + ' ' + textAfter;

        setQuery(newQuery);
        setShowSuggestions(false);

        // Set cursor position after inserted text
        setTimeout(() => {
            const newPosition = start - lastWord.length + suggestion.length + 1;
            textarea.setSelectionRange(newPosition, newPosition);
            textarea.focus();
        }, 0);
    };

    const handleTextChange = (e) => {
        const value = e.target.value;
        setQuery(value);

        const textarea = e.target;
        const cursorPos = textarea.selectionStart;
        setCursorPosition(cursorPos);

        // Get current word
        const textBefore = value.substring(0, cursorPos);
        const match = textBefore.match(/(\w+)$/);

        if (match && suggestions) {
            const word = match[1].toUpperCase();
            const filteredSuggestions = [
                ...suggestions.keywords.filter(k => k.startsWith(word)),
                ...suggestions.tables.filter(t => t.toUpperCase().startsWith(word.toUpperCase())),
            ];

            if (filteredSuggestions.length > 0) {
                // Calculate position for suggestions dropdown
                const rect = textarea.getBoundingClientRect();
                const lineHeight = 20;
                const lines = textBefore.split('\n');
                const currentLine = lines.length - 1;
                const column = lines[currentLine].length;

                setSuggestionPosition({
                    top: rect.top + (currentLine * lineHeight) + 30,
                    left: rect.left + (column * 8)
                });
                setShowSuggestions(true);
            } else {
                setShowSuggestions(false);
            }
        } else {
            setShowSuggestions(false);
        }
    };

    const handleEdit = (record) => {
        setEditingRecord(record);
        editForm.setFieldsValue(record);
        setEditModalVisible(true);
    };

    const handleOpenFkSelection = async (column, currentValue) => {
        if (!column.foreign_key) return;

        const foreignTable = column.foreign_key.referenced_table;
        const foreignColumn = column.foreign_key.referenced_column;

        setCurrentFkColumn({
            columnName: column.column_name,
            foreignKey: { referenced_table: foreignTable, referenced_column: foreignColumn },
            currentValue
        });
        setFkSelectionModalVisible(true);
        setFkFilters([]);
        setFkPagination({ current: 1, pageSize: 10, total: 0 });

        // Fetch foreign table structure first
        try {
            const structureResponse = await api.getTableStructure(foreignTable);
            const allColumns = structureResponse.columns.map(c => ({
                name: c.column_name,
                isForeignKey: c.foreign_key ? true : false
            }));

            // Filter out foreign key columns (except the first column which is required)
            const nonFkColumns = allColumns.filter((c, idx) => idx === 0 || !c.isForeignKey);

            // Select first column (required) + next 3 non-FK columns (default to 4 total)
            const selectedCols = nonFkColumns.slice(0, 4).map(c => c.name);

            setFkTableColumnsFull(allColumns);
            setFkSelectedColumns(selectedCols);
            setFkTableColumns(selectedCols);

            // Load data with initial filters
            await loadFkTableData(foreignTable, 1, 10, [], selectedCols);
        } catch (error) {
            message.error(`Failed to load table structure: ${error.message}`);
        }
    };

    const loadFkTableData = async (tableName, page, pageSize, filters, selectedColumns = null) => {
        try {
            setFkTableLoading(true);
            const offset = (page - 1) * pageSize;

            // Build WHERE clause from filters (escape single quotes for SQL)
            const escapeSql = (str) => str.replace(/'/g, "''");
            let whereClauses = [];

            filters.forEach(filter => {
                if (filter.column && filter.value && filter.value.trim()) {
                    const escapedVal = escapeSql(filter.value.trim());
                    const col = `"${filter.column}"`;

                    switch (filter.operator) {
                        case '=':
                            whereClauses.push(`${col} = '${escapedVal}'`);
                            break;
                        case '!=':
                            whereClauses.push(`${col} != '${escapedVal}'`);
                            break;
                        case '>':
                            whereClauses.push(`${col} > '${escapedVal}'`);
                            break;
                        case '>=':
                            whereClauses.push(`${col} >= '${escapedVal}'`);
                            break;
                        case '<':
                            whereClauses.push(`${col} < '${escapedVal}'`);
                            break;
                        case '<=':
                            whereClauses.push(`${col} <= '${escapedVal}'`);
                            break;
                        case 'LIKE':
                            whereClauses.push(`${col} LIKE '%${escapedVal}%'`);
                            break;
                        case 'ILIKE':
                            whereClauses.push(`${col} ILIKE '%${escapedVal}%'`);
                            break;
                        default:
                            whereClauses.push(`${col} ILIKE '%${escapedVal}%'`);
                    }
                }
            });

            const whereClause = whereClauses.length > 0
                ? `WHERE ${whereClauses.join(' AND ')}`
                : '';

            // Use selected columns or all columns
            const columnsToSelect = selectedColumns || fkSelectedColumns || fkTableColumns;
            const selectColumns = columnsToSelect.length > 0
                ? columnsToSelect.map(c => `"${c}"`).join(', ')
                : '*';

            // Get total count
            const countQuery = `SELECT COUNT(*) as total FROM public."${tableName}" ${whereClause}`;
            const countResponse = await api.executeQuery(countQuery);
            const total = countResponse.rows?.[0]?.total || 0;

            // Get records with pagination
            const query = `SELECT ${selectColumns} FROM public."${tableName}" ${whereClause} LIMIT ${pageSize} OFFSET ${offset}`;
            const response = await api.executeQuery(query);

            setFkTableRecords(response.rows || []);
            setFkPagination({ current: page, pageSize, total });
        } catch (error) {
            message.error(`Failed to load foreign table data: ${error.message}`);
        } finally {
            setFkTableLoading(false);
        }
    };

    const handleFkFilterChange = (index, field, value) => {
        const newFilters = [...fkFilters];
        if (!newFilters[index]) {
            newFilters[index] = { column: '', operator: 'ILIKE', value: '' };
        }
        newFilters[index][field] = value;
        setFkFilters(newFilters);
        setFkPagination(prev => ({ ...prev, current: 1 })); // Reset to first page
        loadFkTableData(currentFkColumn.foreignKey.referenced_table, 1, fkPagination.pageSize, newFilters, fkSelectedColumns);
    };

    const handleAddFkFilter = () => {
        setFkFilters([...fkFilters, { column: '', operator: 'ILIKE', value: '' }]);
    };

    const handleRemoveFkFilter = (index) => {
        const newFilters = fkFilters.filter((_, i) => i !== index);
        setFkFilters(newFilters);
        setFkPagination(prev => ({ ...prev, current: 1 }));
        loadFkTableData(currentFkColumn.foreignKey.referenced_table, 1, fkPagination.pageSize, newFilters, fkSelectedColumns);
    };

    const handleFkColumnSelectionChange = (selectedCols) => {
        // Ensure first column is always included
        const firstCol = fkTableColumnsFull.length > 0 ? fkTableColumnsFull[0].name : null;
        if (firstCol && !selectedCols.includes(firstCol)) {
            selectedCols = [firstCol, ...selectedCols];
        }
        setFkSelectedColumns(selectedCols);
        setFkTableColumns(selectedCols);
        setFkPagination(prev => ({ ...prev, current: 1 }));
        loadFkTableData(currentFkColumn.foreignKey.referenced_table, 1, fkPagination.pageSize, fkFilters, selectedCols);
    };

    const handleFkPaginationChange = (page, pageSize) => {
        setFkPagination(prev => ({ ...prev, current: page, pageSize }));
        loadFkTableData(currentFkColumn.foreignKey.referenced_table, page, pageSize, fkFilters, fkSelectedColumns);
    };

    const handleSelectFkRecord = (record) => {
        const fkColumnName = currentFkColumn.columnName;
        const fkValue = record[currentFkColumn.foreignKey.referenced_column];

        // Update form value
        if (editModalVisible) {
            editForm.setFieldsValue({ [fkColumnName]: fkValue });
        } else if (addModalVisible) {
            addForm.setFieldsValue({ [fkColumnName]: fkValue });
        }

        setFkSelectionModalVisible(false);
        message.success('Foreign key value selected');
    };

    const handleDelete = (record) => {
        if (!currentTableName || !primaryKey) {
            message.warning('Cannot delete: Table or primary key not detected');
            return;
        }

        const recordId = record[primaryKey];
        if (!recordId) {
            message.warning('Cannot delete: Primary key value not found');
            return;
        }

        Modal.confirm({
            title: 'Delete Record',
            content: `Are you sure you want to delete this record? (${primaryKey}: ${recordId})`,
            okText: 'Delete',
            okType: 'danger',
            cancelText: 'Cancel',
            onOk: async () => {
                try {
                    await api.deleteRecord(currentTableName, recordId);
                    message.success('Record deleted successfully');
                    // Refresh query
                    handleExecuteQuery(query);
                } catch (error) {
                    message.error(`Failed to delete record: ${error.message}`);
                }
            }
        });
    };

    const handleAddRow = () => {
        if (!currentTableName || !tableStructure) {
            message.warning('Please execute a query first to detect the table');
            return;
        }
        addForm.resetFields();
        setAddModalVisible(true);
    };

    // Map PostgreSQL data types to VC component types (same logic as Database.jsx)
    const getComponentTypeFromDataType = (dataType, column, value) => {
        const normalizedType = dataType?.toLowerCase()?.trim() || '';
        const columnName = column.column_name?.toLowerCase() || '';

        // Timestamp types - CHECK FIRST
        if (columnName === 'idate' || columnName === 'last_updated' ||
            normalizedType === 'timestamp' ||
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
            normalizedType === 'float') {
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

        // Date types
        if (normalizedType === 'date') {
            return {
                type: 'date',
                inputValues: {
                    format: 'YYYY-MM-DD',
                    default_value: value ? (value instanceof Date ? value : new Date(value)) : null
                }
            };
        }

        // JSONB types
        if (normalizedType === 'jsonb' || normalizedType === 'json') {
            return {
                type: 'jsoneditor',
                inputValues: {
                    default_value: value
                }
            };
        }

        // Text types
        if (normalizedType === 'text' ||
            (normalizedType.includes('varchar') && column.max_length && column.max_length > 100) ||
            (normalizedType === 'character varying' && column.max_length && column.max_length > 100)) {
            return { type: 'textarea', inputValues: {} };
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
            case 'date':
                return <VCDate key={inputValues.name} component={component} />;
            case 'number':
                return <VCNumber key={inputValues.name} component={component} />;
            case 'switch':
                return <VCSwitch key={inputValues.name} component={component} />;
            case 'textarea':
                return <VCTextArea key={inputValues.name} component={component} />;
            case 'jsoneditor':
            case 'json_editor':
                return <VCJsonEditor key={inputValues.name} component={component} />;
            case 'text':
            default:
                return <VCText key={inputValues.name} component={component} />;
        }
    };

    const handleSaveEdit = async () => {
        try {
            const values = await editForm.validateFields();

            if (!currentTableName || !primaryKey || !editingRecord) {
                message.error('Cannot update: Missing table or primary key information');
                return;
            }

            const recordId = editingRecord[primaryKey];

            // Compare with original to find only modified fields
            const updates = {};
            for (const key in values) {
                if (key === primaryKey) continue; // Skip primary key
                
                // Get the actual value from the form field (more reliable for complex types like JSON)
                let newValue = editForm.getFieldValue(key);
                // Fallback to values if getFieldValue returns undefined
                if (newValue === undefined) {
                    newValue = values[key];
                }
                
                const oldValue = editingRecord[key];

                // Handle null/undefined comparison
                if (newValue == null && oldValue == null) {
                    continue;
                }

                // Get column info to check if it's a datetime or jsonb field
                const column = tableStructure?.columns?.find(c => c.column_name === key);
                const dataType = column?.data_type?.toLowerCase() || '';
                const isDateTime = dataType.includes('timestamp') || dataType.includes('time') || dataType.includes('date');
                const isJsonb = dataType === 'jsonb' || dataType === 'json';

                // Normalize values for comparison
                let normalizedNew = newValue;
                let normalizedOld = oldValue;

                // For JSONB fields, normalize both to JSON strings for comparison
                if (isJsonb) {
                    try {
                        // Normalize new value to JSON string (VCJsonEditor now returns string)
                        if (typeof newValue === 'string' && newValue.trim()) {
                            // Parse and re-stringify to normalize format (removes whitespace differences)
                            normalizedNew = JSON.stringify(JSON.parse(newValue));
                        } else if (typeof newValue === 'object' && newValue !== null) {
                            // Fallback: if we somehow get an object
                            normalizedNew = JSON.stringify(newValue);
                        } else {
                            normalizedNew = newValue === null || newValue === '' ? null : String(newValue);
                        }
                        
                        // Normalize old value to JSON string (from database, might be object or string)
                        if (typeof oldValue === 'object' && oldValue !== null) {
                            normalizedOld = JSON.stringify(oldValue);
                        } else if (typeof oldValue === 'string' && oldValue.trim()) {
                            // Parse and re-stringify to normalize format
                            normalizedOld = JSON.stringify(JSON.parse(oldValue));
                        } else {
                            normalizedOld = oldValue === null || oldValue === '' ? null : String(oldValue);
                        }
                    } catch (e) {
                        // If normalization fails, use original values
                        normalizedNew = newValue;
                        normalizedOld = oldValue;
                    }
                }

                // For datetime fields, normalize format
                if (isDateTime && typeof newValue === 'string' && newValue.endsWith('Z')) {
                    normalizedNew = newValue;
                }
                if (isDateTime && typeof oldValue === 'string') {
                    normalizedOld = oldValue.endsWith('Z') ? oldValue : oldValue + 'Z';
                }

                if (normalizedNew !== normalizedOld) {
                    // For datetime fields, VCTimestampUTC already returns UTC ISO string
                    if (isDateTime && typeof newValue === 'string' && newValue.endsWith('Z')) {
                        updates[key] = newValue; // Already in UTC format
                    } else if (newValue instanceof Date) {
                        updates[key] = newValue.toISOString();
                    } else if (isJsonb) {
                        // For JSONB fields, VCJsonEditor now stores the raw JSON string
                        try {
                            let jsonString;
                            
                            if (typeof newValue === 'string') {
                                // VCJsonEditor now returns the raw JSON string
                                if (newValue.trim()) {
                                    // Validate by parsing to ensure it's valid JSON
                                    const parsed = JSON.parse(newValue);
                                    // Re-stringify to ensure consistent formatting (removes extra whitespace)
                                    jsonString = JSON.stringify(parsed);
                                    updates[key] = jsonString;
                                } else {
                                    // Empty string means null for JSONB
                                    updates[key] = null;
                                }
                            } else if (typeof newValue === 'object' && newValue !== null) {
                                // Fallback: if we somehow get an object (backwards compatibility)
                                jsonString = JSON.stringify(newValue);
                                JSON.parse(jsonString); // Validate
                                updates[key] = jsonString;
                            } else if (newValue === null || newValue === undefined) {
                                updates[key] = null;
                            } else {
                                // For other types, stringify directly
                                jsonString = JSON.stringify(newValue);
                                JSON.parse(jsonString); // Validate
                                updates[key] = jsonString;
                            }
                        } catch (e) {
                            // Invalid JSON - show error and prevent save
                            const errorMsg = e.message || 'Invalid JSON format';
                            message.error(`Invalid JSON in field "${key}": ${errorMsg}. Please fix the JSON syntax before saving.`);
                            console.error('JSON validation error:', { 
                                key, 
                                newValue, 
                                newValueType: typeof newValue,
                                error: e 
                            });
                            throw new Error(`Invalid JSON in field "${key}": ${errorMsg}`);
                        }
                    } else {
                        updates[key] = newValue;
                    }
                }
            }

            if (Object.keys(updates).length === 0) {
                message.info('No changes to save');
                return;
            }

            await api.updateRecord(currentTableName, recordId, updates);
            message.success('Record updated successfully');
            setEditModalVisible(false);
            // Refresh query
            handleExecuteQuery(query);
        } catch (error) {
            if (error.errorFields) {
                return; // Form validation errors
            }
            message.error(`Failed to update record: ${error.message}`);
        }
    };

    const handleSaveAdd = async () => {
        try {
            const values = await addForm.validateFields();

            if (!currentTableName) {
                message.error('Cannot insert: Table not detected');
                return;
            }

            // Validate and normalize JSONB fields before sending
            const validatedValues = { ...values };
            for (const key in validatedValues) {
                const column = tableStructure?.columns?.find(c => c.column_name === key);
                const dataType = column?.data_type?.toLowerCase() || '';
                const isJsonb = dataType === 'jsonb' || dataType === 'json';
                
                if (isJsonb) {
                    const value = validatedValues[key];
                    // VCJsonEditor now returns JSON string
                    if (typeof value === 'string' && value.trim()) {
                        // Validate JSON string and normalize format
                        try {
                            const parsed = JSON.parse(value);
                            validatedValues[key] = JSON.stringify(parsed); // Normalize format
                        } catch (e) {
                            message.error(`Invalid JSON in field "${key}": ${e.message}. Please fix the JSON syntax before saving.`);
                            return; // Prevent save
                        }
                    } else if (typeof value === 'object' && value !== null) {
                        // Fallback: if we somehow get an object
                        try {
                            validatedValues[key] = JSON.stringify(value);
                            JSON.parse(validatedValues[key]); // Validate
                        } catch (e) {
                            message.error(`Invalid JSON object in field "${key}": ${e.message}. Please fix the JSON syntax before saving.`);
                            return; // Prevent save
                        }
                    } else if (value === null || value === undefined || value === '') {
                        validatedValues[key] = null;
                    }
                }
            }

            await api.insertRecord(currentTableName, validatedValues);
            message.success('Record added successfully');
            setAddModalVisible(false);
            // Refresh query
            handleExecuteQuery(query);
        } catch (error) {
            if (error.errorFields) {
                return; // Form validation errors
            }
            message.error(`Failed to add record: ${error.message}`);
        }
    };

    // Get column data type from table structure for proper rendering
    const getColumnDataType = (columnName) => {
        if (!tableStructure) return null;
        const column = tableStructure.columns.find(c => c.column_name === columnName);
        return column?.data_type || null;
    };

    // Toggle cell expansion
    const toggleCellExpansion = (rowIndex, columnName) => {
        const key = `${rowIndex}_${columnName}`;
        setExpandedCells(prev => ({
            ...prev,
            [key]: !prev[key]
        }));
    };

    // Prepare table columns with actions
    const tableColumns = [
        ...columns.map((col, colIndex) => {
            const dataType = getColumnDataType(col);
            const normalizedType = dataType?.toLowerCase() || '';
            const isDateTime = normalizedType.includes('timestamp') || normalizedType.includes('time') || normalizedType === 'date';
            const isJsonb = normalizedType === 'jsonb' || normalizedType === 'json';

            return {
                title: col,
                dataIndex: col,
                key: col,
                ellipsis: {
                    showTitle: false,
                },
                width: 150, // Set a reasonable default width
                render: (text, record, rowIndex) => {
                    // Use record key for unique identification (works with pagination)
                    const recordKey = record.key !== undefined ? record.key : rowIndex;
                    const cellKey = `${recordKey}_${col}`;
                    const isExpanded = expandedCells[cellKey];

                    // Handle JSONB columns - show JSON button
                    if (isJsonb) {
                        const isEmpty = text === null || text === undefined || text === '';
                        let jsonValue = null;
                        let hasContent = false;

                        if (!isEmpty) {
                            try {
                                jsonValue = typeof text === 'object' ? text : JSON.parse(text);
                                // Check if it's actually empty (empty object or empty array)
                                if (Array.isArray(jsonValue)) {
                                    hasContent = jsonValue.length > 0;
                                } else if (typeof jsonValue === 'object' && jsonValue !== null) {
                                    hasContent = Object.keys(jsonValue).length > 0;
                                } else {
                                    hasContent = true; // primitive value
                                }
                            } catch (e) {
                                jsonValue = { error: 'Invalid JSON', raw: text };
                                hasContent = true; // Show invalid JSON in viewer
                            }
                        }

                        const isReallyEmpty = isEmpty || !hasContent;

                        return (
                            <Space>
                                <Button
                                    size="small"
                                    style={{
                                        backgroundColor: isReallyEmpty ? '#ffccc7' : '#52c41a',
                                        borderColor: isReallyEmpty ? '#ffccc7' : '#52c41a',
                                        color: isReallyEmpty ? '#666' : '#fff',
                                        fontSize: '11px',
                                        height: '24px',
                                        padding: '0 8px'
                                    }}
                                    onClick={() => {
                                        setJsonViewerData(isReallyEmpty ? null : jsonValue);
                                        setJsonViewerTitle(`${col} - JSON`);
                                        setJsonViewerModalVisible(true);
                                    }}
                                >
                                    JSON
                                </Button>
                            </Space>
                        );
                    }

                    if (text === null || text === undefined) {
                        return <span style={{ color: '#999', fontStyle: 'italic' }}>NULL</span>;
                    }

                    // Handle objects (JSON) - collapsed by default
                    if (typeof text === 'object') {
                        const jsonString = JSON.stringify(text, null, 2);
                        const isLongJson = jsonString.length > 150;
                        const displayJson = isLongJson && !isExpanded
                            ? jsonString.substring(0, 150) + '...'
                            : jsonString;

                        return (
                            <div style={{ fontSize: '11px', lineHeight: '1.4' }}>
                                <pre style={{
                                    margin: 0,
                                    padding: '4px 8px',
                                    background: '#f5f5f5',
                                    borderRadius: '4px',
                                    maxHeight: isExpanded ? 'none' : '100px',
                                    overflow: isExpanded ? 'visible' : 'hidden',
                                    whiteSpace: 'pre-wrap',
                                    wordBreak: 'break-word'
                                }}>
                                    {displayJson}
                                </pre>
                                {isLongJson && (
                                    <Button
                                        type="link"
                                        size="small"
                                        style={{ padding: '4px 0', fontSize: '11px', height: 'auto' }}
                                        onClick={() => toggleCellExpansion(recordKey, col)}
                                    >
                                        {isExpanded ? '▼ Collapse' : '▶ Expand'}
                                    </Button>
                                )}
                            </div>
                        );
                    }

                    // Handle boolean
                    if (typeof text === 'boolean') {
                        return <Tag color={text ? 'green' : 'red'} style={{ margin: 0 }}>{String(text)}</Tag>;
                    }

                    const textString = String(text);
                    const MAX_LENGTH = 80; // Max characters before truncation
                    const isLongText = textString.length > MAX_LENGTH;

                    // Handle date/timestamp fields - display UTC directly (no timezone conversion)
                    if (isDateTime) {
                        try {
                            // Parse as UTC and display UTC (no conversion)
                            const dateStr = typeof text === 'string'
                                ? (text.endsWith('Z') ? text : text + 'Z')
                                : text instanceof Date ? text.toISOString() : text;
                            const utcDate = new Date(dateStr);
                            // Format as UTC string (YYYY-MM-DD HH:mm:ss)
                            const formattedDate = utcDate.toISOString().replace('T', ' ').replace(/\.\d{3}Z$/, '').replace('Z', '');
                            return (
                                <Tooltip title={formattedDate}>
                                    <Text
                                        ellipsis={{ tooltip: formattedDate }}
                                        style={{ fontSize: '12px' }}
                                    >
                                        {formattedDate}
                                    </Text>
                                </Tooltip>
                            );
                        } catch (e) {
                            return textString;
                        }
                    }

                    // Handle long text strings with expand/collapse
                    if (isLongText) {
                        const displayText = isExpanded ? textString : textString.substring(0, MAX_LENGTH) + '...';
                        return (
                            <div>
                                <Text
                                    ellipsis={{ tooltip: textString }}
                                    style={{ fontSize: '12px', display: 'block', marginBottom: '4px' }}
                                >
                                    {displayText}
                                </Text>
                                <Button
                                    type="link"
                                    size="small"
                                    style={{ padding: '2px 0', fontSize: '11px', height: 'auto' }}
                                    onClick={() => toggleCellExpansion(recordKey, col)}
                                >
                                    {isExpanded ? '▼ Show Less' : '▶ Show More'}
                                </Button>
                            </div>
                        );
                    }

                    // Short text - just display with tooltip if needed
                    return (
                        <Tooltip title={textString.length > 50 ? textString : null}>
                            <Text
                                ellipsis={textString.length > 50 ? { tooltip: textString } : false}
                                style={{ fontSize: '12px' }}
                            >
                                {textString}
                            </Text>
                        </Tooltip>
                    );
                }
            };
        }),
        ...(currentTableName && primaryKey ? [{
            title: 'Actions',
            key: 'actions',
            width: 120,
            fixed: 'right',
            render: (_, record) => (
                <Space>
                    <Button
                        type="link"
                        size="small"
                        icon={<EditOutlined />}
                        onClick={() => handleEdit(record)}
                    >
                        Edit
                    </Button>
                    <Button
                        type="link"
                        danger
                        size="small"
                        icon={<DeleteOutlined />}
                        onClick={() => handleDelete(record)}
                    >
                        Delete
                    </Button>
                </Space>
            )
        }] : [])
    ];

    return (
        <div style={{ padding: '20px' }}>
            <Card>
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '20px' }}>
                    <h2 style={{ margin: 0 }}>
                        <CodeOutlined /> Database Query
                    </h2>
                    <Space>
                        <Button
                            icon={<DatabaseOutlined />}
                            onClick={() => setQueryBuilderModalVisible(true)}
                        >
                            Query Builder
                        </Button>
                        {results.length > 0 && (
                            <Button
                                type="text"
                                icon={showQueryPanel ? <DownOutlined /> : <UpOutlined />}
                                onClick={() => setShowQueryPanel(!showQueryPanel)}
                            >
                                {showQueryPanel ? 'Hide Query Panel' : 'Show Query Panel'}
                            </Button>
                        )}
                    </Space>
                </div>

                {showQueryPanel && (
                    <div>
                        <Space style={{ marginBottom: 12 }}>
                            <Button
                                type="primary"
                                icon={<PlayCircleOutlined />}
                                onClick={handleExecuteQuery}
                                loading={loading}
                            >
                                Execute Query
                            </Button>
                            <Button icon={<ClearOutlined />} onClick={handleClear}>
                                Clear
                            </Button>
                            {queryHistory.length > 0 && (
                                <Select
                                    placeholder="Load from history"
                                    style={{ width: 200 }}
                                    onChange={(value) => setQuery(value)}
                                >
                                    {queryHistory.map((q, idx) => (
                                        <Option key={idx} value={q}>
                                            {q.substring(0, 50)}{q.length > 50 ? '...' : ''}
                                        </Option>
                                    ))}
                                </Select>
                            )}
                        </Space>

                        <div style={{ position: 'relative' }}>
                            <TextArea
                                ref={textAreaRef}
                                value={query}
                                onChange={handleTextChange}
                                placeholder="Enter your SQL query here... (Only SELECT queries allowed)"
                                rows={10}
                                style={{
                                    fontFamily: 'monospace',
                                    fontSize: '14px'
                                }}
                                onKeyDown={(e) => {
                                    if (e.key === 'Tab' && showSuggestions) {
                                        e.preventDefault();
                                        const textBefore = query.substring(0, cursorPosition);
                                        const match = textBefore.match(/(\w+)$/);
                                        if (match && suggestions) {
                                            const word = match[1].toUpperCase();
                                            const filtered = suggestions.keywords
                                                .filter(k => k.startsWith(word))[0] ||
                                                suggestions.tables
                                                    .filter(t => t.toUpperCase().startsWith(word.toUpperCase()))[0];
                                            if (filtered) {
                                                handleInsertSuggestion(filtered);
                                            }
                                        }
                                    }
                                }}
                            />

                            {showSuggestions && suggestions && (
                                <div
                                    style={{
                                        position: 'absolute',
                                        top: suggestionPosition.top,
                                        left: suggestionPosition.left,
                                        background: 'white',
                                        border: '1px solid #d9d9d9',
                                        borderRadius: '4px',
                                        boxShadow: '0 2px 8px rgba(0,0,0,0.15)',
                                        maxHeight: '200px',
                                        overflowY: 'auto',
                                        zIndex: 1000,
                                        minWidth: '200px'
                                    }}
                                >
                                    {(() => {
                                        const textBefore = query.substring(0, cursorPosition);
                                        const match = textBefore.match(/(\w+)$/);
                                        const word = match ? match[1].toUpperCase() : '';
                                        const filteredKeywords = suggestions.keywords.filter(k => k.startsWith(word));
                                        const filteredTables = suggestions.tables.filter(t =>
                                            t.toUpperCase().startsWith(word.toUpperCase())
                                        );
                                        return (
                                            <>
                                                {filteredKeywords.map((kw, idx) => (
                                                    <div
                                                        key={`kw-${idx}`}
                                                        onClick={() => handleInsertSuggestion(kw)}
                                                        style={{
                                                            padding: '8px 12px',
                                                            cursor: 'pointer',
                                                            borderBottom: '1px solid #f0f0f0'
                                                        }}
                                                        onMouseEnter={(e) => e.target.style.background = '#f5f5f5'}
                                                        onMouseLeave={(e) => e.target.style.background = 'white'}
                                                    >
                                                        <Tag color="blue">{kw}</Tag>
                                                    </div>
                                                ))}
                                                {filteredTables.map((table, idx) => (
                                                    <div
                                                        key={`table-${idx}`}
                                                        onClick={() => handleInsertSuggestion(table)}
                                                        style={{
                                                            padding: '8px 12px',
                                                            cursor: 'pointer',
                                                            borderBottom: '1px solid #f0f0f0'
                                                        }}
                                                        onMouseEnter={(e) => e.target.style.background = '#f5f5f5'}
                                                        onMouseLeave={(e) => e.target.style.background = 'white'}
                                                    >
                                                        <DatabaseOutlined /> {table}
                                                    </div>
                                                ))}
                                            </>
                                        );
                                    })()}
                                </div>
                            )}
                        </div>

                        <div style={{ fontSize: '12px', color: '#999', marginTop: '8px' }}>
                            Tip: Type SQL keywords or table names and press Tab for auto-complete. Use Query Builder for visual query building.
                        </div>
                    </div>
                )}

                <QueryBuilderModal
                    visible={queryBuilderModalVisible}
                    onClose={() => setQueryBuilderModalVisible(false)}
                    onUseQuery={(sql) => {
                        setQuery(sql);
                        handleExecuteQuery(sql);
                    }}
                    dataSource="database"
                    showPreviewResults={true}
                    initialValue={query}
                />

                {/* Results Section - Always visible when results exist */}
                {(results.length > 0 || loading) && (
                    <div style={{ marginTop: showQueryPanel ? '20px' : 0 }}>
                        {loading && (
                            <div style={{ textAlign: 'center', padding: '40px' }}>
                                <Spin size="large" />
                            </div>
                        )}

                        {!loading && results.length > 0 && (
                            <Card
                                title={<span style={{ fontSize: '14px' }}>Results ({results.length} rows)</span>}
                                extra={
                                    currentTableName && primaryKey && (
                                        <Button
                                            type="primary"
                                            size="small"
                                            icon={<PlusOutlined />}
                                            onClick={handleAddRow}
                                        >
                                            Add Row
                                        </Button>
                                    )
                                }
                                styles={{ body: { padding: '12px' } }}
                            >
                                <AntTable
                                    columns={tableColumns}
                                    dataSource={results.map((row, idx) => ({
                                        key: primaryKey ? row[primaryKey] : idx,
                                        ...row
                                    }))}
                                    bordered
                                    size="small"
                                    scroll={{ x: 'max-content', y: 'calc(100vh - 350px)' }}
                                    pagination={{
                                        current: tablePagination.current,
                                        pageSize: tablePagination.pageSize,
                                        showSizeChanger: true,
                                        showTotal: (total) => `Total ${total} rows`,
                                        pageSizeOptions: ['25', '50', '100', '200'],
                                        size: 'small',
                                        showQuickJumper: true,
                                        onChange: (page, pageSize) => {
                                            setTablePagination({ current: page, pageSize });
                                        },
                                        onShowSizeChange: (current, size) => {
                                            setTablePagination({ current: 1, pageSize: size });
                                        }
                                    }}
                                    style={{ fontSize: '12px' }}
                                />
                            </Card>
                        )}
                    </div>
                )}

                {/* Edit Record Drawer */}
                <Drawer
                    title={`Edit Record - ${currentTableName}`}
                    open={editModalVisible}
                    onClose={() => setEditModalVisible(false)}
                    width={800}
                    extra={
                        <Space>
                            <Button onClick={() => setEditModalVisible(false)}>Cancel</Button>
                            <Button type="primary" onClick={handleSaveEdit}>Save</Button>
                        </Space>
                    }
                >
                    {tableStructure && editingRecord && (
                        <Form
                            form={editForm}
                            layout="vertical"
                            initialValues={editingRecord || {}}
                        >
                            {tableStructure.columns.map(col => {
                                const fieldName = col.column_name;
                                const isPrimaryKey = col.is_primary_key;
                                const value = editingRecord[fieldName];

                                if (isPrimaryKey) {
                                    return (
                                        <Form.Item
                                            key={fieldName}
                                            label={fieldName}
                                            name={fieldName}
                                        >
                                            <Input disabled />
                                        </Form.Item>
                                    );
                                }

                                // Check if this is a foreign key
                                const isForeignKey = col.foreign_key && col.foreign_key.referenced_table;

                                // If foreign key, render with ellipsis button
                                if (isForeignKey) {
                                    return (
                                        <Form.Item
                                            key={fieldName}
                                            label={fieldName}
                                            name={fieldName}
                                        >
                                            <Form.Item noStyle shouldUpdate={(prev, curr) => prev[fieldName] !== curr[fieldName]}>
                                                {({ getFieldValue }) => {
                                                    const fkValue = getFieldValue(fieldName) || value || '';
                                                    return (
                                                        <Input.Group compact style={{ display: 'flex' }}>
                                                            <Input
                                                                readOnly
                                                                value={String(fkValue)}
                                                                style={{ flex: 1 }}
                                                                placeholder="Select from referenced table"
                                                            />
                                                            <Button
                                                                icon={<MoreOutlined />}
                                                                onClick={() => handleOpenFkSelection(col, fkValue)}
                                                            >
                                                                Select
                                                            </Button>
                                                        </Input.Group>
                                                    );
                                                }}
                                            </Form.Item>
                                        </Form.Item>
                                    );
                                }

                                // Get component type based on schema data type
                                const { type: componentType, inputValues: typeInputValues } = getComponentTypeFromDataType(col.data_type, col, value);

                                let inputValues = {
                                    name: fieldName,
                                    label: fieldName,
                                    default_value: value,
                                    ...typeInputValues
                                };

                                // Render VC component directly
                                return renderVCComponent(componentType, inputValues);
                            })}
                        </Form>
                    )}
                </Drawer>

                {/* Add Record Modal */}
                <Modal
                    title={`Add New Record - ${currentTableName}`}
                    open={addModalVisible}
                    onOk={handleSaveAdd}
                    onCancel={() => setAddModalVisible(false)}
                    width={800}
                    okText="Add"
                >
                    {tableStructure && (
                        <Form
                            form={addForm}
                            layout="vertical"
                        >
                            {tableStructure.columns.map(col => {
                                const fieldName = col.column_name;
                                const isPrimaryKey = col.is_primary_key;

                                // Skip auto-generated primary keys
                                if (isPrimaryKey && col.data_type?.includes('serial')) {
                                    return null;
                                }

                                if (isPrimaryKey) {
                                    return (
                                        <Form.Item
                                            key={fieldName}
                                            label={fieldName}
                                            name={fieldName}
                                            rules={[
                                                { required: true, message: `${fieldName} is required` }
                                            ]}
                                        >
                                            <Input placeholder={`Enter ${fieldName}`} />
                                        </Form.Item>
                                    );
                                }

                                // Check if this is a foreign key
                                const isForeignKey = col.foreign_key && col.foreign_key.referenced_table;

                                // If foreign key, render with ellipsis button
                                if (isForeignKey) {
                                    return (
                                        <Form.Item
                                            key={fieldName}
                                            label={fieldName}
                                            name={fieldName}
                                        >
                                            <Form.Item noStyle shouldUpdate={(prev, curr) => prev[fieldName] !== curr[fieldName]}>
                                                {({ getFieldValue }) => {
                                                    const fkValue = getFieldValue(fieldName) || '';
                                                    return (
                                                        <Input.Group compact style={{ display: 'flex' }}>
                                                            <Input
                                                                readOnly
                                                                value={String(fkValue)}
                                                                style={{ flex: 1 }}
                                                                placeholder="Select from referenced table"
                                                            />
                                                            <Button
                                                                icon={<MoreOutlined />}
                                                                onClick={() => handleOpenFkSelection(col, fkValue)}
                                                            >
                                                                Select
                                                            </Button>
                                                        </Input.Group>
                                                    );
                                                }}
                                            </Form.Item>
                                        </Form.Item>
                                    );
                                }

                                // Get component type based on schema data type
                                const { type: componentType, inputValues: typeInputValues } = getComponentTypeFromDataType(col.data_type, col, null);

                                let inputValues = {
                                    name: fieldName,
                                    label: fieldName,
                                    default_value: null,
                                    ...typeInputValues
                                };

                                // Render VC component directly
                                return renderVCComponent(componentType, inputValues);
                            })}
                        </Form>
                    )}
                </Modal>

                {/* Foreign Key Selection Modal */}
                <Modal
                    title={`Select from ${currentFkColumn?.foreignKey?.referenced_table || ''}`}
                    open={fkSelectionModalVisible}
                    onCancel={() => setFkSelectionModalVisible(false)}
                    footer={null}
                    width={1200}
                >
                    {currentFkColumn && (
                        <div>
                            {/* Column Selection */}
                            <div style={{ marginBottom: '16px' }}>
                                <Form.Item label="Select Columns to Display">
                                    <Select
                                        mode="multiple"
                                        value={fkSelectedColumns}
                                        onChange={handleFkColumnSelectionChange}
                                        style={{ width: '100%' }}
                                        placeholder="Select columns to display"
                                    >
                                        {fkTableColumnsFull.map(col => (
                                            <Option
                                                key={col.name}
                                                value={col.name}
                                                disabled={col.isForeignKey && col.name !== fkTableColumnsFull[0]?.name}
                                            >
                                                {col.name}
                                                {col.isForeignKey && <Tag color="orange" style={{ marginLeft: '8px' }}>FK</Tag>}
                                            </Option>
                                        ))}
                                    </Select>
                                    <div style={{ fontSize: '12px', color: '#999', marginTop: '4px' }}>
                                        First column is required. Foreign keys are excluded (except first column).
                                    </div>
                                </Form.Item>
                            </div>

                            {/* Filter Conditions */}
                            <div style={{ marginBottom: '16px', padding: '12px', background: '#f5f5f5', borderRadius: '4px' }}>
                                <div style={{ marginBottom: '8px', fontWeight: 'bold' }}>Filter Conditions</div>
                                <Space direction="vertical" style={{ width: '100%' }} size="small">
                                    {fkFilters.map((filter, index) => (
                                        <Row gutter={[8, 8]} key={index} align="middle">
                                            <Col span={6}>
                                                <Select
                                                    placeholder="Column"
                                                    value={filter.column}
                                                    onChange={(value) => handleFkFilterChange(index, 'column', value)}
                                                    style={{ width: '100%' }}
                                                >
                                                    {fkTableColumnsFull.map(col => (
                                                        <Option key={col.name} value={col.name}>
                                                            {col.name}
                                                        </Option>
                                                    ))}
                                                </Select>
                                            </Col>
                                            <Col span={4}>
                                                <Select
                                                    placeholder="Operator"
                                                    value={filter.operator}
                                                    onChange={(value) => handleFkFilterChange(index, 'operator', value)}
                                                    style={{ width: '100%' }}
                                                >
                                                    <Option value="=">=</Option>
                                                    <Option value="!=">!=</Option>
                                                    <Option value=">">&gt;</Option>
                                                    <Option value=">=">&gt;=</Option>
                                                    <Option value="<">&lt;</Option>
                                                    <Option value="<=">&lt;=</Option>
                                                    <Option value="LIKE">LIKE</Option>
                                                    <Option value="ILIKE">ILIKE</Option>
                                                </Select>
                                            </Col>
                                            <Col span={12}>
                                                <Input
                                                    placeholder="Value"
                                                    value={filter.value}
                                                    onChange={(e) => handleFkFilterChange(index, 'value', e.target.value)}
                                                    allowClear
                                                />
                                            </Col>
                                            <Col span={2}>
                                                <Button
                                                    icon={<DeleteOutlined />}
                                                    onClick={() => handleRemoveFkFilter(index)}
                                                    danger
                                                />
                                            </Col>
                                        </Row>
                                    ))}
                                    <Button
                                        icon={<PlusOutlined />}
                                        onClick={handleAddFkFilter}
                                        size="small"
                                    >
                                        Add Filter
                                    </Button>
                                </Space>
                            </div>

                            {/* Records Table */}
                            <AntTable
                                columns={fkTableColumns.map(col => ({
                                    title: col,
                                    dataIndex: col,
                                    key: col,
                                    ellipsis: true,
                                    render: (text) => {
                                        if (text === null || text === undefined) {
                                            return <span style={{ color: '#999', fontStyle: 'italic' }}>NULL</span>;
                                        }
                                        return <Text ellipsis={{ tooltip: String(text) }}>{String(text)}</Text>;
                                    }
                                }))}
                                dataSource={fkTableRecords.map((row, idx) => ({ key: idx, ...row }))}
                                loading={fkTableLoading}
                                pagination={{
                                    current: fkPagination.current,
                                    pageSize: fkPagination.pageSize,
                                    total: fkPagination.total,
                                    showSizeChanger: true,
                                    showTotal: (total) => `Total ${total} records`,
                                    pageSizeOptions: ['10', '25', '50', '100'],
                                    onChange: handleFkPaginationChange,
                                    onShowSizeChange: handleFkPaginationChange
                                }}
                                size="small"
                                scroll={{ y: 400 }}
                                onRow={(record) => ({
                                    onClick: () => handleSelectFkRecord(record),
                                    style: { cursor: 'pointer' }
                                })}
                            />
                        </div>
                    )}
                </Modal>

                {/* JSON Viewer Modal */}
                <Modal
                    title={jsonViewerTitle}
                    open={jsonViewerModalVisible}
                    onCancel={() => setJsonViewerModalVisible(false)}
                    footer={[
                        <Button key="close" onClick={() => setJsonViewerModalVisible(false)}>
                            Close
                        </Button>
                    ]}
                    width={800}
                >
                    {jsonViewerData !== null && (
                        <VCJsonViewer
                            component={{
                                input_values: {
                                    data: jsonViewerData,
                                    collapse: true,
                                    copy: true,
                                    default_expanded: true
                                }
                            }}
                        />
                    )}
                </Modal>
            </Card>
        </div>
    );
};

export default DbQuery;
