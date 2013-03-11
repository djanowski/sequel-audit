require_relative "prelude"

Class.new(AuditTest) do
  def setup
    super

    @john = User.create(name: "John")
  end

  def test_creates_audits
    post = Audit.audit(user: @john) do
      Post.create(title: "How to write Ruby code")
    end

    assert post
    refute post.new?

    audits = Audit.where(user_id: @john.id)

    assert_equal 1, audits.count

    audit = audits.first

    assert_kind_of Time, audit.date
  end

  def test_does_not_fail_when_not_auditing
    post = Post.create(title: "How to write Ruby code")

    refute post.new?
  end

  def test_creates_entries
    post = Audit.audit(user: @john) do
      Post.create(title: "How to write Ruby code")
    end

    audit = Audit.where(user_id: @john.id).first

    changes = audit.changes

    assert_equal 1, changes.count

    change = changes.first

    assert_equal "Post", change.model_name
    assert_equal post.id, change.model_id

    entry = change.entries.first

    assert_equal "title", entry.attribute_name
    assert_equal nil, entry.from_value
    assert_equal "How to write Ruby code", entry.to_value
  end

  def test_ignores_specified_columns
    Audit.audit(user: @john) do
      Post.create(title: "How to write Ruby code")
    end

    attrs = Audit.where(user_id: @john.id).first.changes.first.entries.map(&:attribute_name)

    assert_includes attrs, "title"
    refute_includes attrs, "created_at"
  end

  def test_ignores_nil_attributes
    Audit.audit(user: @john) do
      Post.create(title: "How to write Ruby code")
    end

    attrs = Audit.where(user_id: @john.id).first.changes.first.entries.map(&:attribute_name)

    assert_includes attrs, "title"
    refute_includes attrs, "body"
  end

  def test_logs_id_change_to_signal_creates
    post = Audit.audit(user: @john) do
      Post.create(title: "How to write Ruby code")
    end

    change = Audit.where(user_id: @john.id).first.changes.first

    entry = change.entries.detect { |e| e.attribute_name == "id" }

    assert_not_nil entry

    assert_equal nil, entry.from_value
    assert_equal post.id, entry.to_value

    assert_equal :create, change.action
  end
end
