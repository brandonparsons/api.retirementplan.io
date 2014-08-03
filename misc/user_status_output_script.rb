all_users = Set.new(User.all);
puts "All Users: #{all_users.count}"

#######

users_without_questionnaires = all_users.select{|user| !user.has_completed_questionnaire?};
puts "Without questionnaires: #{users_without_questionnaires.count}"

remaining_users = all_users.difference(Set.new(users_without_questionnaires));

########

users_without_portfolios = remaining_users.select{|user| !user.has_selected_portfolio?};
puts "Without portfolios: #{users_without_portfolios.count}"

remaining_users = remaining_users.difference(Set.new(users_without_portfolios));

########

users_without_expenses = remaining_users.select{|user| !user.has_selected_expenses?};
puts "Without expenses: #{users_without_expenses.count}"

remaining_users = remaining_users.difference(Set.new(users_without_expenses));

########

users_without_simulations = remaining_users.select{|user| !user.has_completed_simulation?};
puts "Without simulations: #{users_without_simulations.count}"

remaining_users = remaining_users.difference(Set.new(users_without_simulations));

########

users_without_etfs = remaining_users.select{|user| !user.has_selected_etfs?};
puts "Without ETFs: #{users_without_etfs.count}"

remaining_users = remaining_users.difference(Set.new(users_without_etfs));

########

users_without_tracked_portfolios = remaining_users.select{|user| !user.has_setup_tracked_portfolio?};
puts "Without tracked portfolios: #{users_without_tracked_portfolios.count}"

remaining_users = remaining_users.difference(Set.new(users_without_tracked_portfolios));

########
