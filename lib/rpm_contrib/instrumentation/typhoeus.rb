DependencyDetection.defer do
  @name = :typhoeus
  
  depends_on do
    defined?(::Typhoeus) and not ::NewRelic::Control.instance['disable_typhoeus']
  end
  
  executes do
    NewRelic::Agent.logger.debug 'Installing Typhoeus instrumentation'
  end
  
  executes do
    require 'uri'
    ::Typhoeus::Request.instance_eval do
      def get_with_newrelic_trace(*args, &block)
        uri = URI.parse(args.first)
        metrics = ["External/#{uri.host}/Typhoeus/GET","External/#{uri.host}/all"]
        if NewRelic::Agent::Instrumentation::MetricFrame.recording_web_transaction?
          metrics << "External/allWeb"
        else
          metrics << "External/allOther"
        end
        self.class.trace_execution_scoped metrics do
          get_without_newrelic_trace(*args, &block)
        end
      end
      alias get_without_newrelic_trace get
      alias get get_with_newrelic_trace
    end

    ::Curl::Multi.class_eval do
      # TODO: http
      def perform_with_newrelic_trace(*args, &block)
        metrics = ["External/Typhoeus::Multi"]
        if NewRelic::Agent::Instrumentation::MetricFrame.recording_web_transaction?
          metrics << "External/allWeb"
        else
          metrics << "External/allOther"
        end
        self.class.trace_execution_scoped metrics do
          perform_without_newrelic_trace(*args, &block)
        end
      end
      alias perform_without_newrelic_trace perform
      alias perform perform_with_newrelic_trace
    end
  end
end


