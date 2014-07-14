Sidekiq::Client.push({
  'class' => EfficientFrontierBuilder,
  'queue' => 'cache',
  'args'  => [random_tickers]
})
