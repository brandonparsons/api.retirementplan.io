module Finance
  module MortalityTable

    extend self

    def generate_male_lifetime(current_age=0)
      generate_lifetime(:male_prob, current_age)
    end

    def generate_female_lifetime(current_age=0)
      generate_lifetime(:female_prob, current_age)
    end

    def generate_lifetimes(amount=200)
      lifetimes = []
      amount.times do |n|
        lifetimes.push({
          male:   generate_male_lifetime,
          female: generate_female_lifetime
        })
      end
      return lifetimes
    end

    private

    def generate_lifetime(hash_key, current_age)
      # If a current age is passed, need to make sure that those entries are all
      # true.  i.e. If they are currently 43, set the first 43 entries to true
      # and THEN start checking for alive or not.

      lifetime  = []
      alive     = true
      at_age    = 0

      probabilities.each_pair do |key, probabilities_hash|
        if !alive
          lifetime << false
        else
          # We were alive coming into this year

          if at_age < current_age
            # Must return -alive- for this case - see explanation above.
            lifetime << true
          else
            prob = probabilities_hash[hash_key]
            if rand > prob # alive
              lifetime << true
            else # dies
              lifetime << false
              alive = false
            end
          end
        end

        at_age += 1
      end

      return lifetime
    end

    def male_dies_at?(age)
      age_key = "age_#{age.to_i}".to_sym
      prob    = probabilities[age_key][:male_prob]
      rand > prob ? false : true
    end

    def female_dies_at?(age)
      age_key = "age_#{age.to_i}".to_sym
      prob    = probabilities[age_key][:female_prob]
      rand > prob ? false : true
    end

    def probabilities
      {
        age_0:   { male_prob: 0.007379, female_prob: 0.006096},
        age_1:   { male_prob: 0.000494, female_prob: 0.000434},
        age_2:   { male_prob: 0.000317, female_prob: 0.000256},
        age_3:   { male_prob: 0.000241, female_prob: 0.000192},
        age_4:   { male_prob: 0.000200, female_prob: 0.000148},
        age_5:   { male_prob: 0.000179, female_prob: 0.000136},
        age_6:   { male_prob: 0.000166, female_prob: 0.000128},
        age_7:   { male_prob: 0.000152, female_prob: 0.000122},
        age_8:   { male_prob: 0.000133, female_prob: 0.000115},
        age_9:   { male_prob: 0.000108, female_prob: 0.000106},
        age_10:  { male_prob: 8.90e-05, female_prob: 0.000100},
        age_11:  { male_prob: 9.40e-05, female_prob: 0.000102},
        age_12:  { male_prob: 0.000145, female_prob: 0.000120},
        age_13:  { male_prob: 0.000252, female_prob: 0.000157},
        age_14:  { male_prob: 0.000401, female_prob: 0.000209},
        age_15:  { male_prob: 0.000563, female_prob: 0.000267},
        age_16:  { male_prob: 0.000719, female_prob: 0.000323},
        age_17:  { male_prob: 0.000873, female_prob: 0.000369},
        age_18:  { male_prob: 0.001017, female_prob: 0.000401},
        age_19:  { male_prob: 0.001148, female_prob: 0.000422},
        age_20:  { male_prob: 0.001285, female_prob: 0.000441},
        age_21:  { male_prob: 0.001412, female_prob: 0.000463},
        age_22:  { male_prob: 0.001493, female_prob: 0.000483},
        age_23:  { male_prob: 0.001513, female_prob: 0.000499},
        age_24:  { male_prob: 0.001487, female_prob: 0.000513},
        age_25:  { male_prob: 0.001446, female_prob: 0.000528},
        age_26:  { male_prob: 0.001412, female_prob: 0.000544},
        age_27:  { male_prob: 0.001389, female_prob: 0.000563},
        age_28:  { male_prob: 0.001388, female_prob: 0.000585},
        age_29:  { male_prob: 0.001405, female_prob: 0.000612},
        age_30:  { male_prob: 0.001428, female_prob: 0.000642},
        age_31:  { male_prob: 0.001453, female_prob: 0.000678},
        age_32:  { male_prob: 0.001487, female_prob: 0.000721},
        age_33:  { male_prob: 0.001529, female_prob: 0.000771},
        age_34:  { male_prob: 0.001584, female_prob: 0.000830},
        age_35:  { male_prob: 0.001651, female_prob: 0.000896},
        age_36:  { male_prob: 0.001737, female_prob: 0.000971},
        age_37:  { male_prob: 0.001845, female_prob: 0.001056},
        age_38:  { male_prob: 0.001979, female_prob: 0.001153},
        age_39:  { male_prob: 0.002140, female_prob: 0.001260},
        age_40:  { male_prob: 0.002323, female_prob: 0.001377},
        age_41:  { male_prob: 0.002526, female_prob: 0.001506},
        age_42:  { male_prob: 0.002750, female_prob: 0.001650},
        age_43:  { male_prob: 0.002993, female_prob: 0.001810},
        age_44:  { male_prob: 0.003257, female_prob: 0.001985},
        age_45:  { male_prob: 0.003543, female_prob: 0.002174},
        age_46:  { male_prob: 0.003856, female_prob: 0.002375},
        age_47:  { male_prob: 0.004208, female_prob: 0.002582},
        age_48:  { male_prob: 0.004603, female_prob: 0.002794},
        age_49:  { male_prob: 0.005037, female_prob: 0.003012},
        age_50:  { male_prob: 0.005512, female_prob: 0.003255},
        age_51:  { male_prob: 0.006008, female_prob: 0.003517},
        age_52:  { male_prob: 0.006500, female_prob: 0.003782},
        age_53:  { male_prob: 0.006977, female_prob: 0.004045},
        age_54:  { male_prob: 0.007456, female_prob: 0.004318},
        age_55:  { male_prob: 0.007975, female_prob: 0.004619},
        age_56:  { male_prob: 0.008551, female_prob: 0.004965},
        age_57:  { male_prob: 0.009174, female_prob: 0.005366},
        age_58:  { male_prob: 0.009848, female_prob: 0.005830},
        age_59:  { male_prob: 0.010584, female_prob: 0.006358},
        age_60:  { male_prob: 0.011407, female_prob: 0.006961},
        age_61:  { male_prob: 0.012315, female_prob: 0.007624},
        age_62:  { male_prob: 0.013289, female_prob: 0.008322},
        age_63:  { male_prob: 0.014326, female_prob: 0.009046},
        age_64:  { male_prob: 0.015453, female_prob: 0.009822},
        age_65:  { male_prob: 0.016723, female_prob: 0.010698},
        age_66:  { male_prob: 0.018154, female_prob: 0.011702},
        age_67:  { male_prob: 0.019732, female_prob: 0.012832},
        age_68:  { male_prob: 0.021468, female_prob: 0.014103},
        age_69:  { male_prob: 0.023387, female_prob: 0.015526},
        age_70:  { male_prob: 0.025579, female_prob: 0.017163},
        age_71:  { male_prob: 0.028032, female_prob: 0.018987},
        age_72:  { male_prob: 0.030665, female_prob: 0.020922},
        age_73:  { male_prob: 0.033467, female_prob: 0.022951},
        age_74:  { male_prob: 0.036519, female_prob: 0.025147},
        age_75:  { male_prob: 0.040010, female_prob: 0.027709},
        age_76:  { male_prob: 0.043987, female_prob: 0.030659},
        age_77:  { male_prob: 0.048359, female_prob: 0.033861},
        age_78:  { male_prob: 0.053140, female_prob: 0.037311},
        age_79:  { male_prob: 0.058434, female_prob: 0.041132},
        age_80:  { male_prob: 0.064457, female_prob: 0.045561},
        age_81:  { male_prob: 0.071259, female_prob: 0.050698},
        age_82:  { male_prob: 0.078741, female_prob: 0.056486},
        age_83:  { male_prob: 0.086923, female_prob: 0.062971},
        age_84:  { male_prob: 0.095935, female_prob: 0.070259},
        age_85:  { male_prob: 0.105937, female_prob: 0.078471},
        age_86:  { male_prob: 0.117063, female_prob: 0.087713},
        age_87:  { male_prob: 0.129407, female_prob: 0.098064},
        age_88:  { male_prob: 0.143015, female_prob: 0.109578},
        age_89:  { male_prob: 0.157889, female_prob: 0.122283},
        age_90:  { male_prob: 0.174013, female_prob: 0.136190},
        age_91:  { male_prob: 0.191354, female_prob: 0.151300},
        age_92:  { male_prob: 0.209867, female_prob: 0.167602},
        age_93:  { male_prob: 0.229502, female_prob: 0.185078},
        age_94:  { male_prob: 0.250198, female_prob: 0.203700},
        age_95:  { male_prob: 0.270750, female_prob: 0.222541},
        age_96:  { male_prob: 0.290814, female_prob: 0.241317},
        age_97:  { male_prob: 0.310029, female_prob: 0.259716},
        age_98:  { male_prob: 0.328021, female_prob: 0.277409},
        age_99:  { male_prob: 0.344422, female_prob: 0.294054},
        age_100: { male_prob: 0.361644, female_prob: 0.311697},
        age_101: { male_prob: 0.379726, female_prob: 0.330399},
        age_102: { male_prob: 0.398712, female_prob: 0.350223},
        age_103: { male_prob: 0.418648, female_prob: 0.371236},
        age_104: { male_prob: 0.439580, female_prob: 0.393510},
        age_105: { male_prob: 0.461559, female_prob: 0.417121},
        age_106: { male_prob: 0.484637, female_prob: 0.442148},
        age_107: { male_prob: 0.508869, female_prob: 0.468677},
        age_108: { male_prob: 0.534312, female_prob: 0.496798},
        age_109: { male_prob: 0.561028, female_prob: 0.526605},
        age_110: { male_prob: 0.589079, female_prob: 0.558202},
        age_111: { male_prob: 0.618533, female_prob: 0.591694},
        age_112: { male_prob: 0.649460, female_prob: 0.627196},
        age_113: { male_prob: 0.681933, female_prob: 0.664827},
        age_114: { male_prob: 0.716029, female_prob: 0.704717},
        age_115: { male_prob: 0.751831, female_prob: 0.747000},
        age_116: { male_prob: 0.789422, female_prob: 0.789422},
        age_117: { male_prob: 0.828894, female_prob: 0.828894},
        age_118: { male_prob: 0.870338, female_prob: 0.870338},
        age_119: { male_prob: 0.913855, female_prob: 0.913855},
        age_120: { male_prob: 1.000000, female_prob: 1.000000}
      }
    end

  end
end
