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