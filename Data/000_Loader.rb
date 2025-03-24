module RPG
  class Script
    def self.load_ordered
      (402).times do |i|
        n = "%%03d" %% (i + 1)
        Dir["Data/#{n}_*.rb"].each { |f| eval(File.read(f), TOPLEVEL_BINDING, f) }
      end
    end
  end
end
RPG::Script.load_ordered
