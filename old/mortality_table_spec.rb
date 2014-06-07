require 'spec_helper'

describe Finance::MortalityTable do

  it 'can generate a male lifetime' do
    expect { Finance::MortalityTable.generate_male_lifetime }.not_to raise_error
  end

  it 'can generate a female lifetime' do
    expect { Finance::MortalityTable.generate_female_lifetime }.not_to raise_error
  end

  it 'returns an array of boolean values, equal to length of mortality table' do
    lifetime = Finance::MortalityTable.generate_male_lifetime
    lifetime.is_a?(Array).should be_true
    lifetime.each { |element| ( element.is_a?(TrueClass) || element.is_a?(FalseClass) ).should be_true }
    lifetime.length.should eql( Finance::MortalityTable.send(:probabilities).length )
  end

  it 'generates random lifetimes - MAY FAIL IF CRAZY STATS' do
    first_lifetimes = []
    10.times do
      death_age = Finance::MortalityTable.generate_male_lifetime.index(false)
      first_lifetimes << death_age
    end

    second_lifetimes = []
    10.times do
      death_age = Finance::MortalityTable.generate_male_lifetime.index(false)
      second_lifetimes << death_age
    end

    first_lifetimes.should_not eql(second_lifetimes)
  end

  it 'only goes true to false - does not switch back' do
    200.times do
      lifetime = Finance::MortalityTable.generate_male_lifetime

      switches_to_false_at = lifetime.index(false)
      last_true = lifetime.rindex(true) || 0

      if switches_to_false_at == 0
        # They died on the first shot
        expect(last_true).to eql(0)
      else
        (switches_to_false_at > last_true).should be_true
      end
    end
    200.times do
      lifetime = Finance::MortalityTable.generate_female_lifetime

      switches_to_false_at = lifetime.index(false)
      last_true = lifetime.rindex(true) || 0

      if switches_to_false_at == 0
        # They died on the first shot
        expect(last_true).to eql(0)
      else
        (switches_to_false_at > last_true).should be_true
      end
    end
  end

  it 'always returns -alive- up to current_age if passed in' do
    death_ages = []
    25.times do
      death_age = Finance::MortalityTable.generate_male_lifetime().index(false)
      death_ages << death_age
    end
    expect(death_ages.min).to be >= 0

    death_ages = []
    15.times do
      death_age = Finance::MortalityTable.generate_male_lifetime(115).index(false)
      death_ages << death_age
    end
    expect(death_ages.min).to be >= 115

  end

end
