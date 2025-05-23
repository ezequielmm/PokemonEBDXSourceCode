#===============================================================================
# ** Game_SelfSwitches
#-------------------------------------------------------------------------------
#  This class handles self switches. It's a wrapper for the built-in class
#  "Hash." Refer to "$game_self_switches" for the instance of this class.
#===============================================================================
class Game_SelfSwitches
  def initialize
    @data = {}
  end

  # Get Self Switch
  #     key : key
  def [](key)
    return @data[key] == true
  end

  # Set Self Switch
  #     key   : key
  #     value : ON (true) / OFF (false)
  def []=(key, value)
    @data[key] = value
  end
end
