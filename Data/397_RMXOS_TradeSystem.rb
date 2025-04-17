#==============================================================================
# ** RMXOS Trade System for Pokémon EBDX
#------------------------------------------------------------------------------
# Este script implementa el sistema de comercio para la integración multiplayer
# Permite intercambio de Pokémon y objetos entre jugadores
#==============================================================================

module RMXOS
  module TradeSystem
    #--------------------------------------------------------------------------
    # * Constantes
    #--------------------------------------------------------------------------
    TRADE_WINDOW_WIDTH = 400
    TRADE_WINDOW_HEIGHT = 320
    MAX_TRADE_ITEMS = 10
    
    #--------------------------------------------------------------------------
    # * Variables del módulo
    #--------------------------------------------------------------------------
    @active_trade = nil
    @offered_items = []
    @offered_pokemon = []
    @offered_money = 0
    @initialized = false
    
    #--------------------------------------------------------------------------
    # * Inicializar sistema de comercio
    #--------------------------------------------------------------------------
    def self.initialize
      return if @initialized
      
      @active_trade = nil
      @offered_items = []
      @offered_pokemon = []
      @offered_money = 0
      @initialized = true
      
      # Extender clases necesarias
      extend_game_party
    end
    
    #--------------------------------------------------------------------------
    # * Extender Game_Party
    #--------------------------------------------------------------------------
    def self.extend_game_party
      class ::Game_Party
        alias rmxos_trade_initialize initialize
        def initialize
          rmxos_trade_initialize
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
    # * Iniciar comercio con otro jugador
    #--------------------------------------------------------------------------
    def self.start_trade(target_player)
      return false if @active_trade
      
      # Crear nueva sesión de comercio
      @active_trade = {
        target: target_player,
        status: :pending,
        my_confirmed: false,
        target_confirmed: false,
        my_items: [],
        my_pokemon: [],
        my_money: 0,
        target_items: [],
        target_pokemon: [],
        target_money: 0
      }
      
      # Enviar solicitud de comercio
      RMXOS::Network.send_trade_request(target_player) if defined?(RMXOS::Network) && RMXOS::Network.connected?
      
      return true
    end
    
    #--------------------------------------------------------------------------
    # * Aceptar solicitud de comercio
    #--------------------------------------------------------------------------
    def self.accept_trade(from_player)
      # Verificar si ya hay un comercio activo
      return false if @active_trade
      
      # Crear nueva sesión de comercio
      @active_trade = {
        target: from_player,
        status: :active,
        my_confirmed: false,
        target_confirmed: false,
        my_items: [],
        my_pokemon: [],
        my_money: 0,
        target_items: [],
        target_pokemon: [],
        target_money: 0
      }
      
      # Enviar aceptación de comercio
      RMXOS::Network.send_message(:trade_accept, {target: from_player}) if defined?(RMXOS::Network) && RMXOS::Network.connected?
      
      # Mostrar pantalla de comercio
      show_trade_screen
      
      return true
    end
    
    #--------------------------------------------------------------------------
    # * Rechazar solicitud de comercio
    #--------------------------------------------------------------------------
    def self.reject_trade(from_player)
      # Enviar rechazo de comercio
      RMXOS::Network.send_message(:trade_reject, {target: from_player}) if defined?(RMXOS::Network) && RMXOS::Network.connected?
      
      return true
    end
    
    #--------------------------------------------------------------------------
    # * Cancelar comercio activo
    #--------------------------------------------------------------------------
    def self.cancel_trade
      return false unless @active_trade
      
      # Enviar cancelación de comercio
      RMXOS::Network.send_message(:trade_cancel, {target: @active_trade[:target]}) if defined?(RMXOS::Network) && RMXOS::Network.connected?
      
      # Limpiar datos de comercio
      @active_trade = nil
      @offered_items = []
      @offered_pokemon = []
      @offered_money = 0
      
      # Notificar cancelación
      RMXOS::ChatSystem.add_message("", "Comercio cancelado.", :system) if defined?(RMXOS::ChatSystem)
      
      return true
    end
    
    #--------------------------------------------------------------------------
    # * Mostrar pantalla de comercio
    #--------------------------------------------------------------------------
    def self.show_trade_screen
      # Esta función se implementará cuando se integre con el sistema de escenas de Essentials
      # Debe crear una nueva escena para mostrar la interfaz de comercio
      
      # Por ahora, solo mostrar mensaje
      RMXOS::ChatSystem.add_message("", "Iniciando comercio con #{@active_trade[:target]}...", :system) if defined?(RMXOS::ChatSystem)
    end
    
    #--------------------------------------------------------------------------
    # * Añadir objeto a la oferta
    #--------------------------------------------------------------------------
    def self.add_item(item_id, amount = 1)
      return false unless @active_trade && @active_trade[:status] == :active
      return false if @active_trade[:my_confirmed]
      
      # Verificar si el jugador tiene el objeto
      return false unless $game_party.has_item?(item_id, amount)
      
      # Verificar si ya está en la lista
      existing_item = @active_trade[:my_items].find { |i| i[:id] == item_id }
      
      if existing_item
        existing_item[:amount] += amount
      else
        @active_trade[:my_items].push({id: item_id, amount: amount})
      end
      
      # Enviar actualización de comercio
      send_trade_update
      
      return true
    end
    
    #--------------------------------------------------------------------------
    # * Quitar objeto de la oferta
    #--------------------------------------------------------------------------
    def self.remove_item(item_id, amount = 1)
      return false unless @active_trade && @active_trade[:status] == :active
      return false if @active_trade[:my_confirmed]
      
      # Verificar si está en la lista
      existing_item = @active_trade[:my_items].find { |i| i[:id] == item_id }
      return false unless existing_item
      
      if existing_item[:amount] <= amount
        @active_trade[:my_items].delete(existing_item)
      else
        existing_item[:amount] -= amount
      end
      
      # Enviar actualización de comercio
      send_trade_update
      
      return true
    end
    
    #--------------------------------------------------------------------------
    # * Añadir Pokémon a la oferta
    #--------------------------------------------------------------------------
    def self.add_pokemon(pokemon_index)
      return false unless @active_trade && @active_trade[:status] == :active
      return false if @active_trade[:my_confirmed]
      
      # Verificar si el jugador tiene el Pokémon
      return false if pokemon_index < 0 || pokemon_index >= $game_party.actors.size
      
      # Verificar si ya está en la lista
      return false if @active_trade[:my_pokemon].include?(pokemon_index)
      
      # Añadir a la lista
      @active_trade[:my_pokemon].push(pokemon_index)
      
      # Enviar actualización de comercio
      send_trade_update
      
      return true
    end
    
    #--------------------------------------------------------------------------
    # * Quitar Pokémon de la oferta
    #--------------------------------------------------------------------------
    def self.remove_pokemon(pokemon_index)
      return false unless @active_trade && @active_trade[:status] == :active
      return false if @active_trade[:my_confirmed]
      
      # Verificar si está en la lista
      return false unless @active_trade[:my_pokemon].include?(pokemon_index)
      
      # Quitar de la lista
      @active_trade[:my_pokemon].delete(pokemon_index)
      
      # Enviar actualización de comercio
      send_trade_update
      
      return true
    end
    
    #--------------------------------------------------------------------------
    # * Establecer dinero ofrecido
    #--------------------------------------------------------------------------
    def self.set_money(amount)
      return false unless @active_trade && @active_trade[:status] == :active
      return false if @active_trade[:my_confirmed]
      
      # Verificar si el jugador tiene suficiente dinero
      return false if amount < 0 || amount > $game_party.gold
      
      # Establecer cantidad
      @active_trade[:my_money] = amount
      
      # Enviar actualización de comercio
      send_trade_update
      
      return true
    end
    
    #--------------------------------------------------------------------------
    # * Enviar actualización de comercio
    #--------------------------------------------------------------------------
    def self.send_trade_update
      return false unless @active_trade && defined?(RMXOS::Network) && RMXOS::Network.connected?
      
      RMXOS::Network.send_trade_update(
        @active_trade[:my_items],
        @active_trade[:my_pokemon],
        @active_trade[:my_money],
        @active_trade[:my_confirmed]
      )
      
      return true
    end
    
    #--------------------------------------------------------------------------
    # * Confirmar oferta
    #--------------------------------------------------------------------------
    def self.confirm_trade
      return false unless @active_trade && @active_trade[:status] == :active
      
      # Marcar como confirmado
      @active_trade[:my_confirmed] = true
      
      # Enviar confirmación de comercio
      send_trade_update
      
      # Verificar si ambos han confirmado
      if @active_trade[:my_confirmed] && @active_trade[:target_confirmed]
        complete_trade
      else
        RMXOS::ChatSystem.add_message("", "Has confirmado el comercio. Esperando confirmación de #{@active_trade[:target]}...", :system) if defined?(RMXOS::ChatSystem)
      end
      
      return true
    end
    
    #--------------------------------------------------------------------------
    # * Completar comercio
    #--------------------------------------------------------------------------
    def self.complete_trade
      return false unless @active_trade && 
                         @active_trade[:status] == :active &&
                         @active_trade[:my_confirmed] && 
                         @active_trade[:target_confirmed]
      
      # Procesar intercambio de objetos
      process_item_exchange
      
      # Procesar intercambio de Pokémon
      process_pokemon_exchange
      
      # Procesar intercambio de dinero
      process_money_exchange
      
      # Notificar completado
      RMXOS::ChatSystem.add_message("", "¡Comercio completado con éxito!", :system) if defined?(RMXOS::ChatSystem)
      
      # Limpiar datos de comercio
      @active_trade = nil
      @offered_items = []
      @offered_pokemon = []
      @offered_money = 0
      
      return true
    end
    
    #--------------------------------------------------------------------------
    # * Procesar intercambio de objetos
    #--------------------------------------------------------------------------
    def self.process_item_exchange
      # Esta función se implementará cuando se integre con el sistema de inventario de Essentials
      # Debe quitar los objetos ofrecidos y añadir los objetos recibidos
    end
    
    #--------------------------------------------------------------------------
    # * Procesar intercambio de Pokémon
    #--------------------------------------------------------------------------
    def self.process_pokemon_exchange
      # Esta función se implementará cuando se integre con el sistema de Pokémon de Essentials
      # Debe quitar los Pokémon ofrecidos y añadir los Pokémon recibidos
    end
    
    #--------------------------------------------------------------------------
    # * Procesar intercambio de dinero
    #--------------------------------------------------------------------------
    def self.process_money_exchange
      # Esta función se implementará cuando se integre con el sistema de economía de Essentials
      # Debe quitar el dinero ofrecido y añadir el dinero recibido
      if @active_trade[:my_money] > 0
        $game_party.lose_gold(@active_trade[:my_money])
      end
      
      if @active_trade[:target_money] > 0
        $game_party.gain_gold(@active_trade[:target_money])
      end
    end
    
    #--------------------------------------------------------------------------
    # * Actualizar datos de comercio desde el servidor
    #--------------------------------------------------------------------------
    def self.update_trade_data(trade_data)
      return false unless @active_trade
      
      # Actualizar datos del comercio
      @active_trade[:target_items] = trade_data[:items] || []
      @active_trade[:target_pokemon] = trade_data[:pokemon] || []
      @active_trade[:target_money] = trade_data[:money] || 0
      @active_trade[:target_confirmed] = trade_data[:confirmed] || false
      
      # Verificar si ambos han confirmado
      if @active_trade[:my_confirmed] && @active_trade[:target_confirmed]
        complete_trade
      end
      
      return true
    end
  end
end
