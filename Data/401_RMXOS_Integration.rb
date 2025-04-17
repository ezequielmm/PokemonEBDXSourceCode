#==============================================================================
# ** RMXOS Integration for Pokémon EBDX
#------------------------------------------------------------------------------
# Este script integra el sistema multiplayer RMX-OS con Pokémon EBDX
# Permite funcionalidades online como chat, comercio y batallas entre jugadores
#==============================================================================

module RMXOS
  module Options
    #--------------------------------------------------------------------------
    # * Configuración básica
    #--------------------------------------------------------------------------
    GAME_VERSION = "1.0.0"
    SERVER_REFRESH = 40
    SERVER_TIMEOUT = 120
    
    # Configuración de servidores
    SERVERS = []
    SERVERS.push(['Local', '127.0.0.1', 54269])
    
    # Configuración de seguridad
    ENCRYPTION_SALT = "pk"
    MIN_USERPASS_LENGTH = 4
    MAX_USERPASS_LENGTH = 20
    
    # Configuración de chat
    CHATBOX_WIDTH = 400
    CHATBOX_LINES = 8
    CHAT_BUBBLES = true
    REMEMBER_LOGIN = true
    
    # Variables a sincronizar
    EXCHANGE_VARIABLES = ['@x', '@y', '@character_name', '@character_hue']
    
    # Contenedores de guardado
    SAVE_CONTAINERS = [
      '$game_system', '$game_switches', '$game_variables', 
      '$game_player', '$game_party', '$game_map'
    ]
    
    # Datos a guardar
    SAVE_DATA = {}
    
    # Datos de creación
    CREATION_DATA = {}
  end
  
  module Integration
    #--------------------------------------------------------------------------
    # * Constantes
    #--------------------------------------------------------------------------
    VERSION = 1.0
    
    #--------------------------------------------------------------------------
    # * Variables del módulo
    #--------------------------------------------------------------------------
    @initialized = false
    
    #--------------------------------------------------------------------------
    # * Inicialización del sistema RMX-OS
    #--------------------------------------------------------------------------
    def self.initialize
      return if @initialized
      
      # Inicializar sistema de conexión
      setup_connection_system
      
      # Extender clases del juego para soporte multiplayer
      extend_game_classes
      
      # Inicializar interfaces de usuario
      setup_user_interfaces
      
      @initialized = true
    end
    
    #--------------------------------------------------------------------------
    # * Configurar sistema de conexión
    #--------------------------------------------------------------------------
    def self.setup_connection_system
      # Inicializar sistema de red
      RMXOS::Network.initialize
    end
    
    #--------------------------------------------------------------------------
    # * Extender clases del juego
    #--------------------------------------------------------------------------
    def self.extend_game_classes
      # Extender Game_Player para soporte multiplayer
      extend_game_player
      
      # Extender Scene_Map para mostrar otros jugadores
      extend_scene_map
      
      # Extender Game_Party para comercio
      extend_game_party
    end
    
    #--------------------------------------------------------------------------
    # * Extender Game_Player
    #--------------------------------------------------------------------------
    def self.extend_game_player
      # Integrar con el sistema de jugadores
      RMXOS::PlayerExtension.initialize
    end
    
    #--------------------------------------------------------------------------
    # * Extender Scene_Map
    #--------------------------------------------------------------------------
    def self.extend_scene_map
      # Integrar con el sistema de visualización de jugadores
      class ::Scene_Map
        alias rmxos_update update
        def update
          rmxos_update
          RMXOS::PlayerExtension.update_player_sprites if defined?(RMXOS::PlayerExtension)
          RMXOS::ChatSystem.update if defined?(RMXOS::ChatSystem)
        end
      end
    end
    
    #--------------------------------------------------------------------------
    # * Extender Game_Party
    #--------------------------------------------------------------------------
    def self.extend_game_party
      # Integrar con el sistema de comercio
      class ::Game_Party
        alias rmxos_initialize initialize
        def initialize
          rmxos_initialize
          @trading_with = nil
        end
        
        def trading?
          return @trading_with != nil
        end
        
        def start_trade(player_id)
          @trading_with = player_id
          RMXOS::TradeSystem.start_trade(player_id) if defined?(RMXOS::TradeSystem)
        end
        
        def end_trade
          @trading_with = nil
          RMXOS::TradeSystem.cancel_trade if defined?(RMXOS::TradeSystem)
        end
      end
    end
    
    #--------------------------------------------------------------------------
    # * Configurar interfaces de usuario
    #--------------------------------------------------------------------------
    def self.setup_user_interfaces
      # Inicializar sistemas
      RMXOS::ChatSystem.initialize if defined?(RMXOS::ChatSystem)
      RMXOS::TradeSystem.initialize if defined?(RMXOS::TradeSystem)
      RMXOS::BattleSystem.initialize if defined?(RMXOS::BattleSystem)
      
      # Añadir opción de multijugador al menú principal
      class ::Scene_Title
        alias rmxos_command_new command_new
        def command_new
          # Crear escena de selección de servidor
          if @command_window.index == 3 # Asumiendo que añadimos "Multijugador" como opción 3
            RMXOS::Network.connect if defined?(RMXOS::Network)
            # Aquí iría la lógica para mostrar la pantalla de login/registro
          else
            rmxos_command_new
          end
        end
        
        alias rmxos_create_command_window create_command_window
        def create_command_window
          rmxos_create_command_window
          # Añadir opción de multijugador
          @command_window.commands.insert(3, _INTL("Multijugador"))
        end
      end
    end
  end
end

# Inicializar integración RMX-OS cuando se carga el script
RMXOS::Integration.initialize
