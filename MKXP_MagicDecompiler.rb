# MKXP_MagicDecompiler.rb
require 'zlib'
require 'fileutils'

DECOMPILE_DIR = "Data"
SOURCE_SCRIPTS = "Data/Scripts.rxdata"

module MagicDecompiler
  def self.conjure_spells!
    scripts = load_scripts
    create_backup
    decompile_with_precision(scripts)
    create_perfect_loader(scripts.size)
    rebuild_rxdata
    puts "¡HECHIZO COMPLETO! 🧙♂️✨"
  end

  def self.load_scripts
    File.open(SOURCE_SCRIPTS, 'rb') { |f| Marshal.load(f) }
  end

  def self.create_backup
    FileUtils.cp(SOURCE_SCRIPTS, "#{SOURCE_SCRIPTS}.backup#{Time.now.to_i}")
  end

  def self.decompile_with_precision(scripts)
    FileUtils.mkdir_p(DECOMPILE_DIR)
    
    scripts.each_with_index do |s, index|
      next unless s[2]
      
      script_number = "%03d" % (index + 1)
      script_name = s[1] ? s[1].gsub(/[^\w]/, '_') : "Script#{script_number}"
      filename = "#{script_number}_#{script_name}.rb"
      
      File.write("#{DECOMPILE_DIR}/#{filename}", Zlib::Inflate.inflate(s[2]))
    end
  end

  def self.create_perfect_loader(total_scripts)
    loader_code = <<~RUBY
      module RPG
        class Script
          def self.magic_load
            #{total_scripts}.times do |i|
              begin
                n = "%%03d" %% (i + 1)
                file = Dir["Data/#{n}_*.rb"].first
                next unless File.exist?(file)
                eval(File.read(file), TOPLEVEL_BINDING, file)
                puts "🪄 Cargado: \#{file}"
              rescue => e
                puts "🚨 Error en \#{n}: \#{e.message}"
              end
            end
          end
        end
      end
      RPG::Script.magic_load
    RUBY

    File.write("#{DECOMPILE_DIR}/000_MagicLoader.rb", loader_code)
  end

  def self.rebuild_rxdata
    loader = Zlib::Deflate.deflate(File.read("#{DECOMPILE_DIR}/000_MagicLoader.rb"))
    File.open(SOURCE_SCRIPTS, 'wb') { |f| Marshal.dump([[0, "Loader", loader, []]], f) }
  end
end

begin
  MagicDecompiler.conjure_spells!
  puts "\nESTRUCTURA FINAL:"
  puts "├─ Data/ 📂 (Todos tus scripts .rb)"
  puts "└─ PBS/ 📄 (Tus archivos .txt intactos)"
  puts "\n¡Edita los scripts en Data/ y el juego los cargará MÁGICAMENTE! ✨"
rescue => e
  puts "🔥 ¡HECHIZO FALLIDO!: #{e.message}"
end