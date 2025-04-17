#==============================================================================
# ** RMXOS Chat System for Pokémon EBDX
#------------------------------------------------------------------------------
# Este script implementa el sistema de chat para la integración multiplayer
# Permite comunicación entre jugadores a través de chat global y privado
#==============================================================================

module RMXOS
  module ChatSystem
    #--------------------------------------------------------------------------
    # * Constantes
    #--------------------------------------------------------------------------
    CHAT_WINDOW_WIDTH = 400
    CHAT_WINDOW_HEIGHT = 160
    CHAT_INPUT_HEIGHT = 24
    CHAT_HISTORY_SIZE = 100
    
    #--------------------------------------------------------------------------
    # * Variables del módulo
    #--------------------------------------------------------------------------
    @chat_visible = false
    @chat_active = false
    @chat_history = []
    @chat_input = ""
    @chat_scroll = 0
    @initialized = false
    @chat_window = nil
    @chat_input_window = nil
    
    #--------------------------------------------------------------------------
    # * Inicializar sistema de chat
    #--------------------------------------------------------------------------
    def self.initialize
      return if @initialized
      
      @chat_visible = false
      @chat_active = false
      @chat_history = []
      @chat_input = ""
      @chat_scroll = 0
      @chat_window = nil
      @chat_input_window = nil
      @initialized = true
      
      # Registrar comandos de chat
      register_chat_commands
      
      # Extender Input para manejar teclas F5 y F6
      extend_input_module
    end
    
    #--------------------------------------------------------------------------
    # * Extender Input module
    #--------------------------------------------------------------------------
    def self.extend_input_module
      # Añadir soporte para teclas F5 y F6
      class << Input
        alias rmxos_chat_update update
        
        def update
          rmxos_chat_update
          
          # Verificar tecla F5 para mostrar/ocultar chat
          if trigger?(Input::F5) && $scene.is_a?(Scene_Map)
            RMXOS::ChatSystem.toggle_chat_visibility
          end
          
          # Verificar tecla F6 para activar/desactivar entrada de chat
          if trigger?(Input::F6) && $scene.is_a?(Scene_Map)
            RMXOS::ChatSystem.toggle_chat_active
          end
        end
      end
    end
    
    #--------------------------------------------------------------------------
    # * Registrar comandos de chat
    #--------------------------------------------------------------------------
    def self.register_chat_commands
      # Comandos básicos
      @chat_commands = {
        "help" => {
          description: "Muestra la lista de comandos disponibles",
          handler: method(:cmd_help)
        },
        "whisper" => {
          description: "Envía un mensaje privado a otro jugador: /whisper [nombre] [mensaje]",
          handler: method(:cmd_whisper),
          aliases: ["w", "msg", "pm"]
        },
        "online" => {
          description: "Muestra la lista de jugadores conectados",
          handler: method(:cmd_online),
          aliases: ["players"]
        },
        "trade" => {
          description: "Inicia un intercambio con otro jugador: /trade [nombre]",
          handler: method(:cmd_trade)
        },
        "battle" => {
          description: "Desafía a otro jugador a una batalla: /battle [nombre]",
          handler: method(:cmd_battle)
        }
      }
    end
    
    #--------------------------------------------------------------------------
    # * Actualizar sistema de chat
    #--------------------------------------------------------------------------
    def self.update
      return unless @initialized
      
      # Actualizar ventanas de chat si están visibles
      if @chat_visible
        update_chat_windows
      end
    end
    
    #--------------------------------------------------------------------------
    # * Actualizar ventanas de chat
    #--------------------------------------------------------------------------
    def self.update_chat_windows
      # Crear ventanas si no existen
      create_chat_windows if !@chat_window || !@chat_input_window
      
      # Actualizar ventanas
      @chat_window.update if @chat_window
      @chat_input_window.update if @chat_input_window
      
      # Procesar entrada si el chat está activo
      process_chat_input if @chat_active
    end
    
    #--------------------------------------------------------------------------
    # * Crear ventanas de chat
    #--------------------------------------------------------------------------
    def self.create_chat_windows
      # Crear ventana de historial de chat
      @chat_window = Window_Base.new(
        0, 
        Graphics.height - CHAT_WINDOW_HEIGHT - CHAT_INPUT_HEIGHT, 
        CHAT_WINDOW_WIDTH, 
        CHAT_WINDOW_HEIGHT
      )
      @chat_window.opacity = 200
      @chat_window.z = 9998
      
      # Crear ventana de entrada de chat
      @chat_input_window = Window_Base.new(
        0, 
        Graphics.height - CHAT_INPUT_HEIGHT, 
        CHAT_WINDOW_WIDTH, 
        CHAT_INPUT_HEIGHT
      )
      @chat_input_window.opacity = 200
      @chat_input_window.z = 9999
      
      # Actualizar contenido de las ventanas
      refresh_chat_windows
    end
    
    #--------------------------------------------------------------------------
    # * Actualizar contenido de las ventanas
    #--------------------------------------------------------------------------
    def self.refresh_chat_windows
      return unless @chat_window && @chat_input_window
      
      # Limpiar ventanas
      @chat_window.contents.clear
      @chat_input_window.contents.clear
      
      # Mostrar historial de chat
      visible_lines = [CHAT_WINDOW_HEIGHT / 24, @chat_history.size].min
      start_index = [@chat_history.size - visible_lines, 0].max
      
      visible_lines.times do |i|
        index = start_index + i
        if index < @chat_history.size
          @chat_window.contents.draw_text(
            4, i * 24, CHAT_WINDOW_WIDTH - 8, 24, 
            @chat_history[index]
          )
        end
      end
      
      # Mostrar entrada de chat
      @chat_input_window.contents.draw_text(
        4, 0, CHAT_WINDOW_WIDTH - 8, 24, 
        @chat_active ? "> #{@chat_input}" : "> Click F6 para chatear"
      )
    end
    
    #--------------------------------------------------------------------------
    # * Procesar entrada de chat
    #--------------------------------------------------------------------------
    def self.process_chat_input
      # Procesar teclas
      if Input.trigger?(Input::RETURN) && !@chat_input.empty?
        process_input(@chat_input)
        @chat_input = ""
        refresh_chat_windows
      elsif Input.trigger?(Input::BACKSPACE) && !@chat_input.empty?
        @chat_input = @chat_input[0...-1]
        refresh_chat_windows
      else
        # Capturar caracteres
        Input.text_input.each_char do |char|
          @chat_input += char if @chat_input.length < 100
        end
        refresh_chat_windows if Input.text_input.length > 0
      end
    end
    
    #--------------------------------------------------------------------------
    # * Mostrar/ocultar ventana de chat
    #--------------------------------------------------------------------------
    def self.toggle_chat_visibility
      @chat_visible = !@chat_visible
      
      if @chat_visible
        create_chat_windows if !@chat_window || !@chat_input_window
      else
        @chat_active = false
        dispose_chat_windows
      end
    end
    
    #--------------------------------------------------------------------------
    # * Eliminar ventanas de chat
    #--------------------------------------------------------------------------
    def self.dispose_chat_windows
      if @chat_window
        @chat_window.dispose
        @chat_window = nil
      end
      
      if @chat_input_window
        @chat_input_window.dispose
        @chat_input_window = nil
      end
    end
    
    #--------------------------------------------------------------------------
    # * Activar/desactivar entrada de chat
    #--------------------------------------------------------------------------
    def self.toggle_chat_active
      return unless @chat_visible
      
      @chat_active = !@chat_active
      refresh_chat_windows
    end
    
    #--------------------------------------------------------------------------
    # * Añadir mensaje al historial
    #--------------------------------------------------------------------------
    def self.add_message(sender, message, type = :normal)
      timestamp = Time.now.strftime("[%H:%M:%S]")
      
      case type
      when :normal
        formatted_message = "#{timestamp} #{sender}: #{message}"
      when :system
        formatted_message = "#{timestamp} [Sistema] #{message}"
      when :whisper
        formatted_message = "#{timestamp} [PM de #{sender}] #{message}"
      when :error
        formatted_message = "#{timestamp} [Error] #{message}"
      end
      
      @chat_history.push(formatted_message)
      # Limitar tamaño del historial
      @chat_history.shift if @chat_history.size > CHAT_HISTORY_SIZE
      
      # Actualizar ventana de chat si está visible
      refresh_chat_windows if @chat_visible
      
      # Mostrar burbuja de chat si es un mensaje de otro jugador
      show_chat_bubble(sender, message) if type == :normal && sender != $game_player.name
    end
    
    #--------------------------------------------------------------------------
    # * Mostrar burbuja de chat
    #--------------------------------------------------------------------------
    def self.show_chat_bubble(sender, message)
      # Buscar jugador en la lista de otros jugadores
      player_data = nil
      RMXOS::PlayerExtension.other_players.each do |id, data|
        if data[:name] == sender
          player_data = data
          break
        end
      end
      
      # Si encontramos al jugador y está en el mismo mapa, mostrar burbuja
      if player_data && player_data[:map_id] == $game_map.map_id
        # Implementar burbuja de chat
        # Esta función se expandirá en la implementación completa
      end
    end
    
    #--------------------------------------------------------------------------
    # * Procesar entrada de chat
    #--------------------------------------------------------------------------
    def self.process_input(input)
      return if input.empty?
      
      # Verificar si es un comando
      if input.start_with?("/")
        process_command(input[1..-1])
      else
        # Mensaje normal
        send_chat_message(input)
      end
    end
    
    #--------------------------------------------------------------------------
    # * Procesar comando de chat
    #--------------------------------------------------------------------------
    def self.process_command(command_text)
      args = command_text.split(" ")
      command = args.shift.downcase
      
      # Buscar comando
      cmd_info = nil
      @chat_commands.each do |cmd_name, info|
        if cmd_name == command || (info[:aliases] && info[:aliases].include?(command))
          cmd_info = info
          break
        end
      end
      
      if cmd_info
        # Ejecutar comando
        cmd_info[:handler].call(args)
      else
        # Comando desconocido
        add_message("", "Comando desconocido. Usa /help para ver la lista de comandos.", :error)
      end
    end
    
    #--------------------------------------------------------------------------
    # * Enviar mensaje de chat
    #--------------------------------------------------------------------------
    def self.send_chat_message(message)
      # Añadir mensaje al historial local
      add_message($game_player.name, message, :normal)
      
      # Enviar mensaje al servidor
      RMXOS::Network.send_chat_message(message) if defined?(RMXOS::Network) && RMXOS::Network.connected?
    end
    
    #--------------------------------------------------------------------------
    # * Comando: help
    #--------------------------------------------------------------------------
    def self.cmd_help(args)
      add_message("", "Comandos disponibles:", :system)
      @chat_commands.each do |cmd_name, info|
        add_message("", "/#{cmd_name} - #{info[:description]}", :system)
      end
    end
    
    #--------------------------------------------------------------------------
    # * Comando: whisper
    #--------------------------------------------------------------------------
    def self.cmd_whisper(args)
      if args.size < 2
        add_message("", "Uso: /whisper [nombre] [mensaje]", :error)
        return
      end
      
      target = args.shift
      message = args.join(" ")
      
      # Enviar mensaje privado al servidor
      RMXOS::Network.send_chat_message(message, target) if defined?(RMXOS::Network) && RMXOS::Network.connected?
      
      # Mostrar localmente
      add_message("", "Mensaje enviado a #{target}: #{message}", :whisper)
    end
    
    #--------------------------------------------------------------------------
    # * Comando: online
    #--------------------------------------------------------------------------
    def self.cmd_online(args)
      if defined?(RMXOS::Network) && RMXOS::Network.connected?
        # Solicitar lista de jugadores al servidor
        RMXOS::Network.send_message(:request_player_list)
        add_message("", "Solicitando lista de jugadores...", :system)
      else
        add_message("", "No estás conectado al servidor.", :error)
      end
    end
    
    #--------------------------------------------------------------------------
    # * Comando: trade
    #--------------------------------------------------------------------------
    def self.cmd_trade(args)
      if args.size < 1
        add_message("", "Uso: /trade [nombre]", :error)
        return
      end
      
      target = args.shift
      
      if defined?(RMXOS::Network) && RMXOS::Network.connected?
        # Enviar solicitud de comercio
        RMXOS::Network.send_trade_request(target)
        add_message("", "Solicitud de intercambio enviada a #{target}.", :system)
      else
        add_message("", "No estás conectado al servidor.", :error)
      end
    end
    
    #--------------------------------------------------------------------------
    # * Comando: battle
    #--------------------------------------------------------------------------
    def self.cmd_battle(args)
      if args.size < 1
        add_message("", "Uso: /battle [nombre]", :error)
        return
      end
      
      target = args.shift
      
      if defined?(RMXOS::Network) && RMXOS::Network.connected?
        # Enviar solicitud de batalla
        RMXOS::Network.send_battle_request(target)
        add_message("", "Desafío de batalla enviado a #{target}.", :system)
      else
        add_message("", "No estás conectado al servidor.", :error)
      end
    end
  end
end
