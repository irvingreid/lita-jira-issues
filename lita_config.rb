Lita.configure do |config|
  # The name your robot will use.
  config.robot.name = "Irving Bot"
  config.robot.mention_name = "irvingbot"

  # The adapter you want to connect with. Make sure you've added the
  # appropriate gem to the Gemfile.
  config.robot.adapter = :hipchat
  config.adapters.hipchat.jid = '7135_1886205@chat.hipchat.com'
  config.adapters.hipchat.password = 'NOT_THIS_PASSWORD'
  config.adapters.hipchat.debug = true
  config.adapters.hipchat.rooms = ["7135_appsnorth@conf.hipchat.com"]

  # Jira issues bot
  config.handlers.jira_issues.url = "https://pagerduty.atlassian.net"
  config.handlers.jira_issues.username = ENV['JIRA_USER'] || 'irving bot'
  config.handlers.jira_issues.password = ENV['JIRA_PASSWORD'] || 'NOT_THIS_PASSWORD'
  config.handlers.jira_issues.format = 'one-line'

  ## Set options for the Redis connection.
  config.redis.host = "127.0.0.1"
  config.redis.port = 6379
end
