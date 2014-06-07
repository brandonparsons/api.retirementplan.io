checkValidityBetween: (validValues, property) ->
  integerized = parseInt(property)
  validValues.indexOf(integerized) >= 0

sexValid: Ember.computed ->
  @checkValidityBetween [0,1], @get('sex')
.property('sex')

realEstateValValid: Ember.computed ->
  @checkValidityBetween [0,1,2,3,4,5,6], @get('realEstateVal')
.property('realEstateVal')

savingReasonValid: Ember.computed ->
  @checkValidityBetween [0,1], @get('savingReason')
.property('savingReason')

investmentTimelineValid: Ember.computed ->
  @checkValidityBetween [0,1], @get('investmentTimeline')
.property('investmentTimeline')

investmentTimelineLengthValid: Ember.computed ->
  @checkValidityBetween [0,1], @get('investmentTimelineLength')
.property('investmentTimelineLength')

economyPerformanceValid: Ember.computed ->
  @checkValidityBetween [0,1], @get('economyPerformance')
.property('economyPerformance')

financialRiskValid: Ember.computed ->
  @checkValidityBetween [0,1], @get('financialRisk')
.property('financialRisk')

creditCardValid: Ember.computed ->
  @checkValidityBetween [0,1], @get('creditCard')
.property('creditCard')

pensionValid: Ember.computed ->
  @checkValidityBetween [0,1,2,3,4,5,6], @get('pension')
.property('pension')

inheritanceValid: Ember.computed ->
  @checkValidityBetween [0,1,2,3,4,5,6], @get('inheritance')
.property('inheritance')

bequeathValid: Ember.computed ->
  @checkValidityBetween [0,1], @get('bequeath')
.property('bequeath')

degreeValid: Ember.computed ->
  @checkValidityBetween [1,2,3,4,5], @get('degree')
.property('degree')

loanValid: Ember.computed ->
  @checkValidityBetween [0,1], @get('loan')
.property('loan')

forseeableExpensesValid: Ember.computed ->
  @checkValidityBetween [0,1], @get('forseeableExpenses')
.property('forseeableExpenses')

marriedValid: Ember.computed ->
  @checkValidityBetween [0,1], @get('married')
.property('married')

emergencyFundValid: Ember.computed ->
  @checkValidityBetween [0,1,2,3,4,5,6], @get('emergencyFund')
.property('emergencyFund')

jobTitleValid: Ember.computed ->
  @checkValidityBetween [0,1,2], @get('jobTitle')
.property('jobTitle')
