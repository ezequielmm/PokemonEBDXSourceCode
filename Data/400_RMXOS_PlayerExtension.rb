#==============================================================================
# ** RMXOS Player Extension for Pokémon EBDX
#------------------------------------------------------------------------------
# Este script extiende la clase Game_Player para soportar funcionalidades
# multiplayer como visualización de otros jugadores y sincronización
#==============================================================================

module RMXOS
  module PlayerExtension
    #--------------------------------------------------------------------------
    # * Constantes
    #--------------------------------------------------------------------------
    SYNC_INTERVAL = 10 # Frames entre sincronizaciones
    
    #--------------------------------------------------------------------------
    # * Variables del módulo
    #--------------------------------------------------------------------------
    @other_players = {}
    @sync_counter = 0
    @initialized = false
    
    #--------------------------------------------------------------------------
    # * Inicialización
    #--------------------------------------------------------------------------
    def self.initialize
      return if @initialized
      
      @other_players = {}
      @sync_counter = 0
      @initialized = true
      
      # Extender Game_Player
      extend_game_player
    end
    
    #--------------------------------------------------------------------------
    # * Extender Game_Player
    #--------------------------------------------------------------------------
    def self.extend_game_player
      # Extender la clase Game_Player usando monkey patching
      Game_Player.class_eval do
        alias rmxos_player_update update
        
        def update
          rmxos_player_update
          
          # Verificar si la posición ha cambiado
          position_changed = (@last_x != @x || @last_y != @y || 
                            @last_direction != @direction || 
                            @last_map_id != $game_map.map_id)
          
          # Si la posición cambió, actualizar variables de seguimiento
          if position_changed
            @last_x = @x
            @last_y = @y
            @last_direction = @direction
            @last_map_id = $game_map.map_id
            
            # Notificar cambio de posición
            RMXOS::PlayerExtension.send_player_position
          end
        end
        
        alias rmxos_player_initialize initialize
        def initialize
          rmxos_player_initialize
          @last_x = 0
          @last_y = 0
          @last_direction = 0
          @last_map_id = 0
        end
      end
    end
    
    #--------------------------------------------------------------------------
    # * Obtener otros jugadores
    #--------------------------------------------------------------------------
    def self.other_players
      @other_players
    end
    
    #--------------------------------------------------------------------------
    # * Actualizar otros jugadores
    #--------------------------------------------------------------------------
    def self.update
      return unless @initialized
      
      @sync_counter += 1
      if @sync_counter >= SYNC_INTERVAL
        @sync_counter = 0
        send_player_position
      end
    end
    
    #--------------------------------------------------------------------------
    # * Actualizar sprites de jugadores
    #--------------------------------------------------------------------------
    def self.update_player_sprites
      return unless @initialized
      
      # Actualizar sprites de otros jugadores
      # Esta función se implementará cuando se integre con el sistema de sprites de Essentials
      @other_players.each do |player_id, player_data|
        next if player_data[:map_id] != $game_map.map_id
        
        # Actualizar o crear sprite si no existe
        unless player_data[:sprite]
          player_data[:sprite] = create_player_sprite(player_data)
        end
        
        # Actualizar posición del sprite
        if player_data[:sprite]
          player_data[:sprite].x = player_data[:x] * 32 + 16
          player_data[:sprite].y = player_data[:y] * 32 + 32
          player_data[:sprite].direction = player_data[:direction]
          player_data[:sprite].update
        end
      end
    end
    
    #--------------------------------------------------------------------------
    # * Crear sprite de jugador
    #--------------------------------------------------------------------------
    def self.create_player_sprite(player_data)
      # Esta función se implementará cuando se integre con el sistema de sprites de Essentials
      # Debe crear un sprite para representar a otro jugador en el mapa
      return nil
    end
    
    #--------------------------------------------------------------------------
    # * Enviar posición del jugador
    #--------------------------------------------------------------------------
    def self.send_player_position
      return unless @initialized && $game_player && $game_map
      
      # Preparar datos del jugador
      player_data = {
        map_id: $game_map.map_id,
        x: $game_player.x,
        y: $game_player.y,
        direction: $game_player.direction,
        character_name: $game_player.character_name,
        character_hue: $game_player.character_hue
      }
      
      # Enviar datos al servidor
      RMXOS::Network.send_position_update(
        player_data[:x],
        player_data[:y],
        player_data[:direction],
        player_data[:map_id]
      ) if defined?(RMXOS::Network) && RMXOS::Network.connected?
    end
    
    #--------------------------------------------------------------------------
    # * Añadir otro jugador
    #--------------------------------------------------------------------------
    def self.add_player(player_id, player_data)
      return unless @initialized
      
      @other_players[player_id] = player_data
      @other_players[player_id][:sprite] = nil
    end
    
    #--------------------------------------------------------------------------
    # * Eliminar otro jugador
    #--------------------------------------------------------------------------
    def self.remove_player(player_id)
      return unless @initialized
      
      # Eliminar sprite si existe
      if @other_players[player_id] && @other_players[player_id][:sprite]
        # Eliminar sprite de la escena
        @other_players[player_id][:sprite].dispose
      end
      
      @other_players.delete(player_id)
    end
    
    #--------------------------------------------------------------------------
    # * Actualizar datos de otro jugador
    #--------------------------------------------------------------------------
    def self.update_player(player_id, player_data)
      return unless @initialized && @other_players[player_id]
      
      # Actualizar datos del jugador
      @other_players[player_id][:map_id] = player_data[:map_id] if player_data[:map_id]
      @other_players[player_id][:x] = player_data[:x] if player_data[:x]
      @other_players[player_id][:y] = player_data[:y] if player_data[:y]
      @other_players[player_id][:direction] = player_data[:direction] if player_data[:direction]
      @other_players[player_id][:character_name] = player_data[:character_name] if player_data[:character_name]
      @other_players[player_id][:character_hue] = player_data[:character_hue] if player_data[:character_hue]
    end
  end
end
