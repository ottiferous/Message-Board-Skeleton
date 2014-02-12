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

