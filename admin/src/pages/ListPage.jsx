import React from 'react';
import { Table } from 'antd';

const dataSource = [
    { key: '1', name: 'John Doe', email: 'john@example.com' },
    { key: '2', name: 'Jane Smith', email: 'jane@example.com' },
];

const columns = [
    { title: 'Name', dataIndex: 'name', key: 'name' },
    { title: 'Email', dataIndex: 'email', key: 'email' },
];

const ListPage = () => <Table dataSource={dataSource} columns={columns} pagination={false} size="small" />;
export default ListPage;