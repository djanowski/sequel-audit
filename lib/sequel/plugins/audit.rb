module Sequel::Plugins::Audit
  def self.create
    created = false

    audit = (Thread.current[:audit_model] ||= (created = true; ::Audit.create(Thread.current[:audit_options])))

    yield(audit)
  ensure
    Thread.current[:audit_model] = nil if created
  end

  def self.configure(model, opts = {})
    model.instance_eval do
      @audit_ignored_columns = opts.fetch(:ignore, [])
    end
  end

  module ClassMethods
    attr :audit_columns

    def inherited(subclass)
      super

      [:@audit_ignored_columns].each do |iv|
        subclass.instance_variable_set(iv, instance_variable_get(iv).dup)
      end
    end

    def audit_columns
      @audit_columns ||= columns - @audit_ignored_columns
    end
  end

  module InstanceMethods
    def around_save
      return super unless Thread.current[:audit_options]
      return super if ::Audit === self || ::Audit::Change === self || ::Audit::Entry === self

      if new?
        cols = values.keys.select { |k| values[k] } + [:id]
        changes = -> _ { }
      else
        cols = changed_columns.dup
        changes = @_audit_initial_values
      end

      Sequel::Plugins::Audit.create do |audit|
        super

        change = audit.add_change(model_name: self.class.name, model_id: self.id)

        (cols & self.class.audit_columns).each do |col|
          change.add_entry(attribute_name: col, from_value: changes[col], to_value: values[col])
        end
      end
    end

    def set_values(values)
      @_audit_initial_values = values.dup
      super(values)
    end
  end
end
