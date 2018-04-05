require 'json'
require 'net/http'

module Fastlane
  module Actions
    class LatestHockeyBuildNumberAction < Action
      def self.run(config)
        host_uri = URI.parse('https://rink.hockeyapp.net')
        http = Net::HTTP.new(host_uri.host, host_uri.port)
        http.use_ssl = true
        list_request = Net::HTTP::Get.new('/api/2/apps')
        list_request['X-HockeyAppToken'] = config[:api_token]
        list_response = http.request(list_request)
        app_list = JSON.parse(list_response.body)['apps']

        app_index = app_list.find_index { |app| app['public_identifier'] == config[:public_identifier] }

        if app_index.nil? then
            UI.error "No application with public identifier #{config[:public_identifier]}"
            return nil
        end

        app_identifier = app_list[app_index]['public_identifier']

        details_request = Net::HTTP::Get.new("/api/2/apps/#{app_identifier}/app_versions?page=1")
        details_request['X-HockeyAppToken'] = config[:api_token]
        details_response = http.request(details_request)

        app_details = JSON.parse(details_response.body)
        latest_build = app_details['app_versions'][0]

        if latest_build.nil? then
            UI.error "The app has no versions yet"
            return nil
        end

        return latest_build['version']
      end

      def self.description
        "Gets latest version number of the app with the bundle id from HockeyApp"
      end

      def self.authors
        ["pahnev", "FlixBus (original author)"]
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(key: :api_token,
                                       env_name: "FL_HOCKEY_API_TOKEN",
                                       description: "API Token for Hockey Access",
                                       verify_block: proc do |value|
                                         UI.user_error!("No API token for Hockey given, pass using `api_token: 'token'`") unless value and !value.empty?
                                       end),
          FastlaneCore::ConfigItem.new(key: :public_identifier,
                                       env_name: "FL_HOCKEY_BUNDLE_ID",
                                       description: "Bundle ID of the application",
                                       verify_block: proc do |value|
                                         UI.user_error!("No bundle ID for Hockey given, pass using `bundle_id: 'bundle id'`") unless value and !value.empty?
                                       end),
        ]
      end

      def self.is_supported?(platform)
        #[:ios].include? platform
				true
      end
    end
  end
end
