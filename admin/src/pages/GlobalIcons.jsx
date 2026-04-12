import React, { useCallback, useEffect, useRef, useState } from 'react';
import { Card, Row, Col, Typography, Input, Space, Button, Tag, Spin, message, Table, Switch, Tooltip } from 'antd';
import { CheckCircleOutlined, CloseCircleOutlined, CloudUploadOutlined, ReloadOutlined } from '@ant-design/icons';
import { api } from '../utils/api';
import ErrorModal from '../components/ErrorModal';

const { Title, Text } = Typography;

/** Must match default icons_per_batch sent to Noolva API sync (avoid huge single HTTP / proxy timeouts). */
const GLOBAL_ICONS_ICONS_PER_BATCH = 20;

const PLATFORM_ASSET_HELPER = [
    {
        key: 'android',
        platform: 'Android',
        stack: 'Kotlin + Compose',
        path: '…/android/{key}.xml',
        note: 'Android VectorDrawable',
    },
    {
        key: 'ios',
        platform: 'iOS',
        stack: 'SwiftUI',
        path: '…/ios/{key}.svg',
        note: 'currentColor (template rendering)',
    },
    {
        key: 'macos',
        platform: 'macOS',
        stack: 'SwiftUI',
        path: '…/macos/{key}.svg',
        note: 'dark-neutral fill',
    },
    {
        key: 'windows',
        platform: 'Windows',
        stack: 'C# + WinUI',
        path: '…/windows/{key}.png',
        note: '32×32 PNG for Image / bitmap icons',
    },
    {
        key: 'linux',
        platform: 'Linux',
        stack: 'Qt (C++)',
        path: '…/linux/{key}.svg',
        note: 'QSvgWidget / QIcon',
    },
    {
        key: 'web',
        platform: 'Web',
        stack: '(any)',
        path: '…/web/{key}.svg',
        note: 'default CDN + console preview',
    },
];

const platformAssetColumns = [
    { title: 'Platform', dataIndex: 'platform', key: 'platform', width: 110 },
    { title: 'Stack', dataIndex: 'stack', key: 'stack', width: 180 },
    {
        title: 'Asset in repo / icon_path_*',
        key: 'asset',
        render: (_, row) => (
            <span>
                <Text code style={{ fontSize: 12 }}>
                    {row.path}
                </Text>
                <Text type="secondary"> — {row.note}</Text>
            </span>
        ),
    },
];

function IconPreview({ iconKey, cdnUrl, onApiError }) {
    const [src, setSrc] = useState(cdnUrl || '');
    const blobUrlRef = useRef(null);
    const fallbackTried = useRef(false);
    const onApiErrorRef = useRef(onApiError);
    onApiErrorRef.current = onApiError;

    const clearBlob = useCallback(() => {
        if (blobUrlRef.current) {
            URL.revokeObjectURL(blobUrlRef.current);
            blobUrlRef.current = null;
        }
    }, []);

    const loadFromApi = useCallback(async () => {
        try {
            const blob = await api.fetchGlobalIconFileBlob(iconKey);
            clearBlob();
            const u = URL.createObjectURL(blob);
            blobUrlRef.current = u;
            setSrc(u);
        } catch (e) {
            onApiErrorRef.current(e);
        }
    }, [iconKey, clearBlob]);

    useEffect(() => {
        fallbackTried.current = false;
        clearBlob();
        setSrc(cdnUrl || '');
    }, [cdnUrl, iconKey, clearBlob]);

    useEffect(() => {
        if (!cdnUrl) {
            loadFromApi();
        }
        return () => clearBlob();
    }, [cdnUrl, iconKey, loadFromApi, clearBlob]);

    const onImgError = () => {
        if (fallbackTried.current) return;
        fallbackTried.current = true;
        loadFromApi();
    };

    return (
        <img
            src={src || undefined}
            alt={iconKey}
            onError={onImgError}
            style={{ width: 48, height: 48, objectFit: 'contain', display: 'block', margin: '0 auto' }}
        />
    );
}

export default function GlobalIcons() {
    const [icons, setIcons] = useState([]);
    const [loading, setLoading] = useState(true);
    const [search, setSearch] = useState('');
    /** When true, list request runs one S3 HEAD per icon (web key) so tiles can show On S3 / missing. */
    const [verifyS3OnList, setVerifyS3OnList] = useState(false);
    const [syncingAll, setSyncingAll] = useState(false);
    const [syncingKey, setSyncingKey] = useState(null);
    const [errorModal, setErrorModal] = useState(null);

    const handleApiError = useCallback((err) => {
        if (err?.errorData) setErrorModal(err);
        else message.error(err?.message || 'Request failed');
    }, []);

    const load = useCallback(async () => {
        try {
            setLoading(true);
            const data = await api.getGlobalIconsList({ check_s3: verifyS3OnList });
            setIcons(data.icons || []);
        } catch (e) {
            handleApiError(e);
            setIcons([]);
        } finally {
            setLoading(false);
        }
    }, [handleApiError, verifyS3OnList]);

    useEffect(() => {
        load();
    }, [load]);

    const filtered = icons.filter((row) => {
        if (!search.trim()) return true;
        const q = search.trim().toLowerCase();
        const key = String(row.icon_key || '').toLowerCase();
        const desc = String(row.description || '').toLowerCase();
        const kws = Array.isArray(row.keywords) ? row.keywords.join(' ').toLowerCase() : '';
        return key.includes(q) || desc.includes(q) || kws.includes(q);
    });

    const syncOne = async (iconKey) => {
        try {
            setSyncingKey(iconKey);
            const res = await api.syncGlobalIconsToS3({ icon_key: iconKey, sync_all: false });
            if (res.errors?.length) {
                message.warning(res.errors.join('; '));
            } else {
                message.success(`Synced ${res.count || 0} file(s) to S3`);
            }
            await load();
        } catch (e) {
            handleApiError(e);
        } finally {
            setSyncingKey(null);
        }
    };

    const syncAll = async () => {
        try {
            setSyncingAll(true);
            let cursor = null;
            let totalFiles = 0;
            let batchNum = 0;
            while (true) {
                const res = await api.syncGlobalIconsToS3({
                    sync_all: true,
                    cursor_after: cursor,
                    icons_per_batch: GLOBAL_ICONS_ICONS_PER_BATCH,
                });
                batchNum += 1;
                totalFiles += res.count || 0;
                if (res.errors?.length) {
                    message.warning(
                        `Batch ${batchNum}: ${res.errors.slice(0, 5).join('; ')}${res.errors.length > 5 ? '…' : ''}`,
                    );
                }
                const done = res.batch_complete || !res.next_cursor;
                if (done) {
                    if (!res.errors?.length) {
                        message.success(`Synced ${totalFiles} file(s) to S3 in ${batchNum} batch(es)`);
                    } else {
                        message.info(`Finished with errors: ${totalFiles} file(s) in ${batchNum} batch(es); check warnings.`);
                    }
                    break;
                }
                cursor = res.next_cursor;
                message.info(`Global icons: batch ${batchNum} uploaded (${totalFiles} files so far, next → ${cursor})…`);
            }
            await load();
        } catch (e) {
            handleApiError(e);
        } finally {
            setSyncingAll(false);
        }
    };

    return (
        <div style={{ padding: 24 }}>
            <Space direction="vertical" size="large" style={{ width: '100%' }}>
                <div style={{ display: 'flex', flexWrap: 'wrap', gap: 16, alignItems: 'center', justifyContent: 'space-between' }}>
                    <div>
                        <Title level={3} style={{ margin: 0 }}>
                            Global icons
                        </Title>
                        <Text type="secondary">
                            Each logical key has six bundled files under{' '}
                            <Text code>api/assets/global_icons/</Text> and synced S3 keys in{' '}
                            <Text code>public/global_icons/…</Text> (URL from your default S3 integration CDN + bucket prefix, e.g.{' '}
                            <Text code>cdn.avkaran.com</Text>). Card previews use that CDN URL first (no per-row S3 checks on refresh); if the object
                            fails to load, each tile falls back to one Noolva API file request. The table maps client stacks to columns and file
                            types. Sync runs in batches of {GLOBAL_ICONS_ICONS_PER_BATCH} keys per HTTP call until complete. Previews may use a
                            temporary blob URL after API fallback — open the Global icons page itself, not that blob URL in a new tab.
                        </Text>
                    </div>
                    <Space wrap>
                        <Input.Search
                            allowClear
                            placeholder="Search key, description, or keywords"
                            onChange={(e) => setSearch(e.target.value)}
                            style={{ width: 240 }}
                        />
                        <Tooltip title="Runs one S3 HEAD per icon for the web SVG key. Shows a green On S3 tag when the object exists.">
                            <Space align="center" style={{ whiteSpace: 'nowrap' }}>
                                <Switch size="small" checked={verifyS3OnList} onChange={setVerifyS3OnList} />
                                <Text type="secondary">Verify S3 (ticks)</Text>
                            </Space>
                        </Tooltip>
                        <Button icon={<ReloadOutlined />} onClick={load} disabled={loading}>
                            Refresh
                        </Button>
                        <Button type="primary" icon={<CloudUploadOutlined />} loading={syncingAll} onClick={syncAll}>
                            Sync all to S3
                        </Button>
                    </Space>
                </div>

                <Card size="small" title="Client platforms and assets (helper)">
                    <Table
                        size="small"
                        pagination={false}
                        columns={platformAssetColumns}
                        dataSource={PLATFORM_ASSET_HELPER}
                    />
                </Card>

                {loading ? (
                    <div style={{ textAlign: 'center', padding: 48 }}>
                        <Spin size="large" />
                    </div>
                ) : (
                    <Row gutter={[16, 16]}>
                        {filtered.map((row) => {
                            const cdn = row.public_url_web || '';
                            const onS3 = row.s3_exists === true;
                            const needsSync = row.s3_exists === false;
                            const noCdnUrl = !cdn;
                            const s3VerifyInconclusive = verifyS3OnList && cdn && row.s3_exists == null;
                            return (
                                <Col xs={12} sm={8} md={6} lg={4} key={row.id || row.icon_key}>
                                    <Card size="small" styles={{ body: { padding: 12 } }}>
                                        <IconPreview iconKey={row.icon_key} cdnUrl={cdn} onApiError={handleApiError} />
                                        <div style={{ marginTop: 8, textAlign: 'center' }}>
                                            <Text code style={{ fontSize: 12 }}>
                                                {row.icon_key}
                                            </Text>
                                        </div>
                                        {row.description && (
                                            <Text type="secondary" style={{ display: 'block', fontSize: 11, marginTop: 6, textAlign: 'left' }}>
                                                {row.description}
                                            </Text>
                                        )}
                                        {Array.isArray(row.keywords) && row.keywords.length > 0 && (
                                            <div style={{ marginTop: 6, textAlign: 'left' }}>
                                                {row.keywords.slice(0, 8).map((k) => (
                                                    <Tag key={k} style={{ marginBottom: 4 }}>
                                                        {k}
                                                    </Tag>
                                                ))}
                                            </div>
                                        )}
                                        <Space direction="vertical" size={6} style={{ width: '100%', marginTop: 8 }}>
                                            {onS3 && (
                                                <Tag icon={<CheckCircleOutlined />} color="success">
                                                    On S3
                                                </Tag>
                                            )}
                                            {needsSync && (
                                                <Tag icon={<CloseCircleOutlined />} color="warning">
                                                    Missing on S3
                                                </Tag>
                                            )}
                                            {s3VerifyInconclusive && (
                                                <Tooltip title="Could not confirm (e.g. HEAD failed). Try Refresh or check integration permissions.">
                                                    <Tag color="default">S3: unknown</Tag>
                                                </Tooltip>
                                            )}
                                            {noCdnUrl && <Tag color="default">No CDN URL — API preview</Tag>}
                                            <Button
                                                size="small"
                                                block
                                                type={needsSync || noCdnUrl ? 'primary' : 'default'}
                                                loading={syncingKey === row.icon_key}
                                                onClick={() => syncOne(row.icon_key)}
                                            >
                                                Sync to S3
                                            </Button>
                                        </Space>
                                    </Card>
                                </Col>
                            );
                        })}
                    </Row>
                )}
            </Space>
            <ErrorModal visible={!!errorModal} error={errorModal} onClose={() => setErrorModal(null)} />
        </div>
    );
}
