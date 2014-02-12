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

  attr_accessor :fname, :lname
  attr_reader :id

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

  def save(options)
    if self.id.nil?
      QPairs.instance.execute(<<-SQL, @fname, @lname, @id)
        UPDATE
          users
        SET
          fname = ?,
          lname = ?
        WHERE
          id = ?
      SQL
    else
      QPairs.instance.execute(<<-SQL, @fname, @lname)
        INSERT INTO
          users(fname, lname)
        VALUES
          (?, ?);
      SQL
      @id = QPairs.instance.last_insert_row_id
    end
  end

  def followed_questions
    QuestionFollower.followed_questions_for_user_id(@id)
  end

  def liked_questions
    QuestionLike.liked_questions_for_user_id(@id)
  end

  def average_karma
    karma = QPairs.instance.execute(<<-SQL, @id, @id)
      SELECT likes*1.0/total_posts AS num
      FROM	(-- Number of likes per post for a given user
      			SELECT COUNT(question_id) AS likes,
      						 (SELECT id
      							 FROM questions
      						 WHERE user_id IS ?) AS total_posts
      			FROM question_likes
      			WHERE question_id IN (
      			-- Returning the questions.id of all questions authored by user
      														SELECT id as total_posts
      														FROM questions
      														WHERE user_id IS ?)
      			GROUP BY question_id)
      GROUP BY likes;
    SQL

    karma[0]["num"]
  end

  #/Users Class
end

class Question
  attr_accessor :title, :body
  attr_reader :id, :user_id

  def self.all
    results = QPairs.instance.execute("SELECT * FROM questions")
    results.map { |result| Question.new(result) }
  end

  def save(options)
    if self.id.nil?
      QPairs.instance.execute(<<-SQL, @title, @body, @id)
        UPDATE
          questions
        SET
          title = ?,
          body = ?
        WHERE
          id = ?
      SQL
    else
      QPairs.instance.execute(<<-SQL, @title, @body, @user_id)
        INSERT INTO
          questions(title, body, user_id)
        VALUES
          (?, ?, ?);
      SQL

      @id = QPairs.instance.last_insert_row_id
    end
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

  def self.most_liked(n)
    QuestionLike.most_liked_questions(n)
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

  def likers
    QuestionLike.likers_for_question_id(@id)
  end

  def num_likes
    QuestionLike.num_likes_for_question_id(@id)
  end

  #/Question Class
end

class Reply
  attr_accessor :body
  attr_reader :id, :parent_id, :user_id

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

  def save(options)
    if self.id.nil?
      QPairs.instance.execute(<<-SQL, @body, @id)
        UPDATE
          replies
        SET
          body = ?
        WHERE
          id = ?
      SQL
    else
      QPairs.instance.execute(<<-SQL, @question_id, @parent_id, @user_id, @body)
        INSERT INTO
          replies(question_id, parent_id, user_id, body)
        VALUES
          (?, ?, ?, ?)
      SQL

      @id = QPairs.instance.last_insert_row_id
    end
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
    QPairs.instance.execute(<<-SQL, q_id)
    SELECT users.*
    FROM   question_likes
           JOIN users
             ON question_likes.user_id = users.id
    WHERE  question_id = ?
    SQL
  end

  def self.num_likes_for_question_id(q_id)
    num = QPairs.instance.execute(<<-SQL, q_id)
      SELECT COUNT(question_id) as likes
      FROM question_likes
      WHERE question_id = ?
    SQL
    num[0]["likes"].to_i
  end

  def self.liked_questions_for_user_id(u_id)
    QPairs.instance.execute(<<-SQL, u_id)
      SELECT questions.*
      FROM   question_likes
             JOIN questions
               ON question_likes.question_id = questions.id
      WHERE  question_likes.user_id = ?
    SQL
  end

  def self.most_liked_questions(n)
    QPairs.instance.execute(<<-SQL, n)
    SELECT questions.*
    FROM   questions
    WHERE  questions.id IN (SELECT question_id
                            FROM   question_likes
                            GROUP  BY question_id
                            ORDER  BY COUNT(question_id)
                            DESC LIMIT ?)
    SQL
  end

end
