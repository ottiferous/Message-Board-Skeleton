require 'sqlite3'
require 'singleton'

class QPairs < SQLite3::Database
  include Singleton

  def initialize
    super("qpairs")
    self.results_as_hash = true
    self.type_translation = true
  end

end

class User
  def self.all
    results = QPairs.instance.execute("SELECT * FROM users")
    results.map { |result| User.new(result) }
  end

  def self.find_by_name(fname, lname)
    QPairs.instance.execute(<<-SQL, fname, lname)
      SELECT
        *
      FROM
        users
      WHERE
        users.fname = ? AND users.lname = ?
    SQL
  end

  attr_reader :id, :fname, :lname

  def initialize(options = {})
    @id = options["id"]
    @fname = options["fname"]
    @lname = options["lname"]
  end

  def authored_questions
    Question.find_by_author_id(@id)
  end

  def authored_replies
    QPairs.instance.execute(<<-SQL, @id)
      SELECT
        id, question_id, parent_id, body
      FROM
        replies
      WHERE
        user_id = ?
    SQL
  end

  def create_new(options)
    raise "User already exists!" unless self.id.nil?

    QPairs.instance.execute(<<-SQL, options[:fname], options[:lname])
      INSERT INTO
        users(fname, lname)
      VALUES
        (?, ?);
    SQL

    @id = QPairs.instance.last_insert_row_id
  end
end

# newuser = User.new().create_new({:fname => "Buck", :lname => "Shiny"})

class Question
  def self.all
    results = QPairs.instance.execute("SELECT * FROM questions")
    results.map { |result| Question.new(result) }
  end

  def self.find_by_author_id(author_id)
    QPairs.instance.execute(<<-SQL, author_id)
      SELECT
        id, title, body
      FROM
        questions
      WHERE
        user_id = ?
    SQL
  end

  def initialize(options = {})
    @id, @title, @body, @user_id = options.values_at("id", "title", "body", "user_id")
  end

  def author
    QPairs.instance.execute(<<-SQL, @user_id)
      SELECT
        *
      FROM
        users
      WHERE
        id = ?
    SQL
  end

  def replies
    QPairs.instance.execute(<<-SQL, @id)
      SELECT
        id, parent_id, user_id, body
      FROM
        replies
      WHERE
        question_id = ?
    SQL
  end

  def create_new(options)
    raise "Question already exists!" unless self.id.nil?

    QPairs.instance.execute(<<-SQL, options[:title], options[:body], options[:user_id])
      INSERT INTO
        questions(title, body, user_id)
      VALUES
        (?, ?, ?);
    SQL

    @id = QPairs.instance.last_insert_row_id
  end
end

class Reply
  def self.all
    results = QPairs.instance.execute("SELECT * FROM replies")
    results.map { |result| Reply.new(result) }
  end

  def initialize(options = {})
    values = options.values_at("question_id", "parent_id", "user_id", "body")
    @question_id, @parent_id, @user_id, @body = values
  end

  def create_new(options)
    raise "Reply already exists!" unless self.id.nil?

    QPairs.instance.execute(<<-SQL, options[:question_id], options[:parent_id], options[:user_id], options[:body])
      INSERT INTO
        replies(question_id, parent_id, user_id, body)
      VALUES
        (?, ?, ?, ?);
    SQL

    @id = QPairs.instance.last_insert_row_id
  end
end
