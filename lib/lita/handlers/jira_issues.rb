require_relative 'jira_gateway'
require 'set'

module Lita
  module Handlers
    class JiraIssues < Handler

      config :url, required: true, type: String
      config :username, required: true, type: String
      config :password, required: true, type: String
      config :ignore, default: [], type: Array
      config :format, required: false, type: String, default: 'verbose'

      route /[a-zA-Z]+-\d+/, :jira_message, help: {
        "KEY-123" => "Replies with information about the given JIRA key"
      }

      def jira_message(response)
        return if config.ignore.include?(response.user.name)
        @jira ||= JiraGateway.new(http, config)
        Set.new(response.matches).each do | key |
          handle_key(response, key)
        end
      end

      def handle_key(response, key)
        data = @jira.data_for_issue(key)
        Lita.logger.debug "Jira key #{key} data: #{data}"
        return if data.empty?
        response.reply(config.format == 'one-line' ?  oneline_details(data) : issue_details(data))
      end

      def oneline_details(data)
        fields = data[:fields]
        assigned_to = fields[:assignee]
        issue = "#{issue_link(data[:key])} - #{fields[:status][:name]}, #{assigned_to ? assigned_to[:displayName] : 'unassigned'} - #{fields[:summary]}"
      end

      def issue_details(data)
        key = data[:key]
        fields = data[:fields]
        issue = summary(key, fields)
        issue << status(fields)
        issue << assignee(fields)
        issue << reporter(fields)
        issue << fix_version(fields)
        issue << priority(fields)
        issue << "\n" << issue_link(key)
      end

      def summary(key, data)
        "[#{key}] #{data[:summary]}"
      end

      def status(data)
        "\nStatus: #{data[:status][:name]}"
      end

      def assignee(data)
        if assigned_to = data[:assignee]
          return ", assigned to #{assigned_to[:displayName]}"
        end
        ', unassigned'
      end

      def reporter(data)
        ", rep. by #{data[:reporter][:displayName]}"
      end

      def fix_version(data)
        fix_versions = data[:fixVersions]
        if fix_versions and fix_versions.first
          ", fixVersion: #{fix_versions.first[:name]}"
        else
          ', fixVersion: NONE'
        end
      end

      def priority(data)
        if data[:priority]
          ", priority: #{data[:priority][:name]}"
        else
          ""
        end
      end

      def issue_link(key)
        "#{config.url}/browse/#{key}"
      end
    end

    Lita.register_handler(JiraIssues)
  end
end
