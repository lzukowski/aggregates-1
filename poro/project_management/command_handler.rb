module ProjectManagement
  class CommandHandler
    InvalidTransition = Class.new(StandardError)

    def initialize(event_store)
      @event_store = event_store
    end

    def create(cmd)
      with_aggregate(cmd.id) do |issue|
        issue.create
        IssueOpened.new(data: { issue_id: cmd.id })
      end
    end

    def resolve(cmd)
      with_aggregate(cmd.id) do |issue|
        issue.resolve
        IssueResolved.new(data: { issue_id: cmd.id })
      end
    end

    def close(cmd)
      with_aggregate(cmd.id) do |issue|
        issue.close
        IssueClosed.new(data: { issue_id: cmd.id })
      end
    end

    def reopen(cmd)
      with_aggregate(cmd.id) do |issue|
        issue.reopen
        IssueReopened.new(data: { issue_id: cmd.id })
      end
    end

    def start(cmd)
      with_aggregate(cmd.id) do |issue|
        issue.start
        IssueProgressStarted.new(data: { issue_id: cmd.id })
      end
    end

    def stop(cmd)
      with_aggregate(cmd.id) do |issue|
        issue.stop
        IssueProgressStopped.new(data: { issue_id: cmd.id })
      end
    end

    private

    attr_reader :event_store

    def stream_name(id)
      "Issue$#{id}"
    end

    def with_aggregate(id)
      state = IssueProjection.new(event_store).call(stream_name(id))
      event = yield Issue.new(state.status)
      event_store.publish(event, stream_name: stream_name(id), expected_version: state.version)
    end
  end
end
