PLAN

========================================================================
GOAL
========================================================================

Create a proof of concept Swift iPad app that:

1. Sends an event description + a JSON structure with multiple-choice
   fields to a local AI API (Ollama)
2. AI selects the relevant option for each field based on the event

3. App ingests the returned JSON, validates it, and prints results


EXAMPLE INPUT
-------------
Event: "Tiger is roaring"

Fields to fill:

  Character: Horse
    Action: [AI picks one]
       Unclear
       NoChange
       Idle
       Walk
       Run

  Character: Landscape Coloring
    Action: [AI picks one]
      Unclear
      NoChange
      Vibrant Green
      Dull Brown
      Dangerous Red


EXAMPLE OUTPUT (from AI)
------------------------
{
  "horse_action": "run",
  "landscape_coloring_action": "dangerous_red"
}

App ingests this, validates, and prints decoded enums to console.


APPROACH
--------
1. Build a super simple iPad app (iOS 26) that accomplishes the goal
2. Turn that simple app into a reusable Swift library
3. Plug the library into the actual app

The library will accept prompts containing JSON where some parts
are pre-filled info and other parts need AI to fill in from
multiple-choice options.


========================================================================
CONTRACT RECOMMENDATION FOR THE POC
========================================================================


OUTPUT SHAPE (KEEP IT FLAT FOR POC)
-----------------------------------
Flat is best for reliability and simplest to decode:

    horse_action: <enum>
    landscape_coloring_action: <enum>

groundwork: add
    schema_version: 1          (required)
    event_echo: "<original event>"  (optional, for traceability)

This still stays "super simple", but the version field prevents
painful migrations later.


PROMPTING RULES THAT MAKE "NoChange" MEANINGFUL
-----------------------------------------------
You need one explicit policy statement in the prompt
(even with schema enforcement):

  - Use no_change if the event does not affect this field.
  - Use unclear if the event suggests it might affect the field
    but is ambiguous.
  - "Return ONLY JSON that matches the schema."

Also: Ollama explicitly notes it's ideal to include the schema
as a string in the prompt to ground the model, even when using format.


LAN + iPAD CONSTRAINTS (TREAT AS PHASE 0 REQUIREMENTS)
------------------------------------------------------
1) Expose Ollama to the LAN
   Ollama binds to 127.0.0.1:11434 by default; to reach it from
   the iPad you must change the bind address using OLLAMA_HOST.

2) Local network privacy permission
   If your app accesses the local network, include
   NSLocalNetworkUsageDescription and handle the permission
   flow/denial.

3) ATS for HTTP to a LAN IP
   For a LAN proof-of-concept that calls http://<IP>:11434,
   use NSAllowsLocalNetworking (narrower than "allow arbitrary
   loads") to permit local-network HTTP/IP access.


========================================================================
PHASE PLAN (POC -> LIBRARY -> GROUNDWORK FOR DYNAMIC TEMPLATES)
========================================================================

PHASE 0 - Server readiness + connectivity preflight
--------
Goal: Eliminate "it doesn't connect" failures

Ollama API Configuration:

- Base URL: http://100.93.96.72:11434
- Model name: mistral-small
- No authentication required (secured via Tailscale network)

Deliverables:
  - Ollama reachable from iPad over Wi-Fi
  - Preflight request implemented:
      GET /api/version   (confirm you're talking to Ollama)
      GET /api/tags      (optional, confirm model name exists)

Acceptance criteria:
  - iPad can hit /api/version and get a version response
  - You have one canonical base URL (e.g. http://192.168.x.x:11434)


PHASE 1 - Lock the contract
--------
Goal: Schema + IDs + Swift types + mappings

Deliverables:
  - A single schema that includes:
      - required fields
      - enum lists
      - additionalProperties: false
      - the fallback choices (unclear, no_change)
  - Swift Codable types that match exactly (enums for actions)
  - Mapping tables: enum -> display label, enum -> numeric code

Acceptance criteria:
  - A sample valid JSON decodes
  - Any unknown key or invalid enum value fails validation


PHASE 2 - Prompt builder
--------
Goal: Small, deterministic, testable

Deliverables:
  - System message that enforces "JSON only; match schema; no prose"
  - User message that includes:
      - event text
      - definitions of each field + option meanings
      - explicit "no_change vs unclear" rule
      - (recommended) schema string included for grounding
  - Deterministic runtime options (temperature near 0)

Acceptance criteria:
  - Repeated runs on the same event usually return identical outputs


PHASE 3 - Minimal test harness
--------
Goal: Exercise the loop end-to-end

Deliverables:
  - Hardcoded test event in code (modify directly to test different inputs)
  - Network call to POST /api/chat with:
      - stream: false
      - format: <schema>
  - Console prints:
      - raw message.content
      - decoded result

Note: No UI needed. The "event" input will become an external
parameter when extracted to a library (Phase 5).

Acceptance criteria:
  - Sample event produces valid structured output
  - Prints decoded enums


PHASE 4 - Strict ingestion + one repair retry
--------
Deliverables:
  - Ingestion pipeline:
      1. decode attempt
      2. strict key check ("no extras")
      3. semantic checks (optional)
      4. if any fail -> one retry with "return ONLY valid JSON
         matching schema" and include the invalid output +
         one-line reason
  - Clear error classification:
      - cannot reach server
      - local network permission denied
      - ATS blocked
      - decode/validation failed

Acceptance criteria:
  - Typical "model added prose/markdown" cases get corrected by retry
  - Persistent failures produce a clear error


PHASE 5 - Extract into a Swift Package
--------
Goal: Your real integration path

Deliverables:
  - Swift package with:
      - OllamaClient
      - Contract (schema + enums + mapping)
      - PromptBuilder
      - ClassifierRunner (call -> decode -> validate -> retry)
  - Example iPad app becomes a thin wrapper

Acceptance criteria:
  - Example app depends on the package
  - No inference logic lives in the UI target


PHASE 6 - Groundwork for dynamic template JSON
--------
Goal: Your real use-case

Deliverables:
  - Replace static schema with a schema generator driven by:
      - list of fillable fields
      - per-field enum options
  - Replace static prompt with:
      - template JSON (filled + unfilled parts)
      - per-field options + meanings
  - Keep the same runner pipeline (call -> strict decode -> retry)

Acceptance criteria:
  - Adding a new multiple-choice field requires no changes to
    networking/runner—only data