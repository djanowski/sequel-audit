require "test/unit"
require "sequel"

DB = Sequel.sqlite

DB.create_table(:users) do |t|
  t.primary_key(:id)
  t.string(:name)
end

DB.create_table(:posts) do |t|
  t.primary_key(:id)
  t.string(:title)
  t.string(:body)
  t.datetime(:created_at)
end

DB.create_table(:articles) do |t|
  t.primary_key(:id)
  t.string(:topic)
end

require_relative "../lib/sequel-audit/migration"

DB.instance_eval(&AuditMigration.migrate)

require_relative "../lib/sequel-audit"

Sequel::Model.plugin(:audit, ignore: [:created_at])

class User < Sequel::Model

end

class Post < Sequel::Model

end

Post.plugin(:timestamps, update_on_create: true)

class Article < Sequel::Model
  def after_create
    Post.create(title: "First post on #{topic}")
    Post.create(title: "Second post on #{topic}")
    super
  end
end

class AuditTest < Test::Unit::TestCase

end
