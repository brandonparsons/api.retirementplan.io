  desc "Load efficient frontiers file"
  task efficient_frontiers: :environment do

    previous_level_AR = ActiveRecord::Base.logger.level
    count = 0

    begin
      # Make sure not to generate the long log outputs when updating these
      # attributes.  Slows stuff down
      ActiveRecord::Base.logger.level = Logger::ERROR

      securities = Security.all.map(&:ticker)
      threads = []

      threads << Thread.new do

        ActiveRecord::Base.transaction do
          # Single asset portfolios
          securities.each do |ticker|
            allowable_securities = [ticker]

            e           = EfficientFrontier.new
            allocation  = {ticker => 1.0}
            portfolio   = Portfolio.with_weights(allocation)
            portfolio   = Portfolio.create!(weights: allocation) unless portfolio
            e.portfolios << portfolio
            e.save!

            count += 1
          end

          # Two asset portfolio
          combinations = securities.combination(2).to_a
          combinations.each do |combo|
            e = EfficientFrontier.new

            [ [0.0, 1.0], [0.1,0.9], [0.2, 0.8], [0.3, 0.7], [0.4,0.6], [0.5,0.5], [0.6, 0.4], [0.7, 0.3], [0.8, 0.2], [0.9, 0.1], [1.0, 0.0]   ].each do |weights|
              allocation = Hash[combo.zip(weights)]

              portfolio = Portfolio.with_weights(allocation)
              portfolio = Portfolio.create!(weights: allocation ) unless portfolio
              e.portfolios << portfolio
              count += 1
              puts "Created #{count} portfolios" if count%100 == 0
            end

            e.save!
          end
        end # DB transaction

      end # thread


      # FIXME: is there a way to create the EfficientFrontier before the loop, add portfolios (e << port) and then save at the end, similar to what you've done above?

      puts "SKIPPING 4+ EFFICIENT FRONTIERS UNTIL YOU GET SORTED OUT."
      # 3+ asset portfolios
      # (3..securities.length).each do |number_of_assets|
      #   threads << Thread.new do

      #     puts "Seeding efficient frontier for #{number_of_assets} assets."
      #     load_file = File.join(Rails.root, "db", "data", "efficient_frontiers", "#{number_of_assets}_asset_eff_front.csv")

      #     tickers = []

      #     ActiveRecord::Base.transaction do

      #       CSV.foreach(load_file) do |row|
      #         if row[0] =~ /^portfolio/i
      #           # i.e. we are on a header row.  Typical arrangement: "Portfolio ID,TSX,VFINX,NAESX"
      #           number_of_tickers = row.length - 1

      #           # Assign rather than pop, so that the row variable doesn't get banged.  Might help for later
      #           number_of_tickers.times {|i| tickers[i] = row[i + 1]}
      #         else
      #           # i.e. we are not on a header row.  Typical arrangement : "1 (is ID),0.574767376,0.425232611,0"
      #           allocation = {}
      #           tickers.each_with_index { |ticker, index| allocation[ticker] = row[index+1].to_d }

      #           port = Portfolio.with_weights(allocation)
      #           begin
      #             unless port
      #               port = Portfolio.create!(weights: allocation )
      #               count += 1
      #               puts "Created #{count} portfolios" if count%100 == 0
      #             end
      #           rescue => e
      #             puts allocation.inspect
      #             puts e.inspect
      #             puts row.inspect
      #             raise "Portfolio didn't save.... something went wrong (didn't sum to 1.0?)"
      #           end

      #           frontier = EfficientFrontier.with_allowable_securities(tickers) || EfficientFrontier.new
      #           frontier.portfolios << port
      #           frontier.save!
      #         end
      #       end

      #     end # Database transaction

      #     puts "Complete efficient frontier for #{number_of_assets} assets..."

      #   end # thread
      # end # 3..18 loop

      threads.each {|th| th.join}
    ensure
      ActiveRecord::Base.logger.level = previous_level_AR
    end
  end # efficient_frontiers



################


  desc "Removes portfolios that for some reason are dominated, but got onto EF."
  task cull_portfolios: :environment do
    puts "Culling portfolios..."
    count = 0
    EfficientFrontier.all.each do |frontier|
      portfolios = frontier.portfolios

      last_return = 0.0
      (portfolios.by_volatility).each_with_index do |portfolio, index|
        if index == 0
          last_return = portfolio.expected_return
          next
        else
          if portfolio.expected_return < last_return
            portfolio.destroy
            count += 1
          else
            last_return = portfolio.expected_return
          end
        end
      end
    end
    puts "Total culled portfolios: #{count}"
  end # cull ports
