require 'preload_pluck/version'
require 'active_record'

module PreloadPluck
  class Field < Struct.new(:base_class, :path)
    def nested?(level)
      level + 2 <= path.length
    end

    def level?(level)
      !!path[level]
    end

    def path_upto(level)
      path[0..level].join('.')
    end

    def assoc(level)
      return nil if level >= path.length
      current_class = base_class
      assoc = nil
      (level + 1).times do |l|
        assoc = current_class.reflect_on_association(path[l])
        raise 'preload_pluck only supports belongs_to associations' unless assoc.macro == :belongs_to
        current_class = assoc.class_name.constantize
      end
      assoc
    end
  end

  # Return a 2-dimensional array of values where columns correspond to supplied arguments. Data from associations is
  # eager loaded.
  #
  # Attributes on the current model can be supplied by name:
  #
  #    Comment.preload_pluck(:title, :text)
  #
  # Nested attributes should be separated by a period:
  #
  #    Comment.preload_pluck('post.title', 'post.text')
  #
  # Both immediate and nested attributes can be mixed:
  #
  #    Comment.preload_pluck(:title, :text, 'post.title', 'post.text')
  #
  # Any SQL conditions should be set before `preload_pluck` is called:
  #
  #    Comment.order(:created_at)
  #           .joins(:user)
  #           .where(user: {name: 'Alice'))
  #           .preload_pluck(:title, :text, 'post.title', 'post.text')
  #
  # @param args [Array<Symbol or String>] list of immediate and/or nested model attributes.
  # @return [Array<Array>] 2-dimensional array where columns correspond to supplied arguments.
  def preload_pluck(*args)
    fields = args.map {|arg| Field.new(self, arg.to_s.split('.'))}

    plucked_cols = fields.map do |field|
      if field.nested?(0)
        field.assoc(0).foreign_key
      else
        field.path[0]
      end
    end.uniq
    data = connection.execute(select(plucked_cols).to_sql)

    # A cache of records that we populate then join to later based on foreign keys
    nested_data = {}

    # Incrementally process nested fields by level
    max_level = fields.map {|f| f.path.length - 1}.max
    max_level.times do |level|
      fields.select {|f| f.nested?(level)}
            .group_by {|f| f.path_upto(level)}
            .each do |current_path, group|
        # Just use the first item - could use any item in the group
        assoc = group.first.assoc(level)
        klass = assoc.class_name.constantize

        # List of ids that are related to the previous objects (the IN clause in SQL preload statement)
        if level == 0 # Level 0 is different as data is stored in a different structure
          collection = data
        else
          prev_path = group.first.path_upto(level - 1)
          collection = nested_data[prev_path].values
        end
        ids = collection.map {|d| d[assoc.foreign_key]}.uniq

        # Select id and other fields at the next level
        cols = group.map do |f|
          if f.nested?(level + 1)
            f.assoc(level + 1).foreign_key
          else
            f.path[level + 1]
          end
        end.uniq
        # If id is specified by user, we need to make this list unique
        plucked_cols = [klass.primary_key, *cols].uniq
        sql = klass.where(klass.primary_key => ids).select(plucked_cols).to_sql
        indexed_data = klass.connection.execute(sql)
                            .index_by {|d| d[klass.primary_key]} # Index to quickly search by id
        nested_data[current_path] = indexed_data
      end
    end

    data.map do |attr|
      fields.map do |field|
        if field.nested?(0)
          assoc = field.assoc(0)
          val = attr[assoc.foreign_key]
          (field.path.length - 1).times do |level|
            current_path = field.path_upto(level)
            if field.nested?(level + 1)
              col = field.assoc(level + 1).foreign_key
            else
              col = field.path.last
            end
            current_data = nested_data[current_path]
            current_row = current_data[val]
            val = current_row[col] if current_row
          end
          val
        else
          attr[field.path[0]]
        end
      end
    end
  end
end

ActiveRecord::Base.extend(PreloadPluck)
