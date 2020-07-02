# frozen_string_literal: true

# Small extension to convert Class to :class
class Class
  def subclasses
    ObjectSpace.each_object(Class).select { |klass| klass < self }
  end
end
