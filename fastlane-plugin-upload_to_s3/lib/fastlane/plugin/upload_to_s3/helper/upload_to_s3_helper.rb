module Fastlane
  module Helper
    class UploadToS3Helper
      # class methods that you define here become available in your action
      # as `Helper::UploadToS3Helper.your_method`
      #
      def self.show_message
        UI.message("Hello from the upload_to_s3 plugin helper!")
      end
    end
  end
end
