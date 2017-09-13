module Fastlane
  module Actions
    class UploadToS3Action < Action
      def self.run(params)
        UI.message("Region: #{params[:region]}")
        UI.message("Key: #{params[:key]}")
        UI.message("File: #{params[:file]}")
        UI.message("ACL: #{params[:acl]}")

        s3_region = params[:region]
        s3_subdomain = params[:region] ? "s3-#{params[:region]}" : "s3"
        s3_access_key = params[:access_key]
        s3_secret_access_key = params[:secret_access_key]
        s3_bucket = params[:bucket]
        s3_key = params[:key]
        s3_body = params[:file]
        s3_acl = params[:acl]

        require 'aws-sdk'

        if s3_region
          s3_client = Aws::S3::Client.new(
            access_key_id: s3_access_key,
            secret_access_key: s3_secret_access_key,
            region: s3_region
          )
        else
          s3_client = Aws::S3::Client.new(
            access_key_id: s3_access_key,
            secret_access_key: s3_secret_access_key
          )
        end

        File.open(s3_body, 'r') do |file|

          response = s3_client.put_object(
            acl: s3_acl,
            bucket: s3_bucket,
            key: s3_key,
            body: file
          )
        end
      end

      def self.description
        "Upload zip file to s3"
      end

      def self.authors
        ["ulhas", "ulhas_sm"]
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(key: :region,
                                       env_name: "",
                                       description: "Region for S3",
                                       is_string: true, # true: verifies the input is a string, false: every kind of value
                                       optional: true), # the default value if the user didn't provide one
          FastlaneCore::ConfigItem.new(key: :access_key,
                                       env_name: "S3_ACCESS_KEY", # The name of the environment variable
                                       description: "Access Key for S3", # a short description of this parameter
                                       verify_block: proc do |value|
                                          raise "No Access key for UploadToS3Action given, pass using `access_key: 'access_key'`".red unless (value and not value.empty?)
                                       end,
                                       is_string: true),
          FastlaneCore::ConfigItem.new(key: :secret_access_key,
                                       env_name: "S3_SECRET_ACCESS_KEY", # The name of the environment variable
                                       description: "Secret Access for S3", # a short description of this parameter
                                       verify_block: proc do |value|
                                          raise "No Secret Access for UploadToS3Action given, pass using `secret_access_key: 'secret_access_key'`".red unless (value and not value.empty?)
                                       end,
                                       is_string: true),
          FastlaneCore::ConfigItem.new(key: :bucket,
                                       env_name: "S3_BUCKET", # The name of the environment variable
                                       description: "Bucket for S3", # a short description of this parameter
                                       verify_block: proc do |value|
                                          raise "No Bucket for UploadToS3Action given, pass using `bucket: 'bucket'`".red unless (value and not value.empty?)
                                       end,
                                       is_string: true),
          FastlaneCore::ConfigItem.new(key: :key,
                                       env_name: "",
                                       description: "Key to s3 bucket",
                                       is_string: false, # true: verifies the input is a string, false: every kind of value
                                       default_value: false), # the default value if the user didn't provide one
          FastlaneCore::ConfigItem.new(key: :acl,
                                       env_name: "",
                                       description: "Access level for the file",
                                       is_string: true, # true: verifies the input is a string, false: every kind of value
                                       default_value: "private"),
          FastlaneCore::ConfigItem.new(key: :file,
                                       env_name: "", # The name of the environment variable
                                       description: "File to be uploaded for S3", # a short description of this parameter
                                       verify_block: proc do |value|
                                          raise "Couldn't find file at path '#{value}'".red unless File.exist?(value)
                                       end)
        ]
      end

      def self.is_supported?(platform)
        platform == :ios
      end
    end
  end
end
