module JusticeGovSk
  class Persistor
    include Core::Persistor

    def persist(instance)
      super

      # TODO refactor this fix
      Hearing.find(instance.id).save! if instance.is_a? Hearing

      # TODO rm debug
      #if instance.is_a? Hearing
      #  a = instance
      #  b = Hearing.find(instance.id)
      #
      #  puts "EQL #{a == b}"
      #  puts "CLS #{a.class} #{b.class}"
      #  puts a.inspect
      #  puts b.inspect
      #
      #  a.save!
      #  #b.save!
      #end

      # TODO rm
      #super
      #
      #if instance.respond_to? :update_index
      #  print "Updating index #{identify instance} ... "
      #
      #  instance.update_index
      #
      #  puts "done (#{identify instance})"
      #end
      #
      #instance
    end
  end
end
