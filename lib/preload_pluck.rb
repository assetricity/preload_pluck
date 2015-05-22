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

  def preload_pluck(*args)
    fields = args.map {|arg| Field.new(self, arg.to_s.split('.'))}

    plucked_cols = fields.map do |field|
      if field.nested?(0)
        field.assoc(0).foreign_key
      else
        field.path.last
      end
    end.uniq
    data = pluck(*plucked_cols)
    if fields.length == 1
      # Pluck returns a flat array if only one value, so use a consistent structure if there is one or multiple fields
      data.map! {|val| [val]}
    end
    data = __preload_pluck_to_attrs(data, plucked_cols)

    # A cache of records that we populate then join to later based on foreign keys
    joined_data = {}

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
          collection = joined_data[prev_path].values
        end
        ids = collection.map {|a| a[assoc.foreign_key]}.uniq

        # Select id and other fields at the next level
        cols = group.map do |f|
          if f.nested?(level + 1)
            f.assoc(level + 1).foreign_key
          else
            f.path[level + 1]
          end
        end.uniq
        joined_plucked_cols = [klass.primary_key, *cols]
        joined = klass.where(klass.primary_key => ids).pluck(*joined_plucked_cols)
        attrs = __preload_pluck_to_attrs(joined, joined_plucked_cols)

        # Index to quickly search on id
        joined_data[current_path] = attrs.index_by {|a| a[klass.primary_key]}
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
            val = joined_data[current_path][val]
            val = val[col] if val
          end
          val
        else
          attr[field.path.last]
        end
      end
    end
  end

  def __preload_pluck_to_attrs(array, column_names)
    array.map do |item|
      pairs = item.map.with_index {|element, index| [column_names[index], element]}.flatten
      Hash[*pairs]
    end
  end
end

ActiveRecord::Base.extend(PreloadPluck)
