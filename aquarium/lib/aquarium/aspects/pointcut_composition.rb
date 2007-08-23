require 'aquarium/aspects/pointcut'
require 'aquarium/utils/array_utils'

# == Pointcut (composition)
# Since Pointcuts are queries, they can be composed, _i.e.,_ unions and intersections of
# them can be computed, yielding new Pointcuts.
class Aquarium::Aspects::Pointcut
  
  def or pointcut2
    result = Aquarium::Aspects::Pointcut.new
    result.specification           = specification.or(pointcut2.specification) do |value1, value2| 
      value1.union_using_eql_comparison value2
    end
    result.join_points_matched     = join_points_matched.union_using_eql_comparison     pointcut2.join_points_matched
    result.join_points_not_matched = join_points_not_matched.union_using_eql_comparison pointcut2.join_points_not_matched
    result.candidate_types         = candidate_types.union         pointcut2.candidate_types
    result.candidate_objects       = candidate_objects.union       pointcut2.candidate_objects
    result
  end
  
  alias :union :or
  
  def and pointcut2
    result = Aquarium::Aspects::Pointcut.new
    result.specification           = specification.and(pointcut2.specification) do |value1, value2| 
      value1.intersection_using_eql_comparison value2
    end
    result.join_points_matched     = join_points_matched.intersection_using_eql_comparison      pointcut2.join_points_matched
    result.join_points_not_matched = join_points_not_matched.intersection_using_eql_comparison  pointcut2.join_points_not_matched
    result.candidate_types         = candidate_types.intersection          pointcut2.candidate_types
    result.candidate_objects       = candidate_objects.intersection        pointcut2.candidate_objects
    result
  end
  
  alias :intersection :and  
end