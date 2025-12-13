{ config, lib, inputs, ... }:

let
  skillName = "managing-rails-events";
  cfg = config.jvf.aiTools.skills."${skillName}";
  skillHumanName = inputs.lib.strings.kebabToHuman skillName;
  skillOptions = {
    name = skillName;
    description = "Expert in Rails Event Store patterns including event publishing, subscriptions (sync/async), event sourcing with AggregateRoot, projections, reading events, correlation/causation, mappers, transactions, and common usage patterns. Use when working with Rails Event Store, event-driven architectures, or when users mention events, aggregates, projections, or event sourcing in Rails.";
    tags = [
      "explorer"
      "documentation"
    ];
    prompt = ''
      # ${skillHumanName}

      This skill provides comprehensive expertise in Rails Event Store (RES) patterns and best practices for building event-driven applications in Rails.

      ## Core Concepts

      ### Event Publishing

      **Defining Events:**
      ```ruby
      class OrderPlaced < RailsEventStore::Event
      end

      # Or using Class.new
      OrderPlaced = Class.new(RailsEventStore::Event)
      ```

      **Basic Publishing:**
      ```ruby
      event = OrderPlaced.new(data: { order_id: 1, order_data: "sample" })
      event_store.publish(event, stream_name: "order_1")
      ```

      **Publishing with Optimistic Locking:**
      ```ruby
      event_store.publish(
        event,
        stream_name: "order_1",
        expected_version: 3  # Position of last event in stream
      )
      ```

      **Appending without triggering handlers:**
      ```ruby
      event_store.append(event, stream_name: "order_1")
      ```

      ### Expected Version Values

      - `:any` - Default, no ordering guarantees, never fails
      - `Integer` (e.g., `-1`, `0`, `1`) - Optimistic locking, fails if version doesn't match
      - `:auto` - Automatically finds last position (use with custom locking)
      - `:none` - Synonym for `-1`, expects empty stream

      ### Event Subscriptions

      **Synchronous Handlers:**
      ```ruby
      # Object handler
      class InvoiceReadModel
        def call(event)
          # Process event
        end
      end
      event_store.subscribe(InvoiceReadModel.new, to: [InvoiceCreated, InvoiceUpdated])

      # Lambda/Proc handler
      event_store.subscribe(to: [InvoicePrinted]) { |event| /* process */ }
      invoice_handler = ->(event) { /* process */ }
      event_store.subscribe(invoice_handler, to: [InvoiceCreated])
      ```

      **Handler State Management:**
      - Subscribe class (not instance) for fresh state per event: `event_store.subscribe(SyncHandler, to: [OrderPlaced])`
      - Subscribe instance for shared state: `event_store.subscribe(SyncHandler.new, to: [OrderPlaced])`

      **Subscribe to All Events:**
      ```ruby
      event_store.subscribe_to_all_events(EventsLogger.new(Rails.logger))
      event_store.subscribe_to_all_events { |event| puts event.inspect }
      ```

      **Temporary Subscriptions:**
      ```ruby
      event_store
        .within { Import.new.run(file) }
        .subscribe(results, to: [ProductImported, ProductImportFailed])
        .call
      ```

      ### Asynchronous Handlers

      **ActiveJob Handler:**
      ```ruby
      class SendOrderEmail < ActiveJob::Base
        prepend RailsEventStore::AsyncHandler

        def perform(event)
          email = event.data.fetch(:customer_email)
          OrderMailer.notify_customer(email).deliver_now!
        end
      end

      event_store.subscribe(SendOrderEmail, to: [OrderPlaced])
      ```

      **Custom Scheduler:**
      ```ruby
      class CustomScheduler
        def call(klass, serialized_record)
          klass.perform_async(serialized_record.to_h)
        end

        def verify(subscriber)
          Class === subscriber && subscriber.respond_to?(:perform_async)
        end
      end

      event_store = RailsEventStore::Client.new(
        message_broker: RubyEventStore::Broker.new(
          dispatcher: RailsEventStore::AfterCommitAsyncDispatcher.new(scheduler: CustomScheduler.new)
        )
      )
      ```

      **Composed Dispatcher (Default):**
      ```ruby
      event_store = RailsEventStore::Client.new(
        message_broker: RubyEventStore::Broker.new(
          dispatcher: RubyEventStore::ComposedDispatcher.new(
            RailsEventStore::AfterCommitAsyncDispatcher.new(scheduler: RailsEventStore::ActiveJobScheduler.new),
            RubyEventStore::Dispatcher.new
          )
        )
      )
      ```

      ### Reading Events

      **Specification Pattern:**
      ```ruby
      # Available methods: stream, from, to, forward, backward, limit, in_batches, of_type, older_than, newer_than, between
      scope = client.read
        .stream('GoldCustomers')
        .backward
        .limit(100)
        .of_type([Customer::GoldStatusGranted])
      ```

      **Reading Methods:**
      ```ruby
      scope.count                    # Total events in scope
      scope.each { |event| ... }     # Enumerator for all events
      scope.each_batch { |batch| ... } # Enumerator for batches
      scope.to_a                     # Array of all events
      scope.first                    # First event
      scope.last                     # Last event
      scope.event(event_id)          # Single event or nil
      scope.event!(event_id)         # Single event or raises EventNotFound
      scope.events([id1, id2])       # Array of events
      ```

      **Time-based Queries:**
      ```ruby
      client.read.newer_than(3.days.ago).toa
      client.read.older_than(Time.now).toa
      client.read.between(10.days.ago..3.days.ago).toa
      ```

      **Position Queries:**
      ```ruby
      client.position_in_stream("stream_name", "event_id")  # Raises EventNotFoundInStream
      client.global_position("event_id")                    # Raises EventNotFound
      client.event_in_stream?("event_id", "stream_name")
      ```

      ## Event Sourcing with AggregateRoot

      **Configuration:**
      ```ruby
      AggregateRoot.configure do |config|
        config.default_event_store = Rails.configuration.event_store
      end
      ```

      **Aggregate Definition:**
      ```ruby
      class Order
        include AggregateRoot

        def initialize
          @state = :new
        end

        def submit
          raise HasBeenAlreadySubmitted if state == :submitted
          apply OrderSubmitted.new(data: {delivery_date: Time.now + 24.hours})
        end

        on OrderSubmitted do |event|
          @state = :submitted
          @delivery_date = event.data.fetch(:delivery_date)
        end
      end
      ```

      **Repository Pattern:**
      ```ruby
      class OrderRepository
        def initialize(event_store = Rails.configuration.event_store)
          @repository = AggregateRoot::Repository.new(event_store)
        end

        def with_order(order_id, &block)
          stream_name = "Order$#{order_id}"
          repository.with_aggregate(Order.new, stream_name, &block)
        end

        private
        attr_reader :repository
      end

      # Usage
      repository = OrderRepository.new
      repository.with_order(123) do |order|
        order.submit
      end
      ```

      ## Projections

      **Single Stream Projection:**
      ```ruby
      account_balance =
        RailsEventStore::Projection
          .from_stream(stream_name)
          .init(-> { { total: 0 } })
          .when(MoneyDeposited, ->(state, event) { state[:total] += event.data[:amount] })
          .when(MoneyWithdrawn, ->(state, event) { state[:total] -= event.data[:amount] })

      account_balance.run(client) # => {total: 25}
      account_balance.run(client, start: custom_event.event_id) # Start from specific event
      ```

      **Multiple Streams:**
      ```ruby
      RailsEventStore::Projection
        .from_stream(%w[Customer$1 Customer$3])
        .init(-> { { total: 0 } })
        .when(MoneyDeposited, ->(state, event) { state[:total] += event.data[:amount] })
        .run(client)
      ```

      **All Streams:**
      ```ruby
      RailsEventStore::Projection
        .from_all_streams
        .init(-> { { total: 0 } })
        .when([MoneyDeposited, MoneyWithdrawn], ->(state, event) { state[:total] += event.data[:amount] })
        .run(client)
      ```

      ## Correlation and Causation

      **Basic Correlation:**
      ```ruby
      class MyEventHandler
        def call(previous_event)
          new_event = MyEvent.new(data: { foo: "bar" })
          new_event.correlate_with(previous_event)
          event_store.publish(new_event)
        end
      end
      ```

      **Manual Metadata Correlation:**
      ```ruby
      event_store.with_metadata(
        correlation_id: previous_event.correlation_id || previous_event.event_id,
        causation_id: previous_event.event_id,
      ) { event_store.publish([event1, event2]) }
      ```

      **Async Handler Correlation:**
      ```ruby
      class SendOrderEmail < ActiveJob::Base
        prepend RailsEventStore::CorrelatedHandler
        prepend RailsEventStore::AsyncHandler
        # ...
      end
      ```

      **Linking Streams:**
      ```ruby
      event_store.subscribe_to_all_events(RailsEventStore::LinkByCorrelationId.new)
      event_store.subscribe_to_all_events(RailsEventStore::LinkByCausationId.new)

      # Read linked events
      event_store.read.stream("$by_causation_id_#{event.event_id}")
      event_store.read.stream("$by_correlation_id_#{event.correlation_id || event.event_id}")
      ```

      ## Mappers

      **Available Mappers:**
      - `RubyEventStore::Mappers::Default` - Default for RailsEventStore
      - `RubyEventStore::Mappers::Protobuf` - For Google Protobuf events
      - `RubyEventStore::Mappers::NullMapper` - For tests (no transformations)
      - `RubyEventStore::Mappers::EncryptionMapper` - For GDPR compliance

      **Custom Mapper:**
      ```ruby
      class MessagePackSerialization
        def dump(record)
          RubyEventStore::Record.new(
            event_id: record.event_id,
            metadata: record.metadata.to_msg_pack,
            data: record.data.to_msg_pack,
            event_type: record.event_type,
            timestamp: record.timestamp,
            valid_at: record.valid_at
          )
        end

        def load(record)
          RubyEventStore::Record.new(
            event_id: record.event_id,
            metadata: MessagePack.unpack(record.metadata),
            data: MessagePack.unpack(record.data),
            event_type: record.event_type,
            timestamp: record.timestamp,
            valid_at: record.valid_at
          )
        end
      end

      class MyHashToMessagePackMapper < RubyEventStore::Mappers::PipelineMapper
        def initialize
          super(RubyEventStore::Mappers::Pipeline.new(
            MessagePackSerialization.new
          ))
        end
      end

      # Configure
      event_store = RailsEventStore::Client.new(mapper: MyHashToMessagePackMapper.new)
      ```

      ## Transactions

      **Application-level Transactions:**
      ```ruby
      ActiveRecord::Base.transaction do
        order = Order.new(...).save!
        event_store.publish(
          OrderPlaced.new(data:{order_id: order.id}),
          stream_name: "Order-#{order.id}"
        )
        # Sync handlers execute here
        # Async handlers scheduled after commit (default)
      end
      ```

      **Immediate Async Scheduling:**
      ```ruby
      event_store = RailsEventStore::Client.new(
        message_broker: RubyEventStore::Broker.new(
          dispatcher: RubyEventStore::ComposedDispatcher.new(
            RailsEventStore::ImmediateAsyncDispatcher.new(scheduler: RailsEventStore::ActiveJobScheduler.new),
            RubyEventStore::Dispatcher.new
          )
        )
      )
      ```

      ## Common Usage Patterns

      **Publishing Unique Events (Idempotency):**
      ```ruby
      def publish_event_uniquely(event, *fields)
        uniqueness_key = [event.event_type, *fields].join("_")
        event_store.publish(event, stream_name: "$unique_by_#{uniqueness_key}", expected_version: :none)
      rescue RubyEventStore::WrongExpectedEventVersion
        # Event already published, ignore
      end
      ```

      **Exception Handling in Handlers:**
      ```ruby
      class SyncHandler
        def call(event)
          # Process event
        rescue => e
          ExceptionTracker.notify(e)
          # Don't re-raise to avoid transaction rollback
        end
      end
      ```

      **Removing Subscriptions:**
      ```ruby
      unsubscribe = event_store.subscribe(OrderNotifier.new, to: [OrderCancelled])
      # Later...
      unsubscribe.call
      ```

      ## Best Practices

      1. **Stream Naming:** Use meaningful stream names like `"Order$123"`, `"Customer$456"`
      2. **Handler State:** Subscribe classes (not instances) for fresh state, or handle memoization carefully
      3. **Exception Handling:** Always rescue exceptions in sync handlers to avoid transaction rollbacks
      4. **Correlation:** Use `correlate_with` for tracking event chains, especially in async handlers
      5. **Projections:** Use projections for read models, not for complex business logic
      6. **Transactions:** Leverage RES transaction support for consistency between DB and events
      7. **Versioning:** Use `expected_version` for optimistic locking in event-sourced aggregates
      8. **Testing:** Use `NullMapper` in tests for faster execution

      ## Resources

      - [Rails Event Store GitHub](https://github.com/RailsEventStore/rails_event_store)
      - [Ecommerce Example App](https://github.com/RailsEventStore/ecommerce)
      - [Arkency Blog Posts](https://blog.arkency.com/tags/event-sourcing/)

      ## Related Files

      - Sequence diagrams: `publish-sequence-diagram.mmd`, `read-sequence-diagram.mmd`, `subscribe-sequence-diagram.mmd`
      - Core concepts in `core-concepts/` directory
      - Advanced topics in `advanced-topics/` directory
      - Common patterns in `common-usage-patterns/` directory
    '';
  };
in
{
  options.jvf.aiTools.skills."${skillName}" = {
    enable = (lib.mkEnableOption "Enable the ${skillHumanName} agent") // {
      default = true;
    };
  };

  config = lib.mkIf cfg.enable {
    jvf.programs.opencode.skills."${skillName}" = skillOptions;
    jvf.programs.claudecode.skills."${skillName}" = skillOptions;
  };
}
