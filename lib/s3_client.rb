require 'aws-sdk-s3'
require 'dotenv/load'
require 'sinatra'
require_relative 'storage_provider'

# Chargement des variables d'environnement
class S3Client < StorageProvider
  def initialize
    @s3 = Aws::S3::Client.new(
      region: ENV['AWS_REGION'],
      access_key_id: ENV['AWS_ACCESS_KEY_ID'],
      secret_access_key: ENV['AWS_SECRET_ACCESS_KEY']
    )
  end

  # Méthode pour uploader un fichier
  def upload_file(file, bucket, object_key)
    @s3.put_object(bucket: bucket, key: object_key, body: file)
  end

  # Méthode pour lister les fichiers dans un bucket
  def list_files(bucket)
    @s3.list_objects_v2(bucket: bucket).contents.map(&:key)
  end

  def delete_file(bucket, object_key)
    @s3.delete_object(bucket: bucket, key: object_key)
  end
end
