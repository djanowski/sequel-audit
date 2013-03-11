require_relative "prelude"

Class.new(AuditTest) do
  def setup
    super

    @john = User.create(name: "John")

    @post1 = Post.create(title: "How to write Python code")
  end

  def test_multiple_audits
    Audit.audit(user: @john) do
      @post2 = Post.create(title: "How to write Ruby code")
      @post1.update(title: "How to write good Python code")
    end

    audits = Audit.where(user_id: @john.id).all

    assert_equal 2, audits.count

    changes = audits[0].changes

    assert_equal 1, changes.count

    assert_equal "Post", changes[0].model_name
    assert_equal @post2.id, changes[0].model_id

    assert_equal "title", changes[0].entries[0].attribute_name
    assert_equal "How to write Ruby code", changes[0].entries[0].to_value
    assert_equal nil, changes[0].entries[0].from_value

    changes = audits[1].changes

    assert_equal "Post", changes[0].model_name
    assert_equal @post1.id, changes[0].model_id

    assert_equal "title", changes[0].entries[0].attribute_name
    assert_equal "How to write Python code", changes[0].entries[0].from_value
    assert_equal "How to write good Python code", changes[0].entries[0].to_value
  end
end
