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

class Users
  def self.all
    results = QPairs.instance.execute("SELECT * FROM users")
    results.map { |result| Users.new(result) }
  end

  attr_reader :id, :fname, :lname

  def initialize(options = {})
    @id = options["id"]
    @fname = options["fname"]
    @lname = options["lname"]
  end

  def name
    "#{@fname} #{@lname}"
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

# newuser = Users.new().create_new({:fname => "Buck", :lname => "Shiny"})

class Questions
  def self.all
    results = QPairs.instance.execute("SELECT * FROM questions")
    results.map { |result| Questions.new(result) }
  end

  def initialize(options = {})
    @title, @body, @user_id = options.values_at("title", "body", "user_id")
  end


end