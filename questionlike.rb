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
