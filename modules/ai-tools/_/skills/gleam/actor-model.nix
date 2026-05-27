{ lib
, pkgs
, isDarwin
, npx
, defaultBrowser
, kebabToHuman
, ...
}:
{
  allowed-tools = [
    "Read"
    "Grep"
    "Glob"
    "Write"
    "Edit"
    "Bash"
  ];
  name = "gleam-actor-model";
  description = "Use when OTP actor patterns in Gleam including processes, message passing, GenServer implementations, supervisors, fault tolerance, state management, and building concurrent, fault-tolerant applications on the Erlang VM.";
  prompt = ''
    # Gleam Actor Model

    ## Introduction

    Gleam leverages the Erlang VM's actor model, enabling lightweight concurrent
    processes that communicate through message passing. This model provides inherent
    fault tolerance, isolation, and scalability, making it ideal for building
    distributed systems.

    The actor model in Gleam uses OTP (Open Telecom Platform) patterns including
    GenServers for stateful processes, supervisors for fault recovery, and message
    passing for inter-process communication. Each process has its own heap and
    communicates asynchronously, eliminating shared memory concerns.

    This skill covers process creation and message passing, GenServer pattern for
    stateful actors, supervisors and fault tolerance, process linking and monitoring,
    selective receive, and patterns for building robust concurrent applications.

    ## Process Basics and Message Passing

    Processes are lightweight, isolated units of execution that communicate via
    message passing.

    ```gleam
    import gleam/erlang/process
    import gleam/io

    // Basic process creation
    pub fn simple_process() {
      process.spawn(fn() {
        io.println("Hello from process!")
      })
    }

    // Process with message passing
    pub type Message {
      Ping
      Pong
      Stop
    }

    pub fn echo_process() {
      let subject = process.new_subject()
      process.spawn(fn() { loop(subject) })
      subject
    }

    fn loop(subject: process.Subject(Message)) {
      case process.receive(subject, 1000) {
        Ok(Ping) -> { io.println("Received Ping"); loop(subject) }
        Ok(Pong) -> { io.println("Received Pong"); loop(subject) }
        Ok(Stop) -> { io.println("Stopping"); Nil }
        Error(_) -> { io.println("Timeout"); loop(subject) }
      }
    }

    pub fn send_messages(subject: process.Subject(Message)) {
      process.send(subject, Ping)
      process.send(subject, Pong)
      process.send(subject, Stop)
    }

    // Request-response pattern
    pub type Request {
      GetValue(reply_to: process.Subject(Int))
      SetValue(value: Int, reply_to: process.Subject(Nil))
    }

    pub fn state_process(initial: Int) {
      let subject = process.new_subject()
      process.spawn(fn() { state_loop(subject, initial) })
      subject
    }

    fn state_loop(subject: process.Subject(Request), state: Int) {
      case process.receive(subject, 5000) {
        Ok(GetValue(reply_to)) -> { process.send(reply_to, state); state_loop(subject, state) }
        Ok(SetValue(value, reply_to)) -> { process.send(reply_to, Nil); state_loop(subject, value) }
        Error(_) -> state_loop(subject, state)
      }
    }
    ```

    ## GenServer Pattern

    GenServer provides a standard pattern for stateful processes with synchronous
    and asynchronous operations.

    ```gleam
    import gleam/otp/actor
    import gleam/erlang/process

    pub type Counter { Counter(value: Int) }

    pub type CounterMessage {
      Increment
      Decrement
      GetValue(reply_to: process.Subject(Int))
      Reset(reply_to: process.Subject(Nil))
    }

    pub fn start_counter() -> Result(process.Subject(CounterMessage), actor.StartError) {
      actor.start(Counter(value: 0), handle_message)
    }

    fn handle_message(message: CounterMessage, state: Counter) -> actor.Next(CounterMessage, Counter) {
      case message {
        Increment -> actor.continue(Counter(value: state.value + 1))
        Decrement -> actor.continue(Counter(value: state.value - 1))
        GetValue(reply_to) -> { process.send(reply_to, state.value); actor.continue(state) }
        Reset(reply_to) -> { process.send(reply_to, Nil); actor.continue(Counter(value: 0)) }
      }
    }
    ```

    ## Supervisors and Fault Tolerance

    Supervisors monitor child processes and restart them on failure.

    ```gleam
    import gleam/otp/supervisor
    import gleam/erlang/process

    pub fn start_supervisor() -> Result(process.Subject(supervisor.Message), supervisor.StartError) {
      supervisor.start(fn(children) {
        children
        |> supervisor.add(supervisor.worker(fn(_) { worker() }))
      })
    }

    // Supervisor tree with named workers
    pub fn start_named_supervisor() -> Result(process.Subject(supervisor.Message), supervisor.StartError) {
      supervisor.start(fn(children) {
        children
        |> supervisor.add(supervisor.worker_spec(
          start: fn(_) { start_counter() },
          restart: supervisor.RestartForever,
        ))
        |> supervisor.add(supervisor.worker_spec(
          start: fn(_) { start_cache(100) },
          restart: supervisor.RestartForever,
        ))
      })
    }

    // Supervisor tree with child supervisor
    pub fn start_application() -> Result(process.Subject(supervisor.Message), supervisor.StartError) {
      supervisor.start(fn(children) {
        children
        |> supervisor.add(supervisor.worker(fn(_) { start_counter() }))
        |> supervisor.add(supervisor.worker(fn(_) { start_cache(100) }))
        |> supervisor.add(supervisor.supervisor(fn(children) {
          children
          |> supervisor.add(supervisor.worker(fn(_) { worker() }))
        }))
      })
    }
    ```

    ## Process Linking and Monitoring

    Links and monitors enable processes to react to failures in related processes.

    ```gleam
    import gleam/erlang/process

    // Process linking
    pub fn linked_processes() {
      let child = process.spawn_link(fn() {
        io.println("Child process started")
        process.sleep(1000)
      })
      process.sleep(2000)
    }

    // Process monitoring
    pub fn monitored_process() {
      let monitored = process.spawn(fn() {
        io.println("Monitored process started")
        process.sleep(1000)
      })
      let monitor = process.monitor_process(monitored)
      let selector = process.new_selector()
        |> process.selecting_process_down(monitor, fn(down) { down })
      case process.select(selector, 2000) {
        Ok(down) -> io.println("Process exited")
        Error(_) -> io.println("Still running")
      }
    }

    // Trap exits for supervision
    pub fn trap_exits() {
      process.trap_exits(True)
      let child = process.spawn_link(fn() {
        io.println("Child starting")
        panic as "Simulated error"
      })
      let selector = process.new_selector()
        |> process.selecting_trapped_exits(fn(exit) { exit })
      case process.select(selector, 2000) {
        Ok(exit) -> io.println("Caught exit from child")
        Error(_) -> io.println("No exit received")
      }
    }
    ```

    ## Best Practices

    1. Use GenServer for stateful processes to leverage OTP patterns
    2. Wrap GenServers in supervisor trees for automatic recovery
    3. Keep process state minimal to reduce memory usage
    4. Use message types with reply_to fields for request-response patterns
    5. Set appropriate timeouts on receive to prevent indefinite blocking
    6. Monitor external processes rather than linking when you don't want to crash together
    7. Use descriptive message types with custom types rather than generic tuples
    8. Handle all message types in loops to prevent message accumulation
    9. Design for failure by assuming processes will crash and using supervisors
    10. Keep process hierarchies simple with clear parent-child relationships

    ## Common Pitfalls

    1. Not handling timeout cases in receive causes processes to hang
    2. Forgetting to reply in request-response patterns causes client timeout
    3. Creating too many processes without reason adds overhead
    4. Not using supervisors loses fault tolerance benefits
    5. Blocking in message handlers prevents processing other messages
    6. Accumulating unconsumed messages causes memory leaks
    7. Linking processes incorrectly causes unintended crash propagation
    8. Not setting init_timeout on actors causes startup delays
    9. Using shared mutable state defeats isolation benefits
    10. Ignoring exit signals when trapping exits prevents cleanup

    ## Resources

    - Gleam OTP Documentation: https://hexdocs.pm/gleam_otp/
    - Erlang Actor Model: https://www.erlang.org/doc/getting_started/conc_prog.html
    - OTP Design Principles: https://www.erlang.org/doc/design_principles/des_princ.html
    - Gleam Actor Tutorial: https://gleam.run/writing-gleam/actors/
    - Learn You Some Erlang - Supervisors: https://learnyousomeerlang.com/supervisors
  '';
}
