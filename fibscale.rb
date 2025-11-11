# frozen_string_literal: true

require 'logger'
require 'sinatra'
require 'sinatra/reloader' if development?

RubyVM::InstructionSequence.compile_option = {
  tailcall_optimization: true
}

colors = %w[success primary danger warning secondary info dark].freeze
worker = Integer(ARGV.shift || '0')

set :algorithms, %w[recursive iterative]
set :color, colors[worker % colors.length]
set :delay, Float(ENV.fetch('FIBSCALE_DELAY', '0'))
set :max_number, Integer(ENV.fetch('FIBSCALE_MAX', '10000'))
set :max_recursive_number, Integer(ENV.fetch('FIBSCALE_RECURSIVE_MAX', '40'))

set :environment, :production
set :bind, ENV.fetch('FIBSCALE_HOST', '0.0.0.0')
set :port, Integer(ENV.fetch('FIBSCALE_PORT', '3000'))

startup_logger = Logger.new($stdout)
startup_logger.info("Worker: #{worker} (color: #{settings.color})")
startup_logger.info("Max number: #{settings.max_number} (recursive: #{settings.max_recursive_number})")
startup_logger.info("Default delay: #{settings.delay}")

get '/' do
  delay = begin
    Float(params.fetch('delay', settings.delay))
  rescue StandardError
    0
  end
  if delay.negative?
    return respond(fib_number: 0, fib_algorithm: 'recursive', error: 'delay_negative',
                   error_message: 'Delay must be greater than or equal to zero.')
  end

  respond(fib_number: 0, fib_algorithm: 'recursive', delay: delay)
end

post '/' do
  fib_number = begin
    Integer(params['fib'])
  rescue StandardError
    false
  end
  fib_algorithm = params['algorithm'] || 'recursive'
  delay = Float(params.fetch('delay', settings.delay))

  if fib_number == false
    return respond(fib_number: fib_number, fib_algorithm: fib_algorithm, delay: delay, error: 'fib_not_an_integer',
                   error_message: 'Fibonacci number must be an integer.')
  elsif fib_number.negative?
    return respond(fib_number: fib_number, fib_algorithm: fib_algorithm, delay: delay, error: 'fib_negative',
                   error_message: 'Fibonacci number must be greater than or equal to zero.')
  elsif !settings.algorithms.include?(fib_algorithm)
    return respond(fib_number: fib_number, fib_algorithm: fib_algorithm, delay: delay, error: 'fib_algorithm_unknown',
                   error_message: "Fibonacci algorithm must be one of: #{settings.algorithms.join(', ')}.")
  elsif fib_algorithm == 'recursive' && fib_number > settings.max_recursive_number
    return respond(fib_number: fib_number, fib_algorithm: fib_algorithm, delay: delay, error: 'fib_recursive_max',
                   error_message: "Cannot compute fibonacci numbers beyond #{
                     settings.max_recursive_number
                   } with the recursive algorithm (it would be too slow).")
  elsif fib_number > settings.max_number
    return respond(fib_number: fib_number, fib_algorithm: fib_algorithm, delay: delay, error: 'fib_max',
                   error_message: "Cannot compute fibonacci numbers beyond #{settings.max_number}.")
  elsif delay.negative?
    return respond(fib_number: fib_number, fib_algorithm: fib_algorithm, delay: delay, error: 'delay_negative',
                   error_message: 'Delay must be greater than or equal to zero.')
  end

  logger.info("Computing fibonacci number #{fib_number} with the #{fib_algorithm} algorithm")

  starting = Process.clock_gettime(Process::CLOCK_MONOTONIC)

  fib_result = case fib_algorithm
               when 'recursive'
                 fib(fib_number)
               when 'iterative'
                 fib_iter(0, 1, fib_number)
               end

  sleep delay

  ending = Process.clock_gettime(Process::CLOCK_MONOTONIC)
  elapsed_time = ending - starting

  logger.info("Computed fibonacci number #{
    fib_number
  } with the #{fib_algorithm} algorithm in #{format('%.3f', elapsed_time)} seconds")

  respond(fib_number: fib_number, fib_result: fib_result, fib_algorithm: fib_algorithm, elapsed_time: elapsed_time,
          delay: delay)
end

helpers do
  def respond(
    fib_number:,
    fib_algorithm:,
    fib_result: nil,
    elapsed_time: nil,
    delay: nil,
    error: nil,
    error_message: nil
  )
    erb :index, locals: {
      fib_number: fib_number,
      fib_result: fib_result,
      next_fib_number: fib_result.nil? ? nil : fib_number + 1,
      fib_algorithm: fib_algorithm,
      elapsed_time: elapsed_time,
      delay: delay,
      error: error,
      error_message: error_message,
      color: settings.color
    }
  end

  def format_number(number)
    number.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse
  end

  def ordinalize(number)
    return "#{number}th" if number.between?(11, 13)

    case number % 10
    when 1
      "#{number}st"
    when 2
      "#{number}nd"
    when 3
      "#{number}rd"
    else
      "#{number}th"
    end
  end
end

def fib(number)
  raise ArgumentError, 'Number must be greater than or equal to zero' if number.negative?

  case number
  when 0
    0
  when 1
    1
  else
    fib(number - 2) + fib(number - 1)
  end
end

def fib_iter(first, second, number)
  raise ArgumentError, 'Number must be greater than or equal to zero' if number.negative?
  return first if number.zero?

  while number >= 1
    first, second = second, first + second
    number -= 1
  end

  first
end
