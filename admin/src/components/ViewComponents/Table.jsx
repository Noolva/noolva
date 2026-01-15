import React from 'react';
import { Table as AntTable } from 'antd';

const Table = ({ key, component }) => {
    const columns = [{
        title: 'Name',
        dataIndex: 'name',
        render: text => <a href="#">{text}</a>,
    }, {
        title: 'Age',
        dataIndex: 'age',
    }, {
        title: 'Address',
        dataIndex: 'address',
    }];
    const dataSource = [{
        key: '1',
        name: 'John Brown',
        age: 32,
        address: 'New York No. 1 Lake Park',
    }, {
        key: '2',
        name: 'Jim Green',
        age: 42,
        address: 'London No. 1 Lake Park',
    }, {
        key: '3',
        name: 'Joe Black',
        age: 32,
        address: 'Sidney No. 1 Lake Park',
    }, {
        key: '4',
        name: 'Disabled User',
        age: 99,
        address: 'Sidney No. 1 Lake Park',
    }];
    const rowSelection = {
        onChange: (selectedRowKeys, selectedRows) => {
            console.log(`selectedRowKeys: ${selectedRowKeys}`, 'selectedRows: ', selectedRows);
        },
        getCheckboxProps: record => ({
            disabled: record.name === 'Disabled User', // Column configuration not to be checked
        }),
    };
    return (
        <AntTable
            rowSelection={rowSelection}
            dataSource={dataSource}
            columns={columns}
            bordered
            title={() => 'Header'}
            footer={() => 'Footer'}
            pagination={false}
        />
    );
};

export default Table;