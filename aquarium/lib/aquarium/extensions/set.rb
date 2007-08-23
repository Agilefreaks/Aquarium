require 'set'

# Override #== to fix behavior where it seems to ignore overrides of Object#== or Object#eql? when comparing set elements.
# Note that we can't put these definitions inside a helper module, as we do for other methods, and include in the reopened
# Hash class. If we do this, the method is not used!
class Set
  def == set
    equal?(set) and return true
    set.is_a?(Set) && size == set.size or return false
    ary = to_a
    set.all? { |o| ary.include?(o) }
  end

  alias :eql? :==

  def union_using_eql_comparison other
    first = dup
    second = other.dup
    first.size > second.size ? do_union(first, second) : do_union(second, first)
  end

  def intersection_using_eql_comparison other
    first = dup
    second = other.dup
    first.size > second.size ? do_intersection(first, second) : do_intersection(second, first)
  end

  private

  def do_union larger, smaller
    smaller.each do |x| 
     larger.add(x) unless contained_in(larger, x)
    end
    larger
  end

  def do_intersection larger, smaller
    result = Set.new
    smaller.each do |x| 
     result.add(x) if contained_in(larger, x)
    end
    result
  end

  def contained_in set, element
    set.each {|x| return true if element == x}
    false
  end
end
