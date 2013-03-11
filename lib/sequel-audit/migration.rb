class AuditMigration
  def self.migrate
    lambda do |*args|
      create_table(:audits) do |t|
        t.primary_key(:id)
        t.integer(:user_id)
        t.datetime(:date)
      end

      create_table(:audit_changes) do |t|
        t.primary_key(:id)
        t.foreign_key(:audit_id)
        t.string(:model_name)
        t.string(:model_id)
      end

      create_table(:audit_entries) do |t|
        t.primary_key(:id)
        t.foreign_key(:audit_change_id)
        t.string(:attribute_name)
        t.string(:from_value)
        t.string(:to_value)
      end
    end
  end
end
