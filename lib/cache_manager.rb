require 'json'
require 'date'

class CacheManager
  def initialize(storage_provider, bucket)
    @storage_provider = storage_provider
    @bucket = bucket
  end

  # Method 1: Update the JSON DB with a new entry
  def update_json_db(uuid, endpoint)
    json_db = retrieve_json_db || []

    # Check if the UUID already exists in the JSON DB
    existing_entry = json_db.find { |item| item["uuid"] == uuid }
    return if existing_entry

    # Add the new entry
    entry = { "uuid" => uuid, "endpoint" => endpoint, "date" => Date.today.to_s }
    json_db << entry

    upload_json_db(json_db)
  end

  # Method 2: Upload JSON data and update the JSON DB
  def upload_json_data(uuid, endpoint, data, date = Date.today)
    # Check if the endpoint already exists in the JSON DB for the given date
    result = search_json_db(endpoint, date)
    if result
      # Use the UUID from the found result to generate a signed URL
      existing_uuid = result["uuid"]
      return generate_signed_url(existing_uuid)
    end

    # Upload the JSON data file to S3
    path = "cache/#{uuid}"
    @storage_provider.upload_file(data.to_json, @bucket, path)

    # Update the JSON DB with the new entry
    update_json_db(uuid, endpoint)
  end

  # Method 3: Retrieve JSON DB and search by UUID or endpoint, with optional date
  def search_json_db(query, date = Date.today)
    json_db = retrieve_json_db
    return nil unless json_db

    # Find the entry where UUID or endpoint matches the query and date matches
    entry = json_db.find { |item| (item["uuid"] == query || item["endpoint"] == query) && item["date"] == date.to_s }
    entry ? entry : nil
  end

  # Method 4: Generate a signed URL for a UUID-based object valid for a day
  def generate_signed_url(uuid)
    path = "cache/#{uuid}"
    @storage_provider.generate_presigned_url(@bucket, path, ENV["AWS_URL_EXPIRATION"].to_i)
  end

  private

  # Retrieve the JSON DB from S3
  def retrieve_json_db
    json_db_path = "json_db.json"

    # List all files in the bucket
    files = @storage_provider.list_files(@bucket)
    return nil unless files.include?(json_db_path)

    # Retrieve the file content
    data = @storage_provider.get_file(@bucket, json_db_path)

    # Parse the JSON content
    JSON.parse(data)
  rescue StandardError
    nil
  end

  # Upload the updated JSON DB to S3
  def upload_json_db(json_db)
    json_db_path = "json_db.json"
    @storage_provider.upload_file(json_db.to_json, @bucket, json_db_path)
  end
end
