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
    Reply.find_by_user_id(@id)
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

  def followed_questions
    QuestionFollower.followed_questions_for_user_id(@id)
  end

end

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

  def self.most_followed(n)
    QuestionFollower.most_followed_questions(n)
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
    Reply.find_by_question_id(@id)
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

  def followers
    QuestionFollower.followers_for_question_id(@id)
  end

end

class Reply
  def self.all
    results = QPairs.instance.execute("SELECT * FROM replies")
    results.map { |result| Reply.new(result) }
  end

  def self.find_by_question_id(q_id)
    QPairs.instance.execute(<<-SQL, q_id)
      SELECT
        id, parent_id, user_id, body
      FROM
        replies
      WHERE
        question_id = ?
    SQL
  end

  def self.find_by_user_id(u_id)
    QPairs.instance.execute(<<-SQL, u_id)
      SELECT
        id, question_id, parent_id, body
      FROM
        replies
      WHERE
        user_id = ?
    SQL
  end

  def initialize(options = {})
    values = options.values_at("id", "question_id", "parent_id", "user_id", "body")
    @id, @question_id, @parent_id, @user_id, @body = values
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

  def author
    QPairs.instance.execute(<<-SQL, @user_id)
      SELECT
        id, fname, lname
      FROM
        users
      WHERE
        id = ?
    SQL
  end

  def question
    QPairs.instance.execute(<<-SQL, @question_id)
      SELECT
        id, title, body, user_id
      FROM
        questions
      WHERE
        id = ?
    SQL
  end

  def parent_reply
    QPairs.instance.execute(<<-SQL, @parent_id)
      SELECT
        *
      FROM
        replies
      WHERE
        id = ?
    SQL
  end

  def child_replies
    QPairs.instance.execute(<<-SQL, @id)
      SELECT
        *
      FROM
        replies
      WHERE
        parent_id = ?
    SQL
  end
  # /Reply.class
end

class QuestionFollower
  def self.all
    results = QPairs.instance.execute("SELECT * FROM question_followers")
    results.map { |result| QuestionFollower.new(result) }
  end

  def self.followers_for_question_id(q_id)
    QPairs.instance.execute(<<-SQL, q_id)
    SELECT
      users.id, users.fname, users.lname
    FROM
      question_followers
      JOIN users
        ON user_id = users.id
    WHERE
      question_id = ?
  SQL
  end

  def self.followed_questions_for_user_id(u_id)
    QPairs.instance.execute(<<-SQL, u_id)
      SELECT
        questions.id, questions.title, questions.body, questions.user_id
      FROM
        question_followers
        JOIN questions
          ON question_followers.question_id = questions.id
      WHERE
        question_followers.user_id = ?
    SQL
  end

  def self.most_followed_questions(n)
    QPairs.instance.execute(<<-SQL, n)
    SELECT questions.*
    FROM   questions
    WHERE  questions.id IN (SELECT question_id
                            FROM   question_followers
                            GROUP  BY question_id
                            ORDER  BY COUNT(question_id)
                            DESC LIMIT ?)
    SQL
  end

  #/QuestionFollower.class
end

class QuestionLike

  def self.all
    results = QPairs.instance.execute("SELECT * FROM question_likes")
    results.map { |result| QuestionLike.new(result) }
  end

  def self.likers_for_question_id(q_id)

  end

end
