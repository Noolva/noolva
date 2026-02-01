/**
 * QueryBuilder - Reusable SQL query builder with joins and table alias support.
 * Used in DbQuery page and ApiEndpoints custom query section.
 * Props:
 *   - value: SQL string (controlled)
 *   - onChange: (sql, builder) => void
 *   - dataSource: 'database' | 'dataModels'
 *   - dataModels: optional, when dataSource='dataModels' - [{model_id, model_name, table_name, table_alias}]
 *   - onExecute: optional callback when Execute is clicked (DbQuery)
 *   - compact: optional, for drawer/embedded use
 */
import React, { useState, useEffect } from 'react';
import {
    Form,
    Select,
    Input,
    Button,
    Space,
    Row,
    Col,
    InputNumber,
    Typography,
    Tabs
} from 'antd';
import { PlusOutlined, DeleteOutlined, PlayCircleOutlined } from '@ant-design/icons';
import { api } from '../../../utils/api';

const { Option } = Select;
const { TextArea } = Input;
const { Text } = Typography;

const JOIN_TYPES = ['INNER', 'LEFT', 'RIGHT', 'FULL'];
const OPERATORS = ['=', '!=', '>', '<', '>=', '<=', 'LIKE', 'ILIKE', 'IN'];

const buildQueryFromBuilder = (builder, tableAliases = {}) => {
    if (!builder.tables?.length) return '';

    const mainTable = builder.tables[0];
    const mainAlias = builder.tableAliases?.[mainTable] || tableAliases[mainTable] || mainTable.substring(0, 1).toLowerCase();
    const aliasMap = { [mainTable]: mainAlias };

    let sql = 'SELECT ';
    if (builder.selectedColumns?.length === 0) {
        sql += '*';
    } else {
        const colParts = (builder.selectedColumns || []).map((col) => {
            const [tbl, colName] = (col || '').includes('::') ? col.split('::') : [null, col];
            const alias = tbl ? (aliasMap[tbl] || tableAliases[tbl] || tbl) : mainAlias;
            const c = colName || col;
            return c ? `"${alias}"."${c}"` : null;
        }).filter(Boolean);
        sql += colParts.length ? colParts.join(', ') : '*';
    }

    sql += ` FROM "${mainTable}" AS ${mainAlias}`;

    (builder.joins || []).forEach((join) => {
        const joinAlias = join.alias || join.table?.substring(0, 1).toLowerCase();
        aliasMap[join.table] = joinAlias;
        const leftQual = join.leftTable ? `"${aliasMap[join.leftTable] || join.leftTable}"."${join.leftCol}"` : `"${mainAlias}"."${join.leftCol}"`;
        const rightQual = `"${joinAlias}"."${join.rightCol}"`;
        sql += ` ${join.type || 'INNER'} JOIN "${join.table}" AS ${joinAlias} ON ${leftQual} = ${rightQual}`;
    });

    if (builder.whereConditions?.length > 0) {
        const conditions = builder.whereConditions
            .filter((c) => c.column && c.value)
            .map((c) => {
                const [tbl, colName] = c.column.includes('::') ? c.column.split('::') : [null, c.column];
                const alias = tbl ? (aliasMap[tbl] || tableAliases[tbl] || tbl) : mainAlias;
                const col = colName || c.column;
                const escaped = (c.value || '').replace(/'/g, "''");
                const qual = `"${alias}"."${col}"`;
                if (c.operator === 'IN') {
                    const vals = escaped.split(',').map((v) => `'${v.trim()}'`).join(', ');
                    return `${qual} IN (${vals})`;
                }
                return `${qual} ${c.operator || '='} '${escaped}'`;
            })
            .filter(Boolean);
        if (conditions.length) sql += ' WHERE ' + conditions.join(' AND ');
    }

    if (builder.orderBy?.length > 0) {
        const orderParts = builder.orderBy.map((col) => {
            const [tbl, colName] = col.includes('::') ? col.split('::') : [null, col];
            const alias = tbl ? (aliasMap[tbl] || tableAliases[tbl] || tbl) : mainAlias;
            return `"${alias}"."${colName || col}"`;
        });
        sql += ' ORDER BY ' + orderParts.join(', ');
    }

    if (builder.limit) sql += ` LIMIT ${builder.limit}`;
    return sql;
};

const QueryBuilder = ({
    value = '',
    onChange,
    dataSource = 'database',
    dataModels = [],
    onExecute,
    compact = false,
    showExecute = true,
    showGeneratedSql = true,
    showRawSqlTab = true,
}) => {
    const [suggestions, setSuggestions] = useState(null);
    const [builder, setBuilder] = useState({
        tables: [],
        tableAliases: {},
        selectedColumns: [],
        joins: [],
        whereConditions: [],
        orderBy: [],
        limit: 1000,
    });

    const tableAliasesFromDataModels = {};
    (dataModels || []).forEach((m) => {
        if (m.table_alias) tableAliasesFromDataModels[m.table_name] = m.table_alias;
    });

    const tablesForSelect = dataSource === 'dataModels' && dataModels?.length
        ? dataModels.map((m) => ({
            table_name: m.table_name,
            table_alias: m.table_alias,
        }))
        : (suggestions?.tables || []).map((t) => ({
            table_name: t,
            table_alias: suggestions?.table_aliases?.[t],
        })).filter((t) => t.table_name);

    const allTableAliases = { ...(suggestions?.table_aliases || {}), ...tableAliasesFromDataModels };

    useEffect(() => {
        api.getQuerySuggestions()
            .then((s) => setSuggestions(s))
            .catch((e) => console.error('QueryBuilder: failed to load suggestions', e));
    }, []);

    const updateBuilder = (newBuilder) => {
        setBuilder(newBuilder);
        const sql = buildQueryFromBuilder(newBuilder, allTableAliases);
        onChange?.(sql, newBuilder);
    };

    const getColumnsForTable = (tableName) => {
        if (!suggestions?.columns?.[tableName] && dataSource === 'dataModels') return [];
        return suggestions?.columns?.[tableName] || [];
    };

    const getAllColumnsWithTable = () => {
        const mainTable = builder.tables[0];
        if (!mainTable) return [];
        const cols = getColumnsForTable(mainTable);
        const alias = builder.tableAliases?.[mainTable] || allTableAliases[mainTable] || mainTable;
        const result = cols.map((c) => ({ value: `${mainTable}::${c.name}`, label: `${alias}.${c.name}` }));
        (builder.joins || []).forEach((j) => {
            const jCols = getColumnsForTable(j.table);
            const jAlias = j.alias || allTableAliases[j.table] || j.table;
            jCols.forEach((c) => result.push({ value: `${j.table}::${c.name}`, label: `${jAlias}.${c.name}` }));
        });
        return result;
    };

    const handleMainTableChange = (tableName) => {
        const alias = allTableAliases[tableName] || (tableName ? tableName.substring(0, 1).toLowerCase() : '');
        const newBuilder = {
            ...builder,
            tables: tableName ? [tableName] : [],
            tableAliases: { ...(builder.tableAliases || {}), [tableName]: alias },
            selectedColumns: [],
        };
        updateBuilder(newBuilder);
    };

    const handleAddJoin = () => {
        const joinTables = tablesForSelect
            .map((t) => t.table_name || t)
            .filter((t) => t && !builder.tables?.includes(t) && !(builder.joins || []).some((j) => j.table === t));
        if (joinTables.length === 0) return;
        const mainTable = builder.tables[0];
        const mainCols = getColumnsForTable(mainTable);
        const joinTable = joinTables[0];
        const joinCols = getColumnsForTable(joinTable);
        const newJoin = {
            table: joinTable,
            alias: allTableAliases[joinTable] || joinTable.substring(0, 1).toLowerCase(),
            type: 'INNER',
            leftTable: mainTable,
            leftCol: mainCols[0]?.name || 'id',
            rightCol: joinCols.find((c) => c.name?.toLowerCase().includes('id'))?.name || joinCols[0]?.name || 'id',
        };
        const newBuilder = {
            ...builder,
            joins: [...(builder.joins || []), newJoin],
        };
        updateBuilder(newBuilder);
    };

    const mainTable = builder.tables?.[0];
    const allColumns = getAllColumnsWithTable();

    const builderContent = (
        <Form layout="vertical" size={compact ? 'small' : 'middle'}>
            <Row gutter={16}>
                <Col span={compact ? 12 : 8}>
                    <Form.Item label="From Table">
                        <Select
                            placeholder="Select table"
                            showSearch
                            value={mainTable}
                            onChange={handleMainTableChange}
                            optionFilterProp="children"
                            style={{ width: '100%' }}
                        >
                            {tablesForSelect.map((t) => {
                                const name = t.table_name || t;
                                const alias = t.table_alias || allTableAliases[name];
                                return (
                                    <Option key={name} value={name}>
                                        {name} {alias ? `(${alias})` : ''}
                                    </Option>
                                );
                            })}
                        </Select>
                    </Form.Item>
                </Col>
                <Col span={compact ? 12 : 8}>
                    <Form.Item label="Limit">
                        <InputNumber
                            value={builder.limit}
                            onChange={(v) => updateBuilder({ ...builder, limit: v || 1000 })}
                            min={1}
                            max={10000}
                            style={{ width: '100%' }}
                        />
                    </Form.Item>
                </Col>
            </Row>

            {mainTable && (
                <>
                    <Form.Item label="Select Columns">
                        <Select
                            mode="multiple"
                            placeholder="Select columns (empty = *)"
                            value={builder.selectedColumns}
                            onChange={(vals) => updateBuilder({ ...builder, selectedColumns: vals })}
                            style={{ width: '100%' }}
                            optionFilterProp="children"
                        >
                            {allColumns.map((c) => (
                                <Option key={c.value} value={c.value}>
                                    {c.label}
                                </Option>
                            ))}
                        </Select>
                    </Form.Item>

                    <Form.Item label="Joins">
                        <Space direction="vertical" style={{ width: '100%' }}>
                            {(builder.joins || []).map((join, idx) => (
                                <Row key={idx} gutter={8} align="middle">
                                    <Col span={4}>
                                        <Select
                                            value={join.type}
                                            onChange={(v) => {
                                                const j = [...(builder.joins || [])];
                                                j[idx] = { ...j[idx], type: v };
                                                updateBuilder({ ...builder, joins: j });
                                            }}
                                            style={{ width: '100%' }}
                                            showSearch
                                            optionFilterProp="children"
                                        >
                                            {JOIN_TYPES.map((t) => (
                                                <Option key={t} value={t}>{t}</Option>
                                            ))}
                                        </Select>
                                    </Col>
                                    <Col span={5}>
                                        <Select
                                            value={join.table}
                                            onChange={(v) => {
                                                const j = [...(builder.joins || [])];
                                                j[idx] = { ...j[idx], table: v, alias: allTableAliases[v] || v?.substring(0, 1).toLowerCase() };
                                                updateBuilder({ ...builder, joins: j });
                                            }}
                                            style={{ width: '100%' }}
                                            placeholder="Table"
                                            showSearch
                                            optionFilterProp="children"
                                        >
                                            {(tablesForSelect || [])
                                                .map((t) => t.table_name || t)
                                                .filter((t) => t && t !== mainTable && !(builder.joins || []).some((j, i) => i !== idx && j.table === t))
                                                .map((t) => (
                                                    <Option key={t} value={t}>{t}</Option>
                                                ))}
                                        </Select>
                                    </Col>
                                    <Col span={2}><Text type="secondary">AS</Text></Col>
                                    <Col span={3}>
                                        <Input
                                            value={join.alias}
                                            onChange={(e) => {
                                                const j = [...(builder.joins || [])];
                                                j[idx] = { ...j[idx], alias: e.target.value };
                                                updateBuilder({ ...builder, joins: j });
                                            }}
                                            placeholder="alias"
                                        />
                                    </Col>
                                    <Col span={4}>
                                        <Select
                                            value={join.leftTable ? `${join.leftTable}::${join.leftCol}` : `${mainTable}::${join.leftCol}`}
                                            onChange={(val) => {
                                                const [tbl, col] = val.split('::');
                                                const j = [...(builder.joins || [])];
                                                j[idx] = { ...j[idx], leftTable: tbl || mainTable, leftCol: col };
                                                updateBuilder({ ...builder, joins: j });
                                            }}
                                            style={{ width: '100%' }}
                                            placeholder="Left col"
                                            showSearch
                                            optionFilterProp="children"
                                        >
                                            {getColumnsForTable(join.leftTable || mainTable).map((c) => (
                                                <Option key={c.name} value={`${join.leftTable || mainTable}::${c.name}`}>{c.name}</Option>
                                            ))}
                                        </Select>
                                    </Col>
                                    <Col span={2}><Text type="secondary">=</Text></Col>
                                    <Col span={4}>
                                        <Select
                                            value={`${join.table}::${join.rightCol}`}
                                            onChange={(val) => {
                                                const col = val.split('::')[1];
                                                const j = [...(builder.joins || [])];
                                                j[idx] = { ...j[idx], rightCol: col };
                                                updateBuilder({ ...builder, joins: j });
                                            }}
                                            style={{ width: '100%' }}
                                            placeholder="Right col"
                                            showSearch
                                            optionFilterProp="children"
                                        >
                                            {getColumnsForTable(join.table).map((c) => (
                                                <Option key={c.name} value={`${join.table}::${c.name}`}>{c.name}</Option>
                                            ))}
                                        </Select>
                                    </Col>
                                    <Col span={2}>
                                        <Button
                                            type="text"
                                            danger
                                            icon={<DeleteOutlined />}
                                            onClick={() => {
                                                const j = (builder.joins || []).filter((_, i) => i !== idx);
                                                updateBuilder({ ...builder, joins: j });
                                            }}
                                        />
                                    </Col>
                                </Row>
                            ))}
                            <Button type="dashed" icon={<PlusOutlined />} onClick={handleAddJoin}>
                                Add Join
                            </Button>
                        </Space>
                    </Form.Item>

                    <Form.Item label="Where Conditions">
                        <Space direction="vertical" style={{ width: '100%' }}>
                            {(builder.whereConditions || []).map((cond, idx) => (
                                <Space key={idx} wrap>
                                    <Select
                                        placeholder="Column"
                                        value={cond.column}
                                        onChange={(v) => {
                                            const w = [...(builder.whereConditions || [])];
                                            w[idx] = { ...w[idx], column: v };
                                            updateBuilder({ ...builder, whereConditions: w });
                                        }}
                                        style={{ width: 180 }}
                                        showSearch
                                        optionFilterProp="children"
                                    >
                                        {allColumns.map((c) => (
                                            <Option key={c.value} value={c.value}>{c.label}</Option>
                                        ))}
                                    </Select>
                                    <Select
                                        placeholder="Op"
                                        value={cond.operator}
                                        onChange={(v) => {
                                            const w = [...(builder.whereConditions || [])];
                                            w[idx] = { ...w[idx], operator: v };
                                            updateBuilder({ ...builder, whereConditions: w });
                                        }}
                                        style={{ width: 90 }}
                                        showSearch
                                        optionFilterProp="children"
                                    >
                                        {OPERATORS.map((o) => (
                                            <Option key={o} value={o}>{o}</Option>
                                        ))}
                                    </Select>
                                    <Input
                                        placeholder="Value"
                                        value={cond.value}
                                        onChange={(e) => {
                                            const w = [...(builder.whereConditions || [])];
                                            w[idx] = { ...w[idx], value: e.target.value };
                                            updateBuilder({ ...builder, whereConditions: w });
                                        }}
                                        style={{ width: 150 }}
                                    />
                                    <Button
                                        type="text"
                                        danger
                                        icon={<DeleteOutlined />}
                                        onClick={() => {
                                            const w = (builder.whereConditions || []).filter((_, i) => i !== idx);
                                            updateBuilder({ ...builder, whereConditions: w });
                                        }}
                                    />
                                </Space>
                            ))}
                            <Button
                                type="dashed"
                                icon={<PlusOutlined />}
                                onClick={() => updateBuilder({
                                    ...builder,
                                    whereConditions: [...(builder.whereConditions || []), { column: '', operator: '=', value: '' }],
                                })}
                            >
                                Add Condition
                            </Button>
                        </Space>
                    </Form.Item>

                    <Form.Item label="Order By">
                        <Select
                            mode="multiple"
                            placeholder="Columns to order by"
                            value={builder.orderBy}
                            onChange={(v) => updateBuilder({ ...builder, orderBy: v })}
                            style={{ width: '100%' }}
                            showSearch
                            optionFilterProp="children"
                        >
                            {allColumns.map((c) => (
                                <Option key={c.value} value={c.value}>{c.label}</Option>
                            ))}
                        </Select>
                    </Form.Item>
                </>
            )}

            {showExecute && onExecute && (
                <Form.Item>
                    <Button type="primary" icon={<PlayCircleOutlined />} onClick={() => onExecute(buildQueryFromBuilder(builder, allTableAliases))}>
                        Execute Query
                    </Button>
                </Form.Item>
            )}

            {showGeneratedSql && value && (
                <Form.Item label="Generated SQL">
                    <TextArea value={value} readOnly rows={4} style={{ fontFamily: 'monospace', fontSize: 12 }} />
                </Form.Item>
            )}
        </Form>
    );

    const rawSqlContent = (
        <Form.Item label="SQL Query">
            <TextArea
                value={value}
                onChange={(e) => onChange?.(e.target.value, null)}
                placeholder="SELECT ... FROM table alias JOIN table2 alias2 ON ..."
                rows={8}
                style={{ fontFamily: 'monospace', fontSize: 13 }}
            />
        </Form.Item>
    );

    if (showRawSqlTab) {
        return (
            <Tabs
                defaultActiveKey="builder"
                items={[
                    { key: 'builder', label: 'Query Builder', children: builderContent },
                    { key: 'raw', label: 'Raw SQL', children: rawSqlContent },
                ]}
            />
        );
    }

    return builderContent;
};

export default QueryBuilder;
