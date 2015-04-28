require "spec_helper"

describe Lita::Handlers::JiraIssues, lita_handler: true do

  before(:each) do
    registry.config.handlers.jira_issues.url = 'http://jira.local'
    registry.config.handlers.jira_issues.username = 'user'
    registry.config.handlers.jira_issues.password = 'pass'
  end

  it { is_expected.to route('JIRA-123').to(:jira_message) }
  it { is_expected.to route('user talking about something JIRA-123 had key').to(:jira_message) }

  def mock_jira(key, result)
    allow_any_instance_of(JiraGateway).to receive(:data_for_issue)
      .with(key)
      .and_return(result)
  end

  # Re-implement lita/rspec/Handler#send_message to support including a room
  def send_room_message(body, room)
    robot.receive(Lita::Message.new(robot, body, Lita::Source.new(user: user, room: room)))
  end

  def mock_jira_424
    mock_jira('KEY-424', {
      key:'KEY-424',
      fields: {
        summary: 'Another issue',
        status: {
          name: 'Fixed'
        },
        assignee: {
          displayName: 'User'
        },
        reporter: {
          displayName: 'Reporter'
        },
        fixVersions: [ { name: 'Sprint 2' } ],
        priority: { name: 'Undecided' }
      }
    })
  end

  describe 'Looking up keys' do
    it 'should reply with JIRA description if one seen' do
      mock_jira_424
      send_message('Some message KEY-424 more text')
      expect(replies.last).to eq(<<-EOS.chomp
[KEY-424] Another issue
Status: Fixed, assigned to User, rep. by Reporter, fixVersion: Sprint 2, priority: Undecided
http://jira.local/browse/KEY-424
                                 EOS
                                )
    end

    it 'it should reply with multiple JIRA descriptions if many seen' do
      mock_multiple_jiras
      send_message('Some PROJ-9872 message nEw-1 more text')
      expect(replies.pop).to eq(<<-EOS.chomp
[NEW-1] New 1
Status: Open, unassigned, rep. by User2, fixVersion: NONE, priority: High
http://jira.local/browse/NEW-1
                                EOS
                               )
      expect(replies.pop).to eq(<<-EOS.chomp
[PROJ-9872] Too many bugs
Status: Resolved, unassigned, rep. by User, fixVersion: NONE
http://jira.local/browse/PROJ-9872
                                EOS
                               )
    end

    it 'it should reply once for each seen JIRA issue' do
      mock_multiple_jiras
      send_message(
        'Some PROJ-9872 message nEw-1 more text with PROJ-9872 mentioned')
      expect(replies.size).to eq(2)
      expect(replies.pop).to include('[NEW-1] New 1')
      expect(replies.pop).to include('[PROJ-9872] Too many bugs')
    end

    it 'should handle ignoring users' do
      registry.config.handlers.jira_issues.ignore = ['Bob Smith']

      mock_jira('KEY-424', {
        key:'KEY-424',
        fields: {
          summary: 'Another issue',
          status: {
            name: 'Fixed'
          },
          assignee: {
            displayName: 'User'
          },
          reporter: {
            displayName: 'Reporter'
          },
          fixVersions: [ { name: 'Sprint 2' } ],
          priority: { name: 'Undecided' }
        }
      })

      bob = Lita::User.create(123, name: "Bob Smith")
      fred = Lita::User.create(123, name: "Fred Smith")

      send_message('Some message KEY-424 more text', as: bob)
      expect(replies.last).not_to match('KEY-424')
      send_message('Some message KEY-424 more text', as: fred)
      expect(replies.last).to match('KEY-424')
    end

    def mock_multiple_jiras
      mock_jira('PROJ-9872',
                {key:'PROJ-9872',
                 fields: {
                  summary: 'Too many bugs',
                  status: {
                    name: 'Resolved'
                  },
                  assignee: nil,
                  reporter: {
                    displayName: 'User'
                  }
                }})
      mock_jira('nEw-1',
                {key:'NEW-1',
                 fields: {
                  summary: 'New 1',
                  status: {
                    name: 'Open'
                  },
                  reporter: {
                    displayName: 'User2'
                  },
                  fixVersions: [],
                  priority: { name: 'High' }
                }})
    end

  end

  describe 'with a room list set' do
    it 'should respond to the configured room' do
      @test_room = '1234_567@chat.hipchat.com'
      registry.config.handlers.jira_issues.rooms = [@test_room]
      mock_jira_424
      send_room_message('Some message KEY-424 more', @test_room)
      expect(replies.size).to eq(1)
    end
  end

  describe 'set to one-line format' do
    before(:each) do
      registry.config.handlers.jira_issues.format = 'one-line'
    end

    it 'should display compact version' do
      mock_jira_424
      send_message('Some message KEY-424 more text')
      expect(replies.last).to eq("http://jira.local/browse/KEY-424 - Fixed, User - Another issue")
    end
  end
end
