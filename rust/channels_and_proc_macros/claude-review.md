❯ is this using the actor pattern as described in this blog? https://ryhl.io/blog/actors-with-tokio/

● No — it's a related pattern but structurally inverted. Both designs use tokio::sync::mpsc, which is why they can look similar at a glance, but the
  message flow goes the opposite direction, and the lifetime model is different.

  Alice Ryhl's actor pattern (from that blog):
  - A long-lived actor owns state and an inbound mpsc::Receiver<Message>.
  - A cheap-to-clone Handle wraps the mpsc::Sender<Message>. Outsiders call methods on the handle (handle.get_unique_id().await); the handle pushes a
  message into the actor.
  - Messages typically carry a oneshot::Sender<Response> so the actor can reply to that specific request.
  - Actor's run is a loop: while let Some(msg) = self.receiver.recv().await { self.handle_message(msg) }.
  - The actor outlives any one request and serializes mutations on its state.

  Our BackgroundTask pattern:
  - A task is a one-shot computation. run(self, reporter) consumes self, runs to completion, returns Self::Output.
  - The mpsc::Sender (via ProgressReporter) goes outbound — the task emits a stream of progress events to whoever's listening.
  - No inbound channel, no Handle struct, no oneshot replies, no per-request RPC.
  - The "final reply" is the JoinHandle<T::Output>, awaited once.

  Side-by-side directionality:

  Actor:  caller -[mpsc cmd]-> actor -[oneshot reply]-> caller    (long-lived, RPC-shaped)
  Ours:   task  -[mpsc progress]-> consumer; task -[JoinHandle output]-> spawner   (one-shot, stream-shaped)

  When you'd switch to Ryhl's actor: if the thing needs to accept commands while running — e.g., a BluetoothCentral that lives for the whole app, holds the
   adapter handle, and accepts Connect { peripheral_id, reply }, Disconnect { reply }, StartScan { reply }, etc. Then "Connect" stops being a task and
  becomes a message you send to the actor. The actor owns the adapter; the handle is cloneable so multiple parts of the app can ask it to do things.

  Why our shape is fine for what you described: the operations you sketched (Connect, ReadData) are unit operations that run to completion and produce a
  result — that's a fit for one-shot tasks with progress streams, not for actors. You'd reach for an actor if there were a long-lived shared resource (the
  BT central adapter) that multiple callers contended for. At that point, the right architecture is often both: an actor owning the adapter, and the actor
  internally spawns these one-shot tasks in response to RPC messages.

✻ Cooked for 41s

❯ lets mock out a BluetoothCentral using this pattern.  Im curious how best to manage state with this new concept as well as exposing idempotent scan,
  connect, and read background tasks

● Before I write code — there are a handful of design forks where I'd rather know your preference than guess. Let me lay out the shape and the choices, and
   you can pick.

  Top-level shape (Ryhl-style):

  BluetoothCentral          ←──── public, cloneable handle (mpsc::Sender<CentralCommand>)
          │
          │  send command
          ▼
  BluetoothCentralActor     ←──── owns state, single-threaded loop on mpsc::Receiver
          │
          │  spawns existing Connect / ReadData / Scan tasks
          ▼
     forwarder tasks         ←──── pump per-op progress to the caller, then notify actor "Done"

  State the actor owns:
  struct Actor {
      rx: mpsc::Receiver<CentralCommand>,
      self_tx: mpsc::Sender<CentralCommand>,   // so spawned tasks can send Internal(...) back
      connections: HashMap<PeripheralId, ConnectionState>,
      scan: Option<ScanState>,
      reads: HashMap<PeripheralId, ReadState>,
  }

  enum ConnectionState {
      Connecting { waiters: Vec<oneshot::Sender<Result<Arc<Connection>, ConnectError>>> },
      Connected(Arc<Connection>),
  }
  Arc<Connection> so multiple callers (read, etc.) share the same connection without cloning it. The actor is the single owner of the state map; only its
  loop mutates it — no locks anywhere.

  Idempotency semantics — the forks I want your call on:

  ┌─────────────┬───────────────────────────┬───────────────────────────────┬────────────────────────────────────────────────┐
  │     Op      │    "Already in flight"    │      "Already complete"       │               Auto-prerequisite?               │
  ├─────────────┼───────────────────────────┼───────────────────────────────┼────────────────────────────────────────────────┤
  │ scan()      │ subscribe to running scan │ start fresh? or no-op?        │ —                                              │
  ├─────────────┼───────────────────────────┼───────────────────────────────┼────────────────────────────────────────────────┤
  │ connect(id) │ wait for in-flight result │ return cached Arc<Connection> │ —                                              │
  ├─────────────┼───────────────────────────┼───────────────────────────────┼────────────────────────────────────────────────┤
  │ read(id)    │ wait for in-flight result │ start fresh                   │ error if not connected, or auto-connect first? │
  └─────────────┴───────────────────────────┴───────────────────────────────┴────────────────────────────────────────────────┘

  My default proposal for the mock:
  - connect: dedupe — first caller gets full progress stream + result; subsequent callers during the in-flight window get only the final result via oneshot
   (no progress stream). If already connected, return Arc<Connection> immediately.
  - read: same dedupe pattern. Error (not auto-connect) if peripheral isn't connected — keeps the dependency explicit, same way the type-level enforcement
  works in the current code.
  - scan: subscribe-to-running pattern. First caller starts the scan; later callers get a fresh mpsc::Receiver that the actor forwards new discoveries
  into.

  Progress for "second caller during in-flight" — the awkward one:
  Cleanest options:
  1. First-caller-only: only the first caller of connect(id) gets a progress stream; subsequent callers get a stub handle with just a
  oneshot::Receiver<Result<...>>. Simple, slightly asymmetric API.
  2. Fan-out via tokio broadcast: each caller gets their own progress receiver, all subscribed to the same broadcast channel. Symmetric API, but broadcast
  drops messages on slow subscribers and forces Clone on the message type.
  3. Per-call mpsc + actor fan-out: actor holds Vec<mpsc::Sender<Msg>>, forwards each progress event to all of them. Symmetric, no message loss, no Clone
  requirement. Slightly more code in the forwarder.

  My default: (1). It's the simplest, and "who actually cares about progress on the second concurrent connect attempt" is rarely a real requirement. Easy
  to upgrade to (3) later if it matters.

  How the existing BackgroundTask machinery slots in:
  The actor still uses spawn_task(Connect { ... }) for the actual work. A small "forwarder" task per op:
  1. Pumps the task's progress receiver to the first caller's mpsc.
  2. Awaits the JoinHandle<Output>.

  Our BackgroundTask pattern:
  - A task is a one-shot computation. run(self, reporter) consumes self, runs
   to completion, returns Self::Output.
  - The mpsc::Sender (via ProgressReporter) goes outbound — the task emits a
  stream of progress events to whoever's listening.
  - No inbound channel, no Handle struct, no oneshot replies, no per-request
  RPC.
  - The "final reply" is the JoinHandle<T::Output>, awaited once.

  Side-by-side directionality:

  Actor:  caller -[mpsc cmd]-> actor -[oneshot reply]-> caller
  (long-lived, RPC-shaped)
  Ours:   task  -[mpsc progress]-> consumer; task -[JoinHandle output]->
  spawner   (one-shot, stream-shaped)

  When you'd switch to Ryhl's actor: if the thing needs to accept commands
  while running — e.g., a BluetoothCentral that lives for the whole app,
  holds the adapter handle, and accepts Connect { peripheral_id, reply },
  Disconnect { reply }, StartScan { reply }, etc. Then "Connect" stops being
  a task and becomes a message you send to the actor. The actor owns the
  adapter; the handle is cloneable so multiple parts of the app can ask it to
   do things.

  Why our shape is fine for what you described: the operations you sketched
  (Connect, ReadData) are unit operations that run to completion and produce
  a result — that's a fit for one-shot tasks with progress streams, not for
  actors. You'd reach for an actor if there were a long-lived shared resource
   (the BT central adapter) that multiple callers contended for. At that
  point, the right architecture is often both: an actor owning the adapter,
  and the actor internally spawns these one-shot tasks in response to RPC
  messages.

✻ Cooked for 41s

❯ lets mock out a BluetoothCentral using this pattern.  Im curious how best
  to manage state with this new concept as well as exposing idempotent scan,
   connect, and read background tasks

● Before I write code — there are a handful of design forks where I'd rather
  know your preference than guess. Let me lay out the shape and the choices,
  and you can pick.

  Top-level shape (Ryhl-style):

  BluetoothCentral          ←──── public, cloneable handle
  (mpsc::Sender<CentralCommand>)
          │
          │  send command
          ▼
  BluetoothCentralActor     ←──── owns state, single-threaded loop on
  mpsc::Receiver
          │
          │  spawns existing Connect / ReadData / Scan tasks
          ▼
     forwarder tasks         ←──── pump per-op progress to the caller, then
  notify actor "Done"

  State the actor owns:
  struct Actor {
      rx: mpsc::Receiver<CentralCommand>,
      self_tx: mpsc::Sender<CentralCommand>,   // so spawned tasks can send
  Internal(...) back
      connections: HashMap<PeripheralId, ConnectionState>,
      scan: Option<ScanState>,
      reads: HashMap<PeripheralId, ReadState>,
  }

  enum ConnectionState {
      Connecting { waiters: Vec<oneshot::Sender<Result<Arc<Connection>,
  ConnectError>>> },
      Connected(Arc<Connection>),
  }
  Arc<Connection> so multiple callers (read, etc.) share the same connection
  without cloning it. The actor is the single owner of the state map; only
  its loop mutates it — no locks anywhere.

  Idempotency semantics — the forks I want your call on:

  ┌─────────────┬────────────┬──────────────────┬───────────────────────┐
  │     Op      │ "Already   │    "Already      │  Auto-prerequisite?   │
  │             │ in flight" │    complete"     │                       │
  ├─────────────┼────────────┼──────────────────┼───────────────────────┤
  │             │ subscribe  │ start fresh? or  │                       │
  │ scan()      │ to running │ no-op?           │ —                     │
  │             │  scan      │                  │                       │
  ├─────────────┼────────────┼──────────────────┼───────────────────────┤
  │             │ wait for   │ return cached    │                       │
  │ connect(id) │ in-flight  │ Arc<Connection>  │ —                     │
  │             │ result     │                  │                       │
  ├─────────────┼────────────┼──────────────────┼───────────────────────┤
  │             │ wait for   │                  │ error if not          │
  │ read(id)    │ in-flight  │ start fresh      │ connected, or         │
  │             │ result     │                  │ auto-connect first?   │
  └─────────────┴────────────┴──────────────────┴───────────────────────┘

  My default proposal for the mock:
  - connect: dedupe — first caller gets full progress stream + result;
  subsequent callers during the in-flight window get only the final result
  via oneshot (no progress stream). If already connected, return
  Arc<Connection> immediately.
  - read: same dedupe pattern. Error (not auto-connect) if peripheral isn't
  connected — keeps the dependency explicit, same way the type-level
  enforcement works in the current code.
  - scan: subscribe-to-running pattern. First caller starts the scan; later
  callers get a fresh mpsc::Receiver that the actor forwards new discoveries
  │ connect(id) │ wait for in-flight result │ return cached Arc<Connection> │ —                                              │
  ├─────────────┼───────────────────────────┼───────────────────────────────┼────────────────────────────────────────────────┤
  │ read(id)    │ wait for in-flight result │ start fresh                   │ error if not connected, or auto-connect first? │
  └─────────────┴───────────────────────────┴───────────────────────────────┴────────────────────────────────────────────────┘

  My default proposal for the mock:
  - connect: dedupe — first caller gets full progress stream + result; subsequent callers during the in-flight window get only the final result via oneshot
   (no progress stream). If already connected, return Arc<Connection> immediately.
  - read: same dedupe pattern. Error (not auto-connect) if peripheral isn't connected — keeps the dependency explicit, same way the type-level enforcement
  works in the current code.
  - scan: subscribe-to-running pattern. First caller starts the scan; later callers get a fresh mpsc::Receiver that the actor forwards new discoveries
  into.

  Progress for "second caller during in-flight" — the awkward one:
  Cleanest options:
  1. First-caller-only: only the first caller of connect(id) gets a progress stream; subsequent callers get a stub handle with just a
  oneshot::Receiver<Result<...>>. Simple, slightly asymmetric API.
  2. Fan-out via tokio broadcast: each caller gets their own progress receiver, all subscribed to the same broadcast channel. Symmetric API, but broadcast
  drops messages on slow subscribers and forces Clone on the message type.
  3. Per-call mpsc + actor fan-out: actor holds Vec<mpsc::Sender<Msg>>, forwards each progress event to all of them. Symmetric, no message loss, no Clone
  requirement. Slightly more code in the forwarder.

  My default: (1). It's the simplest, and "who actually cares about progress on the second concurrent connect attempt" is rarely a real requirement. Easy
  to upgrade to (3) later if it matters.

  How the existing BackgroundTask machinery slots in:
  The actor still uses spawn_task(Connect { ... }) for the actual work. A small "forwarder" task per op:
  1. Pumps the task's progress receiver to the first caller's mpsc.
  2. Awaits the JoinHandle<Output>.
  3. Sends an internal CentralCommand::ConnectFinished { id, result } back into the actor's own inbox via self_tx.

  The actor then mutates state and replies to all waiters in its main loop — no locks, no Mutex, all serialized through the single channel. That's the
  actor pattern's main payoff.

  ---
  What I need from you to proceed:
  1. Confirm the idempotency table above (especially: read errors vs. auto-connects).
  2. Confirm progress fan-out option (1) is fine, or pick (2)/(3).
  3. Anything else you want modeled — disconnect, multiple simultaneous reads to different peripherals, scan timeout, etc.? Easy to leave out for now and
  add later.

  Once you say go, I'll implement it as a new bluetooth module that uses the existing task/connect/read_data modules as the underlying workers.

✻ Cooked for 1m 43s

❯ does this pattern fit well into a library?

● Honest answer: it's great as an internal implementation pattern, mediocre-to-poor as a library's public API. The distinction matters a lot.

  Where it shines (internal to a library):
  - The library is wrapping a stateful, single-threaded resource — exactly the BT adapter case. Serializing all access through one task matches the
  hardware reality and eliminates internal locking.
  - All the state-machine logic (Connecting/Connected/etc.) lives in one place, mutated by one task. No Mutex, no RwLock, no shared-state bugs.

  Where it strains as the public API:

  1. You impose a runtime on your users. tokio::spawn is hardcoded. Anyone using smol/async-std/embassy can't use your library. Bluetooth libraries
  especially want to be portable. Mitigation exists (feature-gated runtime support, agnostic spawners) but the pattern fights against that.
  2. Every call is async, even trivial getters. handle.is_connected().await pays an mpsc::send + oneshot::recv round trip for what could be a synchronous
  read. Tail latency adds up; users' code becomes .await-soup.
  3. Everything crossing the channel must be Send + 'static. Borrowed data is out. Your public API gets pushed toward owned/cloned types (String not &str,
  owned bytes not slices). Allocates more than necessary, and constrains the API ergonomics.
  4. expect("actor died") is awful library hygiene. Either every method returns Result<_, ActorDead> (verbose at every call site) or you panic (hostile to
  consumers). Neither is great. Stand-alone async functions don't have this problem — they just fail with a normal error.
  5. Cancellation breaks user expectations. Library consumers expect "drop the future, cancel the work." The actor pattern violates that — the command's
  already in the queue; dropping the caller's await doesn't unsend it. You end up needing CancellationToken plumbing inside commands.
  6. Backpressure decisions leak. You pick mpsc::channel(N) — N becomes part of your library's API surface, whether you want it to or not. Users can't tune
   it for their workload.
  7. Extension is a three-shot edit. New operation = new command variant + new actor handler + new handle method. Internal code: fine. Public API where
  users might want to extend behavior via traits: rigid.

  What libraries that solve this problem actually do:
  - btleplug / bluer — expose Adapter/Peripheral types with async methods. No actor in the public API.
  - redis::aio::ConnectionManager — uses an actor internally, exposes a normal-looking handle. You can also use the lower-level Connection directly without
   the manager.
  - sqlx — pool uses actor-ish coordination; exposed API is Pool::acquire().await returning a connection guard, not a command-passing handle.

  The common move: actor for the stateful coordination layer; plain typed async methods at the public surface. Users who want serialized access get it via
  the convenience layer; users who want raw control get the underlying types.

  Concrete recommendation for your code:

  If this becomes a library:
  - Keep Connect, ReadData, and the BackgroundTask trait as the public building blocks. They're already composable, runtime-agnostic at the trait level
  (the async-trait allocation is the only tokio-flavored bit), and don't impose state semantics.
  - Offer BluetoothCentral as an optional convenience layer with a clearly-documented "this is opinionated coordination for one common usage pattern"
  framing.
  - The BluetoothCentral handle's methods should return normal-looking types — impl Future<Output = Result<Connection, _>> — not leak ConnectHandle {
  progress: Receiver, result: oneshot::Receiver } shapes that scream "actor under the hood."
  - If you go further, consider a trait BluetoothBackend that both the real central and a MockCentral implement — that's what makes the library testable
  for downstream users.

  If this stays as an internal binary, the actor pattern is fine as the only API. The constraints I listed bite hardest when you have external consumers
  writing their own code against your types.

  So: do you want me to still build the mock as we sketched (treating it as application code), or are you now thinking about this as a library and want a
  different shape?


