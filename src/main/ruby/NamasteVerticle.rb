require 'vertx-circuit-breaker/circuit_breaker'
event_bus = $vertx.event_bus

breaker = VertxCircuitBreaker::CircuitBreaker.create("namaste", $vertx,
  $vertx.get_or_create_context.config["breaker"])

next_service = "bonjour"
my_name = "namaste"

event_bus.consumer("namaste/chain") { |message|
    name = message.body

    breaker.execute_with_fallback(lambda { |future|
      event_bus.send("bonjour", name) { |reply_err,reply|
        if reply_err != nil
          future.fail("Failed to invoke Bonjour")
        else
          response = reply.body
          response[:namaste] = "Namaste #{name}"
          message.reply(response)
          future.complete
        end
      }
    }) { |v|
      message.reply({
          :namaste => "Namaste #{name}",
          :bonjour => "failed !"
      })
    }
}

event_bus.consumer("namaste") { |message|
  name = message.body
  message.reply({:namaste => "Namaste #{name}"})
}

event_bus.consumer("namaste/health") { |message|
    message.reply("I'm ok");
}