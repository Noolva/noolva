-- 98_seed_integration_providers.sql
-- Classification: Seed Data
-- Description: Standard Integration Providers (SES, SMS, S3, CCAvenue) with required field configurations.

-- Get field_type_id for common field types
DO $$
DECLARE
    ft_text INT;
    ft_email INT;
    ft_url INT;
    ft_number INT;
    ft_boolean INT;
BEGIN
    SELECT field_type_id INTO ft_text FROM public.field_types WHERE type_code = 'text';
    SELECT field_type_id INTO ft_email FROM public.field_types WHERE type_code = 'email';
    SELECT field_type_id INTO ft_url FROM public.field_types WHERE type_code = 'url';
    SELECT field_type_id INTO ft_number FROM public.field_types WHERE type_code = 'number';
    SELECT field_type_id INTO ft_boolean FROM public.field_types WHERE type_code = 'boolean';

    -- 1. AWS SES (Simple Email Service)
    INSERT INTO public.integration_providers (
        provider_name, provider_display_name, provider_category, description,
        required_fields_json, optional_fields_json, metadata_json, is_builtin
    ) VALUES (
        'aws_ses',
        'AWS SES',
        'email',
        'Amazon Simple Email Service for sending transactional and marketing emails',
        jsonb_build_array(
            jsonb_build_object(
                'field_name', 'aws_access_key_id',
                'field_type_id', ft_text,
                'is_required', true,
                'display_name', 'AWS Access Key ID',
                'is_secret', false,
                'description', 'Your AWS access key ID'
            ),
            jsonb_build_object(
                'field_name', 'aws_secret_access_key',
                'field_type_id', ft_text,
                'is_required', true,
                'display_name', 'AWS Secret Access Key',
                'is_secret', true,
                'description', 'Your AWS secret access key'
            ),
            jsonb_build_object(
                'field_name', 'aws_region',
                'field_type_id', ft_text,
                'is_required', true,
                'display_name', 'AWS Region',
                'is_secret', false,
                'description', 'AWS region (e.g., us-east-1, ap-south-1)',
                'default_value', 'us-east-1'
            )
        ),
        jsonb_build_array(
            jsonb_build_object(
                'field_name', 'from_email',
                'field_type_id', ft_email,
                'is_required', false,
                'display_name', 'Default From Email',
                'description', 'Default sender email address'
            ),
            jsonb_build_object(
                'field_name', 'from_name',
                'field_type_id', ft_text,
                'is_required', false,
                'display_name', 'Default From Name',
                'description', 'Default sender name'
            )
        ),
        jsonb_build_object('service_url', 'https://aws.amazon.com/ses/', 'api_docs', 'https://docs.aws.amazon.com/ses/'),
        true
    ) ON CONFLICT (provider_name) DO NOTHING;

    -- 2. AWS S3 (Simple Storage Service)
    INSERT INTO public.integration_providers (
        provider_name, provider_display_name, provider_category, description,
        required_fields_json, optional_fields_json, metadata_json, is_builtin
    ) VALUES (
        'aws_s3',
        'AWS S3',
        'storage',
        'Amazon Simple Storage Service for file and asset storage',
        jsonb_build_array(
            jsonb_build_object(
                'field_name', 'aws_access_key_id',
                'field_type_id', ft_text,
                'is_required', true,
                'display_name', 'AWS Access Key ID',
                'is_secret', false,
                'description', 'Your AWS access key ID'
            ),
            jsonb_build_object(
                'field_name', 'aws_secret_access_key',
                'field_type_id', ft_text,
                'is_required', true,
                'display_name', 'AWS Secret Access Key',
                'is_secret', true,
                'description', 'Your AWS secret access key'
            ),
            jsonb_build_object(
                'field_name', 'bucket_name',
                'field_type_id', ft_text,
                'is_required', true,
                'display_name', 'S3 Bucket Name',
                'is_secret', false,
                'description', 'Name of the S3 bucket'
            ),
            jsonb_build_object(
                'field_name', 'aws_region',
                'field_type_id', ft_text,
                'is_required', true,
                'display_name', 'AWS Region',
                'is_secret', false,
                'description', 'AWS region (e.g., us-east-1, ap-south-1)',
                'default_value', 'us-east-1'
            )
        ),
        jsonb_build_array(
            jsonb_build_object(
                'field_name', 'endpoint_url',
                'field_type_id', ft_url,
                'is_required', false,
                'display_name', 'Custom Endpoint URL',
                'description', 'Custom S3 endpoint (for S3-compatible services)'
            ),
            jsonb_build_object(
                'field_name', 'cdn_url',
                'field_type_id', ft_url,
                'is_required', false,
                'display_name', 'CDN URL',
                'description', 'CDN URL for public asset access'
            )
        ),
        jsonb_build_object('service_url', 'https://aws.amazon.com/s3/', 'api_docs', 'https://docs.aws.amazon.com/s3/'),
        true
    ) ON CONFLICT (provider_name) DO NOTHING;

    -- 3. AWS SMS / SNS (Simple Notification Service)
    INSERT INTO public.integration_providers (
        provider_name, provider_display_name, provider_category, description,
        required_fields_json, optional_fields_json, metadata_json, is_builtin
    ) VALUES (
        'aws_sms',
        'AWS SMS (SNS)',
        'sms',
        'Amazon Simple Notification Service for sending SMS messages',
        jsonb_build_array(
            jsonb_build_object(
                'field_name', 'aws_access_key_id',
                'field_type_id', ft_text,
                'is_required', true,
                'display_name', 'AWS Access Key ID',
                'is_secret', false,
                'description', 'Your AWS access key ID'
            ),
            jsonb_build_object(
                'field_name', 'aws_secret_access_key',
                'field_type_id', ft_text,
                'is_required', true,
                'display_name', 'AWS Secret Access Key',
                'is_secret', true,
                'description', 'Your AWS secret access key'
            ),
            jsonb_build_object(
                'field_name', 'aws_region',
                'field_type_id', ft_text,
                'is_required', true,
                'display_name', 'AWS Region',
                'is_secret', false,
                'description', 'AWS region (e.g., us-east-1, ap-south-1)',
                'default_value', 'us-east-1'
            )
        ),
        jsonb_build_array(
            jsonb_build_object(
                'field_name', 'sender_id',
                'field_type_id', ft_text,
                'is_required', false,
                'display_name', 'Sender ID',
                'description', 'Default SMS sender ID'
            )
        ),
        jsonb_build_object('service_url', 'https://aws.amazon.com/sns/', 'api_docs', 'https://docs.aws.amazon.com/sns/'),
        true
    ) ON CONFLICT (provider_name) DO NOTHING;

    -- 4. CCAvenue Payment Gateway
    INSERT INTO public.integration_providers (
        provider_name, provider_display_name, provider_category, description,
        required_fields_json, optional_fields_json, metadata_json, is_builtin
    ) VALUES (
        'ccavenue',
        'CCAvenue',
        'payment',
        'CCAvenue payment gateway for processing online payments',
        jsonb_build_array(
            jsonb_build_object(
                'field_name', 'merchant_id',
                'field_type_id', ft_text,
                'is_required', true,
                'display_name', 'Merchant ID',
                'is_secret', false,
                'description', 'Your CCAvenue merchant ID'
            ),
            jsonb_build_object(
                'field_name', 'access_code',
                'field_type_id', ft_text,
                'is_required', true,
                'display_name', 'Access Code',
                'is_secret', true,
                'description', 'Your CCAvenue access code'
            ),
            jsonb_build_object(
                'field_name', 'working_key',
                'field_type_id', ft_text,
                'is_required', true,
                'display_name', 'Working Key',
                'is_secret', true,
                'description', 'Your CCAvenue working key (encryption key)'
            )
        ),
        jsonb_build_array(
            jsonb_build_object(
                'field_name', 'environment',
                'field_type_id', ft_text,
                'is_required', false,
                'display_name', 'Environment',
                'description', 'Payment environment: test or production',
                'default_value', 'test',
                'options', jsonb_build_array('test', 'production')
            ),
            jsonb_build_object(
                'field_name', 'currency',
                'field_type_id', ft_text,
                'is_required', false,
                'display_name', 'Default Currency',
                'description', 'Default currency code (e.g., INR, USD)',
                'default_value', 'INR'
            )
        ),
        jsonb_build_object('service_url', 'https://www.ccavenue.com/', 'api_docs', 'https://www.ccavenue.com/supportcenter/knowledgebase'),
        true
    ) ON CONFLICT (provider_name) DO NOTHING;

END $$;
