require_relative "prelude"

Class.new(AuditTest) do
  def setup
    super

    @john = User.create(name: "John")

    @post = Post.create(title: "How to write Ruby code")
  end

  def test_creates_audits
    Audit.audit(user: @john) do
      @post.update(title: "How NOT to write Ruby code")
    end

    audits = Audit.where(user_id: @john.id)

    assert_equal 1, audits.count

    audit = audits.first

    assert_kind_of Time, audit.date
  end

  def test_does_not_fail_when_not_auditing
    @post.update(title: "How NOT to write Ruby code")

    assert_equal "How NOT to write Ruby code", @post.reload.title
  end

  def test_creates_entries
    Audit.audit(user: @john) do
      @post.update(title: "How NOT to write Ruby code")
    end

    audit = Audit.where(user_id: @john.id).first

    changes = audit.changes

    assert_equal 1, changes.count

    change = changes.first

    assert_equal "Post", change.model_name
    assert_equal @post.id, change.model_id

    entries = change.entries

    assert_equal 1, entries.size

    entry = entries.first

    assert_equal "title", entry.attribute_name
    assert_equal "How to write Ruby code", entry.from_value
    assert_equal "How NOT to write Ruby code", entry.to_value
  end

  def test_logs_the_initial_value_for_an_attribute
    Audit.audit(user: @john) do
      @post.title = "How to write Ruby code II"
      @post.title = "How to write Ruby code III"
      @post.save
    end

    entry = Audit.where(user_id: @john.id).first.changes.first.entries.first

    assert_equal "How to write Ruby code", entry.from_value
    assert_equal "How to write Ruby code III", entry.to_value
  end

  def test_logs_the_initial_value_for_an_attribute_when_changing_from_nil
    assert_equal nil, @post.body

    Audit.audit(user: @john) do
      @post.body = "foo"
      @post.body = "bar"
      @post.save
    end

    entry = Audit.where(user_id: @john.id).first.changes.first.entries.first

    assert_equal nil, entry.from_value
    assert_equal "bar", entry.to_value
  end

  def test_does_not_log_id_when_updating
    Audit.audit(user: @john) do
      @post.update(body: "foo")
    end

    change = Audit.where(user_id: @john.id).first.changes.first

    refute_includes change.entries.map(&:attribute_name), "id"

    assert_equal :update, change.action
  end
end
