# Copilot Instructions for FantasyApp

## Architecture Overview
This is a SwiftUI + RealityKit iPad app implementing an Entity-Component-System (ECS) pattern for game logic. The app integrates local AI (Ollama) for event-driven character behavior decisions.

**Key Components:**
- **MatheMagicApp/**: Main app code with SwiftUI views and RealityKit scenes
- **AnimLibS/**: Animation library for character movements and state transitions
- **CoreLib/**: Core utilities and shared components
- **AssetLib/**: Asset management and loading system

**Data Flow:**
- `TeraModelDictionaryActor` (actor-based store) holds game state
- `GameModelView` (ObservableObject) manages UI state and communicates with store
- Custom RealityKit components (e.g., `MoveComponent`, `TapComponent`) attached to entities
- Corresponding systems (e.g., `MoveSystem`) update components in `update(context:)` methods

## Development Workflows

### Building and Running
- Open `MatheMagic.xcodeproj` in Xcode
- Target: iPad (iOS 18+)
- Build scheme: Default (FantasyAppGithub)

### AI Integration Setup
1. Install Ollama locally: `brew install ollama`
2. Expose to LAN: Set `OLLAMA_HOST=0.0.0.0:11434` before starting
3. Grant local network permissions in iPad Settings > Privacy > Local Network
4. App connects to Ollama at configurable host (default: `http://192.168.1.100:11434`)

### Source Concatenation for AI Prompts
Run `python3 _concat/concat_sources.py` to generate `concatenated_MVR.txt` containing structured source code for AI analysis. Update `SOURCE_FILES` list in the script to include new files.

## Code Patterns and Conventions

### Component-System Pattern
- Define data-only structs conforming to `RealityKit.Component`
- Implement update logic in classes conforming to `RealityKit.System`
- Register components/systems in `MatheMagicApp.init()`
- Example: `MoveComponent` stores position, `MoveSystem` updates based on joystick input

### State Management
- Use `GameplayKit.GKStateMachine` for game states (Load, Ready, Play, etc.)
- Inject dependencies (e.g., `GameModelView`, `TeraModelDictionaryActor`) into states
- States handle async operations like asset loading

### Logging
- Use `AppLogger.shared` for all logging (info, error, debug)
- Inject clock time provider for consistent timestamps: `AppLogger.shared.clockTimeProvider = { gameModelView.clockTime }`

### AI Prompt Structure
- Send flat JSON schemas with enum options to Ollama
- Include `schema_version` and optional `event_echo` for traceability
- Validate returned JSON against expected structure
- Example schema: `{"horse_action": "run", "landscape_coloring_action": "dangerous_red"}`

### File Organization
- Group related functionality in subdirectories (Components/, Entities/, Views/)
- Use `Top-Level/` for main app files
- Separate old/legacy code in `Brain-Old/` directories

## Key Files to Reference
- `MatheMagicApp/Top-Level/MatheMagicApp.swift`: App setup, component/system registration
- `MatheMagicApp/Game Engine/GameMachineStates.swift`: State machine implementation
- `MatheMagicApp/Components/MoveComponent.swift`: Example component-system pair
- `_concat/concat_sources.py`: Source concatenation script
- `_concat/prompts/Plan.md`: AI integration requirements</content>
<parameter name="filePath">/Users/nata/GitHub/iPadApp/FantasyApp/.github/copilot-instructions.md