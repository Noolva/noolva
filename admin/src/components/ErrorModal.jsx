import React from 'react';
import { Modal, Typography, Space, Button } from 'antd';
import { ExclamationCircleOutlined, CloseCircleOutlined } from '@ant-design/icons';

const { Title, Text, Paragraph } = Typography;

/**
 * Corporate-style Error Modal Component
 * Displays errors in a professional, user-friendly manner
 */
const ErrorModal = ({ 
    visible, 
    onClose, 
    error = null,
    title = "Something went wrong",
    showDetails = false 
}) => {
    if (!visible) return null;

    // Extract error information
    let errorMessage = "An unexpected error occurred. Please try again.";
    let errorSolution = "If the problem persists, please contact support.";
    let errorDetails = null;
    let errorCode = null;

    if (error) {
        console.log('ErrorModal received error:', {
            hasErrorData: !!error.errorData,
            hasResponse: !!error.response,
            isApiError: error.isApiError,
            isNetworkError: error.isNetworkError,
            errorData: error.errorData,
            responseData: error.response?.data,
            message: error.message,
            fullError: error
        });

        // First, check if error has errorData attached (from axios interceptor)
        // This is the primary source for API errors
        if (error.errorData) {
            const errorData = error.errorData;
            console.log('ErrorModal: Found errorData:', errorData);
            if (errorData.description) {
                errorMessage = errorData.description;
                errorSolution = errorData.solution || errorSolution;
                errorCode = errorData.code;
                errorDetails = errorData.details;
                console.log('ErrorModal: Using errorData.description:', errorMessage);
            } else if (errorData.message) {
                errorMessage = errorData.message;
                console.log('ErrorModal: Using errorData.message:', errorMessage);
            } else {
                console.warn('ErrorModal: errorData exists but no description or message found:', errorData);
            }
        }
        // Then check error.response.data (direct axios error - fallback)
        else if (error.response?.data) {
            const errorData = error.response.data;
            console.log('Checking error.response.data:', errorData);
            
            // Check if it's our structured ERPError format
            if (errorData.description) {
                errorMessage = errorData.description;
                errorSolution = errorData.solution || errorSolution;
                errorCode = errorData.code;
                errorDetails = errorData.details;
                console.log('Using response.data.description:', errorMessage);
            } else if (errorData.message) {
                errorMessage = errorData.message;
            } else if (errorData.detail) {
                errorMessage = errorData.detail;
            } else if (typeof errorData === 'string') {
                errorMessage = errorData;
            }
        }
        // Fallback to error.message
        else if (error.message) {
            // Only treat as network error if it's actually a network error
            // (no response received, not just a 400/500 status)
            if (error.isNetworkError || (error.request && !error.response)) {
                errorMessage = "Unable to connect to the server. Please check your internet connection.";
                errorSolution = "Verify your network connection and try again.";
            } else {
                errorMessage = error.message;
            }
            console.log('Using error.message:', errorMessage);
        }
        
        console.log('Final error display:', {
            errorMessage,
            errorSolution,
            errorCode
        });
    }

    return (
        <Modal
            open={visible}
            onCancel={onClose}
            footer={[
                <Button 
                    key="close" 
                    type="primary" 
                    onClick={onClose}
                    style={{
                        borderRadius: '6px',
                        height: '40px',
                        padding: '0 24px',
                        fontWeight: 500,
                    }}
                >
                    Close
                </Button>
            ]}
            centered
            width={520}
            closable={true}
            maskClosable={true}
            style={{
                top: '20%',
            }}
            styles={{
                body: {
                    padding: '32px',
                },
                header: {
                    borderBottom: 'none',
                    padding: '24px 32px 0',
                },
                footer: {
                    borderTop: '1px solid #f0f0f0',
                    padding: '16px 32px 24px',
                },
            }}
        >
            <Space direction="vertical" size="large" style={{ width: '100%' }}>
                {/* Icon and Title */}
                <Space align="start" size="middle" style={{ width: '100%' }}>
                    <div
                        style={{
                            width: '48px',
                            height: '48px',
                            borderRadius: '50%',
                            backgroundColor: '#fff2f0',
                            display: 'flex',
                            alignItems: 'center',
                            justifyContent: 'center',
                            flexShrink: 0,
                        }}
                    >
                        <ExclamationCircleOutlined
                            style={{
                                fontSize: '24px',
                                color: '#ff4d4f',
                            }}
                        />
                    </div>
                    <div style={{ flex: 1 }}>
                        <Title
                            level={4}
                            style={{
                                margin: 0,
                                marginBottom: '8px',
                                fontSize: '18px',
                                fontWeight: 600,
                                color: '#262626',
                            }}
                        >
                            {title}
                        </Title>
                        <Text
                            type="secondary"
                            style={{
                                fontSize: '13px',
                                color: '#8c8c8c',
                            }}
                        >
                            Error Code: {errorCode || 'N/A'}
                        </Text>
                    </div>
                </Space>

                {/* Error Message */}
                <div
                    style={{
                        backgroundColor: '#fafafa',
                        borderRadius: '8px',
                        padding: '16px',
                        border: '1px solid #f0f0f0',
                    }}
                >
                    <Paragraph
                        style={{
                            margin: 0,
                            fontSize: '14px',
                            lineHeight: '1.6',
                            color: '#595959',
                        }}
                    >
                        {errorMessage}
                    </Paragraph>
                </div>

                {/* Solution */}
                {errorSolution && (
                    <div
                        style={{
                            backgroundColor: '#f6ffed',
                            borderRadius: '8px',
                            padding: '16px',
                            border: '1px solid #b7eb8f',
                        }}
                    >
                        <Space align="start" size="small">
                            <Text
                                strong
                                style={{
                                    fontSize: '13px',
                                    color: '#52c41a',
                                }}
                            >
                                Suggested Solution:
                            </Text>
                            <Text
                                style={{
                                    fontSize: '13px',
                                    color: '#389e0d',
                                }}
                            >
                                {errorSolution}
                            </Text>
                        </Space>
                    </div>
                )}

                {/* Error Details (Collapsible) */}
                {showDetails && errorDetails && (
                    <details
                        style={{
                            marginTop: '8px',
                        }}
                    >
                        <summary
                            style={{
                                cursor: 'pointer',
                                fontSize: '12px',
                                color: '#8c8c8c',
                                userSelect: 'none',
                            }}
                        >
                            Technical Details
                        </summary>
                        <div
                            style={{
                                marginTop: '12px',
                                padding: '12px',
                                backgroundColor: '#fafafa',
                                borderRadius: '6px',
                                fontSize: '12px',
                                fontFamily: 'monospace',
                                color: '#595959',
                                maxHeight: '200px',
                                overflow: 'auto',
                            }}
                        >
                            <pre
                                style={{
                                    margin: 0,
                                    whiteSpace: 'pre-wrap',
                                    wordBreak: 'break-word',
                                }}
                            >
                                {JSON.stringify(errorDetails, null, 2)}
                            </pre>
                        </div>
                    </details>
                )}
            </Space>
        </Modal>
    );
};

export default ErrorModal;
