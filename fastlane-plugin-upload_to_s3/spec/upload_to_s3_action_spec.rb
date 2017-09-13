describe Fastlane::Actions::UploadToS3Action do
  describe '#run' do
    it 'prints a message' do
      expect(Fastlane::UI).to receive(:message).with("The upload_to_s3 plugin is working!")

      Fastlane::Actions::UploadToS3Action.run(nil)
    end
  end
end
