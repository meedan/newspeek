# frozen_string_literal: true

class Class
  def subclasses
    ObjectSpace.each_object(Class).select { |klass| klass < self }
  end
end
