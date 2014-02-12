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

