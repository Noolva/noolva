import React, { useState, useEffect } from 'react';
import {
    Card,
    Table,
    Tag,
    Button,
    Space,
    message,
    Drawer,
    Form,
    Input,
    InputNumber,
    Select,
    Switch,
    Popconfirm,
    Typography,
} from 'antd';
import { ReloadOutlined, PlusOutlined, EditOutlined, DeleteOutlined, ClockCircleOutlined } from '@ant-design/icons';
import { api } from '../utils/api';
import ErrorModal from '../components/ErrorModal';
import dayjs from 'dayjs';
import utc from 'dayjs/plugin/utc';
import timezone from 'dayjs/plugin/timezone';

dayjs.extend(utc);
dayjs.extend(timezone);

const { TextArea } = Input;
const { Option } = Select;
const { Text } = Typography;

const DURATIONS = [
    { value: 'minute', label: 'minute(s)', needsTime: false },
    { value: 'hour', label: 'hour(s)', needsTime: false },
    { value: 'day', label: 'day(s)', needsTime: true },
    { value: 'week', label: 'week(s)', needsTime: true },
];

const WEEKDAYS = [
    { value: 0, label: 'Sunday' },
    { value: 1, label: 'Monday' },
    { value: 2, label: 'Tuesday' },
    { value: 3, label: 'Wednesday' },
    { value: 4, label: 'Thursday' },
    { value: 5, label: 'Friday' },
    { value: 6, label: 'Saturday' },
];

/** Build cron from UI values. Time is in user TZ; we convert to UTC for cron. */
function buildCronFromUI({ scheduleValue, scheduleDuration, scheduleTime, scheduleWeekday, tz }) {
    const v = scheduleValue || 1;
    const dur = scheduleDuration || 'minute';

    if (dur === 'minute') {
        const n = Math.max(1, Math.min(60, v));
        return n === 1 ? '* * * * *' : `*/${n} * * * *`;
    }
    if (dur === 'hour') {
        const n = Math.max(1, Math.min(24, v));
        return n === 1 ? '0 * * * *' : `0 */${n} * * *`;
    }
    if (dur === 'day') {
        const timeStr = scheduleTime || '00:00';
        const [h, m] = timeStr.split(':').map(Number);
        const local = dayjs().tz(tz).hour(h).minute(m || 0).second(0).millisecond(0);
        const utcTime = local.utc();
        const min = utcTime.minute();
        const hour = utcTime.hour();
        return `${min} ${hour} * * *`;
    }
    if (dur === 'week') {
        const timeStr = scheduleTime || '00:00';
        const [h, m] = timeStr.split(':').map(Number);
        const dow = scheduleWeekday ?? 0;
        const local = dayjs().tz(tz).hour(h).minute(m || 0).second(0).millisecond(0);
        const utcTime = local.utc();
        const min = utcTime.minute();
        const hour = utcTime.hour();
        return `${min} ${hour} * * ${dow}`;
    }
    return '0 * * * *';
}

/** Parse cron into UI values (best-effort). */
function parseCronToUI(cron, tz) {
    if (!cron || !cron.trim()) return { scheduleValue: 5, scheduleDuration: 'minute', scheduleTime: '00:00', scheduleWeekday: 0 };
    const parts = cron.trim().split(/\s+/);
    if (parts.length < 5) return { scheduleValue: 5, scheduleDuration: 'minute', scheduleTime: '00:00', scheduleWeekday: 0 };

    const [min, hour, dom, month, dow] = parts;

    // Every minute: * * * * * or */N * * * *
    if (min === '*' && hour === '*' && dom === '*' && month === '*') {
        return { scheduleValue: 1, scheduleDuration: 'minute', scheduleTime: '00:00', scheduleWeekday: 0 };
    }
    if (min.startsWith('*/') && hour === '*' && dom === '*' && month === '*') {
        const n = parseInt(min.slice(2), 10);
        return { scheduleValue: n || 1, scheduleDuration: 'minute', scheduleTime: '00:00', scheduleWeekday: 0 };
    }
    // Every hour: 0 * * * * or 0 */N * * *
    if (min === '0' && hour === '*' && dom === '*' && month === '*') {
        return { scheduleValue: 1, scheduleDuration: 'hour', scheduleTime: '00:00', scheduleWeekday: 0 };
    }
    if (min === '0' && hour.startsWith('*/') && dom === '*' && month === '*') {
        const n = parseInt(hour.slice(2), 10);
        return { scheduleValue: n || 1, scheduleDuration: 'hour', scheduleTime: '00:00', scheduleWeekday: 0 };
    }
    // Every day or week: numeric min, hour, dom=*, month=*, dow=* or 0-6
    if (dom === '*' && month === '*' && (dow === '*' || dow === '?' || /^[0-6]$/.test(dow))) {
        const h = parseInt(hour, 10);
        const m = parseInt(min, 10);
        if (!Number.isNaN(h) && !Number.isNaN(m)) {
            const utcTime = dayjs.utc().hour(h).minute(m).second(0);
            const local = utcTime.tz(tz);
            const timeStr = `${String(local.hour()).padStart(2, '0')}:${String(local.minute()).padStart(2, '0')}`;
            if (dow === '*' || dow === '?') {
                return { scheduleValue: 1, scheduleDuration: 'day', scheduleTime: timeStr, scheduleWeekday: 0 };
            }
            return { scheduleValue: 1, scheduleDuration: 'week', scheduleTime: timeStr, scheduleWeekday: parseInt(dow, 10) };
        }
    }
    return { scheduleValue: 5, scheduleDuration: 'minute', scheduleTime: '00:00', scheduleWeekday: 0 };
}

const Schedulers = () => {
    const [schedulers, setSchedulers] = useState([]);
    const [templates, setTemplates] = useState([]);
    const [loading, setLoading] = useState(false);
    const [drawerVisible, setDrawerVisible] = useState(false);
    const [editingId, setEditingId] = useState(null);
    const [form] = Form.useForm();
    const [errorModal, setErrorModal] = useState(null);
    const [nextRuns, setNextRuns] = useState([]);
    const [displayConfig, setDisplayConfig] = useState({ timezone: 'Asia/Kolkata', time_format: 'DD/MM/YYYY h:mm A' });

    const tz = displayConfig.timezone || 'Asia/Kolkata';
    const timeFmt = displayConfig.time_format || 'DD/MM/YYYY h:mm A';
    const fullFmt = timeFmt; // date + time format from config

    const fetchDisplayConfig = async () => {
        try {
            const cfg = await api.getDisplayConfig();
            setDisplayConfig({ timezone: cfg.timezone || 'Asia/Kolkata', time_format: cfg.time_format || 'DD/MM/YYYY h:mm A' });
        } catch {
            setDisplayConfig({ timezone: 'Asia/Kolkata', time_format: 'DD/MM/YYYY h:mm A' });
        }
    };

    const fetchSchedulers = async () => {
        try {
            setLoading(true);
            const data = await api.getSchedulers();
            setSchedulers(Array.isArray(data) ? data : []);
        } catch (error) {
            message.error('Failed to load schedulers: ' + (error.message || 'Unknown error'));
            if (error.errorData) setErrorModal(error);
            setSchedulers([]);
        } finally {
            setLoading(false);
        }
    };

    const fetchTemplates = async () => {
        try {
            const data = await api.getJobTemplates();
            setTemplates(Array.isArray(data) ? data : []);
        } catch (_) {
            setTemplates([]);
        }
    };

    useEffect(() => {
        fetchDisplayConfig();
        fetchSchedulers();
        fetchTemplates();
    }, []);

    const scheduleDuration = Form.useWatch('schedule_duration', form);
    const scheduleValue = Form.useWatch('schedule_value', form);
    const scheduleTime = Form.useWatch('schedule_time', form);
    const scheduleWeekday = Form.useWatch('schedule_weekday', form);

    const needsTime = DURATIONS.find((d) => d.value === scheduleDuration)?.needsTime ?? false;

    const syncCronToForm = () => {
        const cron = buildCronFromUI({
            scheduleValue,
            scheduleDuration,
            scheduleTime,
            scheduleWeekday,
            tz,
        });
        form.setFieldsValue({ cron_expression: cron });
    };

    useEffect(() => {
        if (!drawerVisible) return;
        syncCronToForm();
    }, [scheduleValue, scheduleDuration, scheduleTime, scheduleWeekday, drawerVisible]);

    const currentCron = Form.useWatch('cron_expression', form);

    useEffect(() => {
        if (!drawerVisible || !currentCron || !currentCron.trim()) {
            setNextRuns([]);
            return;
        }
        let cancelled = false;
        api.getCronNextRuns(currentCron.trim(), 3)
            .then((runs) => {
                if (!cancelled) setNextRuns(Array.isArray(runs) ? runs : []);
            })
            .catch(() => {
                if (!cancelled) setNextRuns([]);
            });
        return () => { cancelled = true; };
    }, [drawerVisible, currentCron]);

    const openAdd = () => {
        setEditingId(null);
        form.setFieldsValue({
            name: '',
            description: '',
            schedule_value: 5,
            schedule_duration: 'minute',
            schedule_time: '00:00',
            schedule_weekday: 0,
            cron_expression: '*/5 * * * *',
            template_id: undefined,
            payload: '{}',
            is_enabled: true,
        });
        setNextRuns([]);
        setDrawerVisible(true);
    };

    const openEdit = (record) => {
        setEditingId(record.id);
        const cron = record.cron_expression || '0 * * * *';
        const ui = parseCronToUI(cron, tz);
        form.setFieldsValue({
            name: record.name,
            description: record.description || '',
            schedule_value: ui.scheduleValue,
            schedule_duration: ui.scheduleDuration,
            schedule_time: ui.scheduleTime,
            schedule_weekday: ui.scheduleWeekday,
            cron_expression: cron,
            template_id: record.template_id,
            payload: typeof record.payload === 'string' ? record.payload : JSON.stringify(record.payload || {}, null, 2),
            is_enabled: record.is_enabled,
        });
        setNextRuns([]);
        setDrawerVisible(true);
    };

    const handleSubmit = async () => {
        try {
            const values = await form.validateFields();
            let payloadObj = {};
            if (values.payload) {
                try {
                    payloadObj = JSON.parse(values.payload);
                } catch {
                    message.error('Payload must be valid JSON');
                    return;
                }
            }
            const cron = buildCronFromUI({
                scheduleValue: values.schedule_value,
                scheduleDuration: values.schedule_duration,
                scheduleTime: values.schedule_time,
                scheduleWeekday: values.schedule_weekday,
                tz,
            });
            const body = {
                name: values.name,
                description: values.description || null,
                cron_expression: cron,
                template_id: values.template_id,
                payload: payloadObj,
                is_enabled: values.is_enabled,
            };
            if (editingId) {
                await api.updateScheduler(editingId, body);
                message.success('Scheduler updated');
            } else {
                await api.createScheduler(body);
                message.success('Scheduler created');
            }
            setDrawerVisible(false);
            fetchSchedulers();
        } catch (error) {
            if (error.errorFields) return;
            message.error(error.message || 'Failed to save');
            if (error.errorData) setErrorModal(error);
        }
    };

    const handleDelete = async (id) => {
        try {
            await api.deleteScheduler(id);
            message.success('Scheduler deleted');
            fetchSchedulers();
        } catch (error) {
            message.error(error.message || 'Failed to delete');
            if (error.errorData) setErrorModal(error);
        }
    };

    const formatTime = (isoStr) => {
        if (!isoStr) return '—';
        try {
            return dayjs.utc(isoStr).tz(tz).format(fullFmt);
        } catch {
            return isoStr;
        }
    };

    const columns = [
        { title: 'Name', dataIndex: 'name', key: 'name' },
        { title: 'Description', dataIndex: 'description', key: 'description', ellipsis: true },
        { title: 'Cron', dataIndex: 'cron_expression', key: 'cron_expression', width: 120 },
        { title: 'Template', dataIndex: 'template_name', key: 'template_name' },
        {
            title: 'Enabled',
            dataIndex: 'is_enabled',
            key: 'is_enabled',
            width: 90,
            render: (v) => (v ? <Tag color="green">Yes</Tag> : <Tag>No</Tag>),
        },
        { title: 'Last run', dataIndex: 'last_run_at', key: 'last_run_at', width: 165, render: formatTime },
        { title: 'Next run', dataIndex: 'next_run_at', key: 'next_run_at', width: 165, render: formatTime },
        {
            title: 'Actions',
            key: 'actions',
            width: 120,
            render: (_, record) => (
                <Space>
                    <Button type="link" size="small" icon={<EditOutlined />} onClick={() => openEdit(record)} />
                    <Popconfirm title="Delete this scheduler?" onConfirm={() => handleDelete(record.id)}>
                        <Button type="link" size="small" danger icon={<DeleteOutlined />} />
                    </Popconfirm>
                </Space>
            ),
        },
    ];

    return (
        <>
            <Card
                title={
                    <Space>
                        <ClockCircleOutlined />
                        Schedulers (cron jobs)
                    </Space>
                }
                extra={
                    <Space>
                        <Button type="primary" icon={<PlusOutlined />} onClick={openAdd}>
                            Add scheduler
                        </Button>
                        <Button icon={<ReloadOutlined />} onClick={fetchSchedulers} loading={loading}>
                            Refresh
                        </Button>
                    </Space>
                }
            >
                <Table
                    rowKey="id"
                    columns={columns}
                    dataSource={schedulers}
                    loading={loading}
                    pagination={{ pageSize: 20 }}
                    size="small"
                />
            </Card>

            <Drawer
                title={editingId ? 'Edit scheduler' : 'Add scheduler'}
                open={drawerVisible}
                onClose={() => setDrawerVisible(false)}
                width={480}
                footer={
                    <Space>
                        <Button onClick={() => setDrawerVisible(false)}>Cancel</Button>
                        <Button type="primary" onClick={handleSubmit}>
                            {editingId ? 'Update' : 'Create'}
                        </Button>
                    </Space>
                }
            >
                <Form form={form} layout="vertical">
                    <Form.Item name="name" label="Name" rules={[{ required: true }]}>
                        <Input placeholder="e.g. Daily report" />
                    </Form.Item>
                    <Form.Item name="description" label="Description">
                        <Input placeholder="Optional" />
                    </Form.Item>

                    <Form.Item label="Schedule" required>
                        <Space direction="vertical" style={{ width: '100%' }} size="middle">
                            <Space wrap>
                                <Form.Item name="schedule_value" noStyle rules={[{ required: true }]}>
                                    <InputNumber min={1} max={60} style={{ width: 72 }} placeholder="1" />
                                </Form.Item>
                                <Form.Item name="schedule_duration" noStyle rules={[{ required: true }]}>
                                    <Select style={{ width: 140 }} placeholder="Duration">
                                        {DURATIONS.map((d) => (
                                            <Option key={d.value} value={d.value}>
                                                {d.label}
                                            </Option>
                                        ))}
                                    </Select>
                                </Form.Item>
                            </Space>
                            {needsTime && (
                                <Space wrap align="center">
                                    <Text type="secondary">At:</Text>
                                    <Form.Item name="schedule_time" noStyle>
                                        <Input type="time" style={{ width: 120 }} />
                                    </Form.Item>
                                    {scheduleDuration === 'week' && (
                                        <>
                                            <Text type="secondary">on</Text>
                                            <Form.Item name="schedule_weekday" noStyle>
                                                <Select style={{ width: 120 }} placeholder="Day">
                                                    {WEEKDAYS.map((d) => (
                                                        <Option key={d.value} value={d.value}>
                                                            {d.label}
                                                        </Option>
                                                    ))}
                                                </Select>
                                            </Form.Item>
                                        </>
                                    )}
                                </Space>
                            )}
                            <Form.Item name="cron_expression" hidden>
                                <Input />
                            </Form.Item>
                            {nextRuns.length > 0 && (
                                <div>
                                    <Text type="secondary" style={{ fontSize: 12 }}>
                                        Next 3 runs ({tz}):
                                    </Text>
                                    <ul style={{ margin: '4px 0 0 0', paddingLeft: 18, fontSize: 12 }}>
                                        {nextRuns.map((r, i) => (
                                            <li key={i}>
                                                <Text type="secondary">{formatTime(r)}</Text>
                                            </li>
                                        ))}
                                    </ul>
                                </div>
                            )}
                        </Space>
                    </Form.Item>

                    <Form.Item name="template_id" label="Job template" rules={[{ required: true }]}>
                        <Select placeholder="Select template" showSearch optionFilterProp="children">
                            {templates.map((t) => (
                                <Option key={t.template_id} value={t.template_id}>
                                    {t.name}
                                </Option>
                            ))}
                        </Select>
                    </Form.Item>
                    <Form.Item name="payload" label="Payload (JSON)">
                        <TextArea rows={4} placeholder='{"key": "value"}' />
                    </Form.Item>
                    <Form.Item name="is_enabled" label="Enabled" valuePropName="checked">
                        <Switch />
                    </Form.Item>
                </Form>
            </Drawer>

            {errorModal && (
                <ErrorModal
                    visible={!!errorModal}
                    error={errorModal}
                    onClose={() => setErrorModal(null)}
                />
            )}
        </>
    );
};

export default Schedulers;
