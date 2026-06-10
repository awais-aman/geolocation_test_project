# frozen_string_literal: true

max_threads_count = ENV.fetch("PUMA_MAX_THREADS", 5)
min_threads_count = ENV.fetch("PUMA_MIN_THREADS", max_threads_count)
threads min_threads_count, max_threads_count

bind "tcp://0.0.0.0:#{ENV.fetch('PORT', 3000)}"
environment ENV.fetch("RACK_ENV", "development")
