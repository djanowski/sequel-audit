require "sequel"
require_relative "sequel/plugins/audit"

class Audit < Sequel::Model
  def self.audit(options = {})
    opts = {}
    opts[:user_id] = options.delete(:user).id

    Thread.current[:audit_options] = opts
    yield
  ensure
    Thread.current[:audit_options] = nil
  end

  def before_create
    self.date = Time.now.utc
    super
  end

  class Change < Sequel::Model(:audit_changes)
    def action
      @action ||= begin
                    entry = entries.detect { |e| e.attribute_name == "id" }

                    if entry
                      if entry.from_value.nil? && !entry.to_value.nil?
                        :create
                      end
                    else
                      :update
                    end
                  end
    end
  end

  class Entry < Sequel::Model(:audit_entries)
  end
end

Audit.one_to_many(:changes, class: Audit::Change)
Audit::Change.one_to_many(:entries, class: Audit::Entry, key: :audit_change_id)
Audit::Entry.many_to_one(:change, class: Audit::Change, key: :audit_change_id)
