namespace :fixtures do
  namespace :db do
    desc "Drops, creates, migrates and loads seed data into the database"
    task rebuild: :environment do
      Rake::Task['db:drop'].invoke
      Rake::Task['db:create'].invoke
      Rake::Task['db:migrate'].invoke
      Rake::Task['db:seed'].invoke
    end
    
    desc "Setups small database with production data (drops existing database)"
    task setup: :environment do
      Rake::Task['fixtures:db:rebuild'].invoke
      Rake::Task['fixtures:db:seed'].invoke
      Rake::Task['fixtures:db:hearings'].invoke
      Rake::Task['fixtures:db:decrees'].invoke
    end

    desc "Seeds database with necessary data"
    task seed: :environment do
      Rake::Task['crawl:courts'].invoke
      Rake::Task['crawl:judges'].invoke
      
      Rake::Task['process:paragraphs'].invoke
    end
    
    desc "Crawls small amount hearings"
    task hearings: :environment do
      Rake::Task['crawl:hearings:civil'].invoke    1, 20
      Rake::Task['crawl:hearings:criminal'].invoke 1, 20
      Rake::Task['crawl:hearings:special'].invoke  1, 20
    end

    desc "Crawls small amount of decrees"
    task :decrees, [:reverse] => :environment do |_, args|
      args.with_defaults reverse: false
      
      codes = DecreeForm.order(:code).all
      
      raise "No decree form codes found." if codes.empty?
      
      codes.reverse! if args[:reverse]
      
      codes.each do |form|
        Rake::Task['crawl:decrees'].reenable
        Rake::Task['crawl:decrees'].invoke form.code, 1, 4
      end
    end
    
    desc "Prints basic statistics about the database"
    task stat: :environment do
      puts "Courts: #{Court.count}"
      puts "Judges: #{Judge.count}"
      puts
      puts "Paragraphs: #{Paragraph.count}"
      puts
      puts "Hearings civil:    #{CivilHearing.count}"
      puts "Hearings criminal: #{CriminalHearing.count}"
      puts "Hearings special:  #{SpecialHearing.count}"
      puts
      
      DecreeForm.order(:code).all.each do |form|
        puts "Decrees form #{form.code}: #{Decree.where('decree_form_id = ?', form.id).count}"
      end
      
      puts
      puts "Court expenses:   #{CourtExpense.count}"
      puts "Court statistics: #{CourtStatisticalSummary.count}"
      puts
      puts "Judge desigantions: #{JudgeDesignation.count}"
      puts "Judge statistics:   #{JudgeStatisticalSummary.count}"
    end
  end

  namespace :export do
    desc "Export judge property declarations and some other related data into CSVs" 
    task :judge_property_declarations, [:path] => :environment do |_, args|
      include Core::Pluralize
      include Core::Output
      
      path = args[:path] || 'tmp'
      
      FileUtils.mkpath path
      
      f  = File.open File.join(path, 'judge-property-declarations.csv'), 'w'
      fi = File.open File.join(path, 'judge-property-declarations-incomes.csv'), 'w'
      fp = File.open File.join(path, 'judge-property-declarations-persons.csv'), 'w'
      fs = File.open File.join(path, 'judge-property-declarations-statements.csv'), 'w'
      
      data  = [:uri, :judge_name]
      data += [:court_name, :year]
      data += [:category]
      data += [:description]
      data += [:cost, :share_size, :acquisition_date]
      data += [:acquisition_reason, :ownership_form, :change]
      
      f.write(data.join("\t") + "\n")
      
      Judge.order(:name).all.each do |judge|
        print "Exporting declaration properties for judge #{judge.name} ... "
        
        judge.property_declarations.each do |declaration|
          declaration.lists.each do |list|
            list.items.each do |property|
              data  = [declaration.uri, judge.name]
              data += [declaration.court.name, declaration.year]
              data += [list.category.value]
              data += [property.description]
              data += [property.cost, property.share_size, property.acquisition_date]
              data << (property.acquisition_reason.nil? ? '' : property.acquisition_reason.value)
              data << (property.ownership_form.nil?     ? '' : property.ownership_form.value)
              data << (property.change.nil?             ? '' : property.change.value)
              
              f.write(data.join("\t") + "\n")
            end
          end

          declaration.incomes.each do |income|
            data  = [declaration.uri, judge.name]
            data += [declaration.court.name, declaration.year]
            data += [income.description, income.value]            
            
            fi.write(data.join("\t") + "\n") 
          end

          declaration.related_persons.each do |person|
            data  = [declaration.uri, judge.name]
            data += [declaration.court.name, declaration.year]
            data += [person.name, person.institution, person.function]            
            
            fp.write(data.join("\t") + "\n") 
          end
          
          declaration.statements.each do |statement|
            data  = [declaration.uri, judge.name]
            data += [declaration.court.name, declaration.year]
            data += [statement.value]            
            
            fs.write(data.join("\t") + "\n") 
          end
        end
        
        puts "done"
      end
      
      f.close
      
      fi.close
      fp.close
      fs.close
    end
  end
  
  namespace :decrees do
    desc "Extract missing images of decree documents"
    task :extract_images, [:override] => :environment do |_, args|
      include Core::Pluralize
      include Core::Output
      
      args.with_defaults override: false
      
      document_storage = JusticeGovSk::Storage::DecreeDocument.instance
      image_storage    = JusticeGovSk::Storage::DecreeImage.instance
      
      document_storage.batch do |entries, bucket|
        print "Running image extraction for bucket #{bucket}, "
        print "#{pluralize entries.size, 'document'}, "
        puts  "#{args[:override] ? 'overriding' : 'skipping'} already extracted."
        
        n = 0
        
        entries.each do |entry|
          next unless args[:override] || !image_storage.contains?(entry)
         
          options = { output: image_storage.path(entry) }
          
          JusticeGovSk::Extractor::Image.extract document_storage.path(entry), options
          
          n += 1
        end
        
        puts "finished (#{pluralize n, 'document'} extracted)"
      end
    end
  end
end
