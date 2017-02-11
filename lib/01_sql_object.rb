require_relative 'db_connection'
require 'active_support/inflector'
# NB: the attr_accessor we wrote in phase 0 is NOT used in the rest
# of this project. It was only a warm up.

class SQLObject
  def self.columns

    @columns ||= DBConnection.execute2(<<-SQL)
      SELECT
        *
      FROM
        #{self.table_name}
    SQL
    @columns.first.map!{|col| col.to_sym}
  end

  def self.finalize!

    self.columns.each do |column|

      define_method "#{column}" do
        @attributes[column]
      end

      define_method "#{column}=" do |value|
        self.attributes
        @attributes[column] = value
      end
    end
  end

  def self.table_name=(table_name)
      table_name
  end

  def self.table_name
    names = self.name.to_s.downcase!
    names = "#{names}s"
  end

  def self.all
    self.finalize!
    results = DBConnection.execute(<<-SQL)
      SELECT
       *
      FROM
      #{self.table_name}
    SQL

    self.parse_all(results)
    # p results
  end

  def self.parse_all(results)
    results.map do |object|
      self.new(object)
    end

  end

  def self.find(id)
    found_id = DBConnection.execute(<<-SQL)
    SELECT
      *
    FROM
      #{self.table_name}
    WHERE
      id = #{id}
    SQL

    # p found_id
    if found_id == []
       nil
    else
      self.all[id-1]
    end
  end

  def initialize(params = {})
    columns =  self.class.finalize!
    params.each do |k,v|
      key = k.to_sym
      raise "unknown attribute '#{k}'" unless columns.include?(key)
      self.send("#{key}=", v)
    end

  end

  def attributes
    @attributes ||= {}
  end

  def attribute_values
    self.class.columns.map {|at| self.send(at)}
  end

  def insert
    col_names = self.class.columns.join(', ')
    n = self.class.columns.length
    questions_marks = (["?"]* n).join(', ')


    DBConnection.execute(<<-SQL,*attribute_values)
    INSERT INTO
      #{self.class.table_name} (#{col_names})
    VALUES
      (#{questions_marks})
    SQL

    self.id = DBConnection.last_insert_row_id
  end

  def update
    # col_names = self.class.columns.join(', ')
    # n = self.class.columns.length
    # questions_marks = (["?"]* n).join(', ')
    #
    # set_line = self.class.columns.map do |el|
    #   "#{el} = ?"
    # end
    # # DBConnection.execute(<<-SQL,*attributes)
  end

  def save
    # id.nil? ? insert : update
  end
end
