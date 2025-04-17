#==============================================================================
# ** Main
#------------------------------------------------------------------------------
# Punto de entrada principal para el sistema RMX-OS integrado con Pokémon EBDX
# Reemplaza el Main original de Essentials para soportar funcionalidades multiplayer
#==============================================================================

# Inicializar módulos RMX-OS
RMXOS::Network.initialize if defined?(RMXOS::Network)
RMXOS::PlayerExtension.initialize if defined?(RMXOS::PlayerExtension)
RMXOS::ChatSystem.initialize if defined?(RMXOS::ChatSystem)
RMXOS::TradeSystem.initialize if defined?(RMXOS::TradeSystem)
RMXOS::BattleSystem.initialize if defined?(RMXOS::BattleSystem)

class Scene_DebugIntro
  def main
    Graphics.transition(0)
    sscene = PokemonLoad_Scene.new
    sscreen = PokemonLoadScreen.new(sscene)
    sscreen.pbStartLoadScreen
    Graphics.freeze
  end
end

def pbCallTitle
  return Scene_DebugIntro.new if $DEBUG
  return Scene_Intro.new
end

def mainFunction
  if $DEBUG
    pbCriticalCode { mainFunctionDebug }
  else
    mainFunctionDebug
  end
  return 1
end

def mainFunctionDebug
  begin
    MessageTypes.load_default_messages if FileTest.exist?("Data/messages_core.dat")
    PluginManager.runPlugins
    
    # Inicializar integración RMX-OS
    RMXOS::Integration.initialize if defined?(RMXOS::Integration)
    
    Compiler.main
    Game.initialize
    Game.set_up_system
    Graphics.update
    Graphics.freeze
    $scene = pbCallTitle
    $scene.main until $scene.nil?
    Graphics.transition
  rescue Hangup
    pbPrintException($!) if !$DEBUG
    pbEmergencySave
    raise
  end
end

loop do
  retval = mainFunction
  case retval
  when 0   # failed
    loop do
      Graphics.update
    end
  when 1   # ended successfully
    break
  end
end
