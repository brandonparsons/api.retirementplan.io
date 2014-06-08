if Rails.env.development?
  me = RegularUser.create! name: "Brandon", email: "parsons.brandon@gmail.com", password: 'asdfasdf', password_confirmation: 'asdfasdf'
  me.admin = true
  me.confirm!

  RegularUser.create! name: "Bob", email: 'bob@what.com', password: 'asdfasdf', password_confirmation: 'asdfasdf'

  Questionnaire.create({ user_id: me.id,
                             age: 29,
                             sex: 1,
                       no_people: 2,
                 real_estate_val: 5,
                   saving_reason: 0,
             investment_timeline: 0,
      investment_timeline_length: 1,
             economy_performance: 0,
                  financial_risk: 0,
                     credit_card: 1,
                         pension: 2,
                     inheritance: 4,
                        bequeath: 0,
                          degree: 3,
                            loan: 0,
             forseeable_expenses: 0,
                         married: 1,
                  emergency_fund: 2,
                       job_title: 1,
           investment_experience: 3
  })
end

Rake::Task["load_data"].invoke

$redis.set $SIMULATION_COUNT_KEY, 0
