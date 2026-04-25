---
name: Architecture instructions
description: "Indicates Project's UI Logic Architecture Rules"
---

# Architecture instructions

This project uses a feature-oriented SwiftUI architecture built on top of MVVM, with unidirectional presentation flow.

## Core architecture principles

- Use **MVVM** for the presentation layer.
- However, avoid traditional loosely-structured MVVM where inputs are scattered across many methods and bindings.
- Prefer a **unidirectional presentation flow**:
  - View emits user input
  - ViewModel receives input as `Action`
  - ViewModel updates a single `State`
  - View renders from `State`
- Use **feature-based structure** over type-based grouping.
- Keep business logic in **UseCases**, not in Views.

## View rules

- Views are responsible only for:
  - rendering state
  - forwarding user actions
  - local UI composition
  - lifecycle triggers such as initial load
- Do not place business logic in SwiftUI Views.
- Do not make Views directly call repositories, services, SDK clients, or persistence APIs.
- Views should prefer emitting actions like `viewModel.send(.tapSubmit)` instead of mutating business state directly.
- Use local `@State` only for truly local UI-only state.
- For shared observable models, ownership should be in `@State`, and downstream passing should use `@Bindable` or `@Environment`, consistent with the project’s Observation-based rules. :contentReference[oaicite:3]{index=3}

## ViewModel rules

- All ViewModels must be `@MainActor`.
- All ViewModels must use `@Observable`, not `ObservableObject`. :contentReference[oaicite:4]{index=4}
- Each screen-level ViewModel must expose a **single screen State**.
- Each screen-level ViewModel must receive user input through a single entry point:
  - `send(_ action: Action)`
- Prefer defining one `Action` enum and one `State` struct per screen.
- ViewModels are responsible for:
  - handling actions
  - calling UseCases
  - mapping domain results into UI state
  - managing loading / error / route state
- ViewModels must not:
  - contain repository implementation details
  - perform direct networking logic
  - manage low-level socket protocols
  - embed payment SDK details
  - own app-wide navigation stack logic
- Prefer explicit state transitions over scattered booleans when complexity grows.
- Use enum-based state for flows such as loading, payment, upload, streaming, connection, and authentication where it improves clarity.
- Keep route emission explicit. A ViewModel may expose a route intent in state, but should not directly manipulate global navigation state unless the feature is intentionally designed that way.

## Action and State conventions

- For each non-trivial screen, define:
  - `FeatureAction`
  - `FeatureState`
  - `FeatureRoute` if navigation is needed
- Treat business-significant user input as `Action`.
- Examples of Action-worthy input:
  - submit
  - refresh
  - retry
  - login
  - send message
  - select reply target
  - payment start
  - web bridge event
- Purely local UI-only input may still use direct binding when appropriate.
- Keep `State` as the single source of truth for rendering.
- Keep one-off presentation concerns explicit, such as:
  - `alert`
  - `toast`
  - `route`
  - `sheet`
  - `fullScreen`

## Coordinator rules

- Coordinators are responsible for **flow decisions**.
- A Coordinator decides where the user should go based on app state, session state, deeplinks, push payloads, payment results, or other feature outcomes.
- A Coordinator is not a SwiftUI View.
- A Coordinator should not own business logic that belongs in a UseCase.
- Use Coordinators for cases such as:
  - app launch flow
  - logged-in vs logged-out root decision
  - forced logout after refresh token failure
  - post-payment redirect
  - deeplink / push entry routing
  - feature-level multi-step flows
- Coordinators may depend on shared app state and on Routers.

## Router rules

- Routers are responsible for **navigation execution**, not business decisions.
- A Router owns and mutates navigation state, such as:
  - `NavigationStack` path
  - presented sheet
  - full-screen cover
- Routers must be `@MainActor @Observable` in this project, not `ObservableObject`. :contentReference[oaicite:5]{index=5}
- Routers should expose narrow navigation APIs such as:
  - `push(_:)`
  - `pop()`
  - `setRoot(_:)`
  - `presentSheet(_:)`
  - `dismissSheet()`
- Routers should not decide whether navigation is allowed. That belongs to Coordinators or higher-level flow logic.
- Route values should be plain destination data, typically enums like `AppRoute` or feature-specific route enums.

## Route rules

- A Route represents **where to go**, not why.
- Route types should be value types, usually enums with associated values when needed.
- Keep route types lightweight and serializable in spirit.
- Prefer one app-level route type plus feature-level route types where complexity justifies it.
- Do not place side effects inside route definitions.

## UseCase rules

- Put business rules in UseCases.
- ViewModels should orchestrate UseCases, not replace them.
- Examples:
  - refresh token rotation
  - social login completion
  - comment submission
  - payment verification
  - chat message send / retry
  - upload validation
- If a rule is important enough to test independently, it likely belongs in a UseCase.

## Project structure rules

- Organize code primarily by **feature**.
- Keep each meaningful screen in its own folder with files like:
  - `FeatureView.swift`
  - `FeatureViewModel.swift`
  - `FeatureAction.swift`
  - `FeatureState.swift`
  - `FeatureRoute.swift`
- Shared infrastructure belongs in Core / Domain / Data, not duplicated across features.
- Do not group the whole project by file type alone.

## Testing rules

- Write unit tests for UseCases and screen-level ViewModels.
- Prefer testing:
  - action → state transitions
  - success/failure flows
  - route emission
  - retry behavior
  - token refresh behavior
  - socket connection state changes
- UI tests should cover only critical flows when unit tests are insufficient, consistent with the project rules.
- Avoid putting important behavior exclusively in Views where it cannot be easily unit tested.
- Never build UI tests module if Project Module is empty (If No UI Testing File or method)

## SwiftUI architecture style constraints

- Use `NavigationStack` and `navigationDestination(for:)` for stack-based navigation.
- Avoid UIKit-based coordinators or navigation wrappers unless explicitly required. 
- Keep Views small by extracting child Views into separate `View` structs rather than large computed subviews.
- Place testable view logic into ViewModels or adjacent presentation models. 

## Default recommendation for new screens

For any new non-trivial screen, prefer this template:

- one `State` struct
- one `Action` enum
- one `@MainActor @Observable` ViewModel
- one View
- optional `Route` enum
- optional feature Coordinator if the flow spans multiple screens
- UseCases injected into the ViewModel

## Anti-patterns to avoid

- Massive Views with business logic
- Massive ViewModels with repository/network/socket/payment implementation details
- Two-way mutation of business state from many child Views
- Direct repository calls from Views
- Using `ObservableObject`/`@Published` for new shared state in this project
- Treating Router as a flow decision-maker
- Treating Coordinator as a dumb push/pop helper
- Hiding important state transitions inside ad-hoc bindings
