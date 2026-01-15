"""
S3 Service for Asset Management
Handles upload, list, download, and stream operations for S3 storage
Supports both public and private assets
"""
import boto3
from botocore.exceptions import ClientError, BotoCoreError
from typing import Optional, Dict, List, BinaryIO, Tuple, Any
import os
from urllib.parse import urljoin
import logging

logger = logging.getLogger(__name__)


class S3Service:
    """Service for managing S3 operations"""
    
    def __init__(
        self,
        access_key_id: str,
        secret_access_key: str,
        bucket_name: str,
        region: str = 'us-east-1',
        endpoint_url: Optional[str] = None,
        cdn_url: Optional[str] = None,
        bucket_prefix: Optional[str] = None
    ):
        """
        Initialize S3 service
        
        Args:
            access_key_id: AWS access key ID
            secret_access_key: AWS secret access key
            bucket_name: S3 bucket name
            region: AWS region
            endpoint_url: Custom endpoint URL (for S3-compatible services)
            cdn_url: CDN URL for public asset access
            bucket_prefix: Optional prefix/folder path in bucket (e.g., "production", "staging")
        """
        self.access_key_id = access_key_id
        self.secret_access_key = secret_access_key
        self.bucket_name = bucket_name
        self.region = region
        self.endpoint_url = endpoint_url
        self.cdn_url = cdn_url
        # Normalize bucket_prefix: remove leading/trailing slashes, ensure it ends with / if not empty
        if bucket_prefix:
            bucket_prefix = bucket_prefix.strip('/')
            self.bucket_prefix = bucket_prefix + '/' if bucket_prefix else None
        else:
            self.bucket_prefix = None
        
        # Initialize S3 client
        s3_config = {
            'aws_access_key_id': access_key_id,
            'aws_secret_access_key': secret_access_key,
            'region_name': region
        }
        
        # Only set endpoint_url for S3-compatible services (not for regular AWS S3)
        # endpoint_url should be like: https://s3.amazonaws.com or https://nyc3.digitaloceanspaces.com
        # NOT a bucket URL like: https://bucket-name.s3.region.amazonaws.com
        if endpoint_url:
            # Validate endpoint_url format
            if 's3.' in endpoint_url and '.amazonaws.com' in endpoint_url:
                # This looks like a bucket URL, not an endpoint URL
                # For AWS S3, we should NOT use endpoint_url
                logger.warning(
                    f"endpoint_url '{endpoint_url}' looks like a bucket URL. "
                    "For AWS S3, endpoint_url should be empty. Using default AWS endpoint."
                )
            else:
                # This is likely a custom S3-compatible service endpoint
                s3_config['endpoint_url'] = endpoint_url
        
        self.s3_client = boto3.client('s3', **s3_config)
        self.s3_resource = boto3.resource('s3', **s3_config)
        self.bucket = self.s3_resource.Bucket(bucket_name)
    
    def test_connection(self) -> Dict[str, Any]:
        """
        Test S3 connection and bucket access
        
        Returns:
            Dict with success status and message
        """
        try:
            # First, try to get bucket location to verify credentials and bucket exist
            try:
                location = self.s3_client.get_bucket_location(Bucket=self.bucket_name)
                bucket_region = location.get('LocationConstraint')
                
                # If bucket is in us-east-1, LocationConstraint will be None or empty
                if not bucket_region:
                    bucket_region = 'us-east-1'
                
                # Verify region matches (if specified)
                if self.region and bucket_region and bucket_region != self.region:
                    return {
                        'success': False,
                        'message': f'Region mismatch: Bucket is in {bucket_region}, but you specified {self.region}',
                        'bucket_region': bucket_region,
                        'specified_region': self.region,
                        'error': 'Region mismatch'
                    }
                
                # Try to list objects (more reliable than head_bucket)
                response = self.s3_client.list_objects_v2(
                    Bucket=self.bucket_name,
                    MaxKeys=1
                )
                
                return {
                    'success': True,
                    'message': 'S3 connection successful',
                    'bucket': self.bucket_name,
                    'region': bucket_region or self.region,
                    'endpoint_url': self.endpoint_url
                }
            except ClientError as e:
                error_code = e.response.get('Error', {}).get('Code', 'Unknown')
                error_message = e.response.get('Error', {}).get('Message', str(e))
                
                # Provide helpful error messages
                if error_code == '404':
                    return {
                        'success': False,
                        'message': f'Bucket "{self.bucket_name}" not found. Please check: 1) Bucket name is correct, 2) Bucket exists in region {self.region}, 3) Your credentials have access to this bucket',
                        'error_code': error_code,
                        'error': error_message,
                        'suggestions': [
                            'Verify the bucket name is correct',
                            f'Check if bucket exists in region: {self.region}',
                            'Verify your AWS credentials have permission to access this bucket',
                            'If using a custom endpoint, ensure it\'s correct (should be empty for AWS S3)'
                        ]
                    }
                elif error_code == '403':
                    return {
                        'success': False,
                        'message': f'Access denied to bucket "{self.bucket_name}". Check your AWS credentials and IAM permissions.',
                        'error_code': error_code,
                        'error': error_message
                    }
                elif error_code == 'InvalidAccessKeyId':
                    return {
                        'success': False,
                        'message': 'Invalid AWS Access Key ID. Please check your credentials.',
                        'error_code': error_code,
                        'error': error_message
                    }
                elif error_code == 'SignatureDoesNotMatch':
                    return {
                        'success': False,
                        'message': 'Invalid AWS Secret Access Key. Please check your credentials.',
                        'error_code': error_code,
                        'error': error_message
                    }
                else:
                    return {
                        'success': False,
                        'message': f'S3 connection failed: {error_code}',
                        'error_code': error_code,
                        'error': error_message
                    }
        except Exception as e:
            return {
                'success': False,
                'message': f'S3 connection failed: {str(e)}',
                'error': str(e),
                'error_type': type(e).__name__
            }
    
    def _build_s3_key(self, key: str) -> str:
        """
        Build S3 key with bucket prefix if configured
        
        Args:
            key: Base S3 key
            
        Returns:
            Full S3 key with prefix if configured
        """
        if self.bucket_prefix:
            # Remove leading slash from key if present
            key = key.lstrip('/')
            return f"{self.bucket_prefix}{key}"
        return key.lstrip('/')
    
    def upload_file(
        self,
        file_path: str,
        s3_key: str,
        is_public: bool = False,
        content_type: Optional[str] = None,
        metadata: Optional[Dict[str, str]] = None
    ) -> Dict[str, Any]:
        """
        Upload a file to S3
        
        Args:
            file_path: Local file path to upload
            s3_key: S3 object key (path in bucket, will be prefixed if bucket_prefix is set)
            is_public: Whether the file should be publicly accessible
            content_type: MIME type of the file
            metadata: Additional metadata to store with the file
            
        Returns:
            Dict with upload result including public_url if public
        """
        try:
            # Apply bucket prefix to S3 key
            full_s3_key = self._build_s3_key(s3_key)
            extra_args = {}
            
            if content_type:
                extra_args['ContentType'] = content_type
            
            if metadata:
                extra_args['Metadata'] = metadata
            
            # Note: ACLs are disabled on many modern S3 buckets (default for new buckets)
            # DO NOT set ACL - use bucket policies for public access instead
            # Setting ACL will cause AccessControlListNotSupported error
            # For public access, configure bucket policy: s3:GetObject for public principal
            
            # Upload file WITHOUT ACL
            self.s3_client.upload_file(
                file_path,
                self.bucket_name,
                full_s3_key,
                ExtraArgs=extra_args if extra_args else None
            )
            
            # Generate public URL
            if is_public:
                if self.cdn_url:
                    public_url = urljoin(self.cdn_url.rstrip('/') + '/', full_s3_key)
                else:
                    # For public access, use direct URL (bucket policy must allow public read)
                    if self.endpoint_url:
                        public_url = urljoin(self.endpoint_url.rstrip('/') + '/', f"{self.bucket_name}/{full_s3_key}")
                    else:
                        public_url = f"https://{self.bucket_name}.s3.{self.region}.amazonaws.com/{full_s3_key}"
            else:
                public_url = None
            
            return {
                'success': True,
                'message': 'File uploaded successfully',
                's3_key': full_s3_key,
                'original_key': s3_key,
                'bucket': self.bucket_name,
                'public_url': public_url,
                'is_public': is_public,
                'acl_warning': is_public  # Warn that bucket policy is needed for public access
            }
        except ClientError as e:
            logger.error(f"S3 upload failed: {str(e)}")
            return {
                'success': False,
                'message': f'Upload failed: {str(e)}',
                'error': str(e)
            }
        except Exception as e:
            logger.error(f"S3 upload error: {str(e)}")
            return {
                'success': False,
                'message': f'Upload error: {str(e)}',
                'error': str(e)
            }
    
    def upload_fileobj(
        self,
        file_obj: BinaryIO,
        s3_key: str,
        is_public: bool = False,
        content_type: Optional[str] = None,
        metadata: Optional[Dict[str, str]] = None
    ) -> Dict[str, Any]:
        """
        Upload a file-like object to S3
        
        Args:
            file_obj: File-like object to upload
            s3_key: S3 object key (path in bucket, will be prefixed if bucket_prefix is set)
            is_public: Whether the file should be publicly accessible
            content_type: MIME type of the file
            metadata: Additional metadata to store with the file
            
        Returns:
            Dict with upload result
        """
        try:
            # Apply bucket prefix to S3 key
            full_s3_key = self._build_s3_key(s3_key)
            extra_args = {}
            
            if content_type:
                extra_args['ContentType'] = content_type
            
            if metadata:
                extra_args['Metadata'] = metadata
            
            # Note: ACLs are disabled on many modern S3 buckets (default for new buckets)
            # DO NOT set ACL - use bucket policies for public access instead
            # Setting ACL will cause AccessControlListNotSupported error
            # For public access, configure bucket policy: s3:GetObject for public principal
            
            # Upload file object WITHOUT ACL
            self.s3_client.upload_fileobj(
                file_obj,
                self.bucket_name,
                full_s3_key,
                ExtraArgs=extra_args if extra_args else None
            )
            
            # Generate public URL if public
            if is_public:
                if self.cdn_url:
                    public_url = urljoin(self.cdn_url.rstrip('/') + '/', full_s3_key)
                elif self.endpoint_url:
                    public_url = urljoin(self.endpoint_url.rstrip('/') + '/', f"{self.bucket_name}/{full_s3_key}")
                else:
                    public_url = f"https://{self.bucket_name}.s3.{self.region}.amazonaws.com/{full_s3_key}"
            else:
                public_url = None
            
            return {
                'success': True,
                'message': 'File uploaded successfully',
                's3_key': full_s3_key,
                'original_key': s3_key,
                'bucket': self.bucket_name,
                'public_url': public_url,
                'is_public': is_public,
                'acl_warning': is_public  # Warn that bucket policy is needed for public access
            }
        except Exception as e:
            logger.error(f"S3 upload error: {str(e)}")
            return {
                'success': False,
                'message': f'Upload error: {str(e)}',
                'error': str(e)
            }
    
    def list_files(
        self,
        prefix: str = '',
        max_keys: int = 1000
    ) -> List[Dict[str, Any]]:
        """
        List files in S3 bucket
        
        Args:
            prefix: Prefix to filter files (folder path, will be prefixed if bucket_prefix is set)
            max_keys: Maximum number of keys to return
            
        Returns:
            List of file dictionaries with key, size, last_modified, etc.
        """
        try:
            # Apply bucket prefix to search prefix
            full_prefix = self._build_s3_key(prefix)
            response = self.s3_client.list_objects_v2(
                Bucket=self.bucket_name,
                Prefix=full_prefix,
                MaxKeys=max_keys
            )
            
            files = []
            if 'Contents' in response:
                for obj in response['Contents']:
                    files.append({
                        'key': obj['Key'],
                        'size': obj['Size'],
                        'last_modified': obj['LastModified'].isoformat(),
                        'etag': obj['ETag'].strip('"')
                    })
            
            return files
        except Exception as e:
            logger.error(f"S3 list error: {str(e)}")
            return []
    
    def download_file(
        self,
        s3_key: str,
        local_path: str
    ) -> Dict[str, Any]:
        """
        Download a file from S3 to local path
        
        Args:
            s3_key: S3 object key (will be prefixed if bucket_prefix is set)
            local_path: Local file path to save to
            
        Returns:
            Dict with download result
        """
        try:
            # Ensure directory exists
            os.makedirs(os.path.dirname(local_path), exist_ok=True)
            
            # Apply bucket prefix to S3 key
            full_s3_key = self._build_s3_key(s3_key)
            
            self.s3_client.download_file(
                self.bucket_name,
                full_s3_key,
                local_path
            )
            
            return {
                'success': True,
                'message': 'File downloaded successfully',
                'local_path': local_path,
                's3_key': full_s3_key,
                'original_key': s3_key
            }
        except ClientError as e:
            logger.error(f"S3 download failed: {str(e)}")
            return {
                'success': False,
                'message': f'Download failed: {str(e)}',
                'error': str(e)
            }
        except Exception as e:
            logger.error(f"S3 download error: {str(e)}")
            return {
                'success': False,
                'message': f'Download error: {str(e)}',
                'error': str(e)
            }
    
    def get_file_stream(
        self,
        s3_key: str
    ) -> Tuple[Optional[BinaryIO], Dict[str, Any]]:
        """
        Get a file stream from S3
        
        Args:
            s3_key: S3 object key (will be prefixed if bucket_prefix is set)
            
        Returns:
            Tuple of (file_stream, metadata_dict)
        """
        try:
            # Apply bucket prefix to S3 key
            full_s3_key = self._build_s3_key(s3_key)
            
            obj = self.s3_client.get_object(
                Bucket=self.bucket_name,
                Key=full_s3_key
            )
            
            metadata = {
                'content_type': obj.get('ContentType'),
                'content_length': obj.get('ContentLength'),
                'last_modified': obj.get('LastModified').isoformat() if obj.get('LastModified') else None,
                'metadata': obj.get('Metadata', {})
            }
            
            return obj['Body'], metadata
        except ClientError as e:
            logger.error(f"S3 stream error: {str(e)}")
            return None, {
                'error': str(e),
                'success': False
            }
        except Exception as e:
            logger.error(f"S3 stream error: {str(e)}")
            return None, {
                'error': str(e),
                'success': False
            }
    
    def generate_presigned_url(
        self,
        s3_key: str,
        expiration: int = 3600
    ) -> Optional[str]:
        """
        Generate a presigned URL for private file access
        
        Args:
            s3_key: S3 object key (will be prefixed if bucket_prefix is set)
            expiration: URL expiration time in seconds (default 1 hour)
            
        Returns:
            Presigned URL or None if failed
        """
        try:
            # Apply bucket prefix to S3 key
            full_s3_key = self._build_s3_key(s3_key)
            
            url = self.s3_client.generate_presigned_url(
                'get_object',
                Params={'Bucket': self.bucket_name, 'Key': full_s3_key},
                ExpiresIn=expiration
            )
            return url
        except Exception as e:
            logger.error(f"Presigned URL generation error: {str(e)}")
            return None
    
    def delete_file(self, s3_key: str) -> Dict[str, Any]:
        """
        Delete a file from S3
        
        Args:
            s3_key: S3 object key (will be prefixed if bucket_prefix is set)
            
        Returns:
            Dict with delete result
        """
        try:
            # Apply bucket prefix to S3 key
            full_s3_key = self._build_s3_key(s3_key)
            
            self.s3_client.delete_object(
                Bucket=self.bucket_name,
                Key=full_s3_key
            )
            return {
                'success': True,
                'message': 'File deleted successfully',
                's3_key': full_s3_key,
                'original_key': s3_key
            }
        except Exception as e:
            logger.error(f"S3 delete error: {str(e)}")
            return {
                'success': False,
                'message': f'Delete error: {str(e)}',
                'error': str(e)
            }
    
    @staticmethod
    def from_integration_config(config: Dict[str, Any]) -> 'S3Service':
        """
        Create S3Service instance from integration config
        
        Args:
            config: Integration config dictionary with credentials
            
        Returns:
            S3Service instance
        """
        return S3Service(
            access_key_id=config.get('aws_access_key_id'),
            secret_access_key=config.get('aws_secret_access_key'),
            bucket_name=config.get('bucket_name'),
            region=config.get('aws_region', 'us-east-1'),
            endpoint_url=config.get('endpoint_url'),
            cdn_url=config.get('cdn_url'),
            bucket_prefix=config.get('bucket_prefix')
        )
