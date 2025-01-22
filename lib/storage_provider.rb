# storage_provider.rb
class StorageProvider
  def upload_file(file, bucket, object_key)
    raise NotImplementedError, 'This method must be implemented by a subclass'
  end

  def list_files(bucket)
    raise NotImplementedError, 'This method must be implemented by a subclass'
  end

  def delete_file(bucket, object_key)
    raise NotImplementedError, 'This method must be implemented by a subclass'
  end
end
