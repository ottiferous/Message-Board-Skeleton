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