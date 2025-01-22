require 'aws-sdk-s3'
require 'dotenv/load'
require 'sinatra'
require_relative 'storage_provider'

# S3Client class to interact with AWS S3
class S3Client < StorageProvider
  def initialize
    @s3 = Aws::S3::Client.new(
      region: ENV['AWS_REGION'],
      access_key_id: ENV['AWS_ACCESS_KEY_ID'],
      secret_access_key: ENV['AWS_SECRET_ACCESS_KEY']
    )
  end

  # Method to upload a file to S3
  def upload_file(file, bucket, object_key)
    @s3.put_object(bucket: bucket, key: object_key, body: file)
  end

  # Method to list files in a bucket
  def list_files(bucket)
    @s3.list_objects_v2(bucket: bucket).contents.map(&:key)
  end

  # Method to delete a file from S3
  def delete_file(bucket, object_key)
    @s3.delete_object(bucket: bucket, key: object_key)
  end

  # Method to retrieve a file's content from S3
  def get_file(bucket, object_key)
    response = @s3.get_object(bucket: bucket, key: object_key)
    response.body.read
  rescue Aws::S3::Errors::NoSuchKey
    nil # Return nil if the file does not exist
  rescue StandardError => e
    puts "ERROR: Failed to retrieve file '#{object_key}' from bucket '#{bucket}' - #{e.message}"
    nil
  end

  # Method to generate a presigned URL for a file
  def generate_presigned_url(bucket, object_key, expiration = 3600)
    # Ensure expiration is an integer
    unless expiration.is_a?(Integer) && expiration > 0
      raise ArgumentError, "Expiration must be a positive integer, got #{expiration.inspect}"
    end

    signer = Aws::S3::Presigner.new(client: @s3)
    signer.presigned_url(:get_object, bucket: bucket, key: object_key, expires_in: expiration)
  end
end
