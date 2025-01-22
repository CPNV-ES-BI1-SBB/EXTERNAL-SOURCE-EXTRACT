require 'json'
require 'date'

class CacheManager
  def initialize(storage_provider, bucket)
    @storage_provider = storage_provider
    @bucket = bucket
  end

  # Method 1: Upload JSON data and update the JSON DB
  def upload_json_data(uuid, endpoint, data)
    # Upload the JSON data file to S3
    path = "cache/#{uuid}.json"
    @storage_provider.upload_file(data.to_json, @bucket, path)

    # Update the JSON DB with the new entry
    update_json_db(uuid, endpoint)
  end

  # Method 2: Retrieve, update the JSON DB with new data, and upload it back to S3
  def update_json_db(uuid, endpoint)
    json_db = retrieve_json_db(Date.today) || []
    entry = { "uuid" => uuid, "endpoint" => endpoint, "date" => Date.today.to_s }
    json_db << entry
    upload_json_db(json_db, Date.today)
  end

  # Method 3: Retrieve JSON DB and search by UUID or endpoint, with optional date
  def search_json_db(query, date = Date.today)
    json_db = retrieve_json_db(date)
    return nil unless json_db

    # Find the entry where UUID or endpoint matches the query
    entry = json_db.find { |item| item["uuid"] == query || item["endpoint"] == query }
    entry ? entry.slice("endpoint", "date") : nil
  end

  # Method 4: Generate a signed URL for a UUID-based object valid for a day
  def generate_signed_url(uuid)
    path = "cache/#{uuid}.json"
    @storage_provider.generate_presigned_url(@bucket, path, 86_400) # 1 day = 86,400 seconds
  end

  private

  # Retrieve the JSON DB from S3 for a specific date
  def retrieve_json_db(date)
    json_db_path = "json_db/#{date}.json"
    files = @storage_provider.list_files(@bucket)
    return nil unless files.include?(json_db_path)

    data = @storage_provider.get_file(@bucket, json_db_path)
    JSON.parse(data)
  rescue StandardError
    nil
  end

  # Upload the updated JSON DB to S3 for a specific date
  def upload_json_db(json_db, date)
    json_db_path = "json_db/#{date}.json"
    @storage_provider.upload_file(json_db.to_json, @bucket, json_db_path)
  end
end
