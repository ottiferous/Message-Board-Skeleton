require 'sqlite3'
require 'singleton'

require 'user.rb'
require 'question.rb'
require 'reply.rb'
require 'questionfollower.rb'
require 'questionlike.rb'

class QPairs < SQLite3::Database
  include Singleton

  def initialize
    super("qpairs")
    self.results_as_hash = true
    self.type_translation = true
  end

end
