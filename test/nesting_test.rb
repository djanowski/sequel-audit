require_relative "prelude"

Class.new(AuditTest) do
  def setup
    super

    @john = User.create(name: "John")
  end

  def test_nesting_changes
    Audit.audit(user: @john) do
      @article = Article.create(topic: "Ruby")
    end

    audits = Audit.where(user_id: @john.id)

    assert_equal 1, audits.count

    audit = audits.first

    changes = audit.changes

    assert_equal 3, changes.count

    assert_equal %w[Article Post Post], changes.map(&:model_name).sort
  end
end
