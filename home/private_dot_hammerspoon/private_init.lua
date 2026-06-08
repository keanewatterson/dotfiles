-- ~/.hammerspoon/init.lua
--
-- Requires: Karabiner-Elements remapping Caps Lock → F18
--
-- Leader key: Caps Lock (via F18)
-- Tap Caps Lock → leader mode (1.5s window)
-- No follow-up  → toggles caps lock state
--
-- ┌─────────────────────────────────────────────┐
-- │  Apps              Scripts                  │
-- │  g  Ghostty        1  start dev container   │
-- │  a  Anthropic ›    2  docker compose up     │
-- │  c  Cursor         3  ssh tunnel            │
-- │  o  Obsidian       4  ollama serve          │
-- │  s  Safari                                  │
-- │  f  Finder                                  │
-- │  m  Mail                                    │
-- │  w  work session                            │
-- │                                             │
-- │  Anthropic sub-mode (after leader → a):     │
-- │  c        CureWise Claude profile           │
-- │  timeout  personal Claude profile           │
-- │  esc      cancel                            │
-- └─────────────────────────────────────────────┘

-- ── Leader ────────────────────────────────────────────────────────────

local leader      = hs.hotkey.modal.new()
local leaderTimer = nil

local function exitLeader(toggleCaps)
  if leaderTimer then leaderTimer:stop(); leaderTimer = nil end
  leader:exit()
  if toggleCaps then
    local next = not hs.hid.capslock.get()
    hs.hid.capslock.set(next)
    hs.alert.show(next and "CAPS ON" or "caps off", 0.8)
  end
end

local function enterLeader()
  leader:enter()
  hs.alert.show("›", 1.5)
  leaderTimer = hs.timer.doAfter(1.5, function()
    exitLeader(true)    -- timed out with no follow-up → caps lock
  end)
end

-- F18 is Caps Lock after Karabiner remapping
hs.hotkey.bind({}, 'f18', enterLeader)
leader:bind({}, 'escape', function() exitLeader(false) end)

-- ── Helpers ───────────────────────────────────────────────────────────

local function app(name)
  return function()
    exitLeader(false)
    hs.application.launchOrFocus(name)
  end
end

local function shell(cmd)
  return function()
    exitLeader(false)
    hs.task.new('/bin/zsh', function(code, _, stderr)
      if code ~= 0 then hs.alert.show('error: ' .. (stderr or '')) end
    end, { '-c', cmd }):start()
  end
end

local function shQuote(s)
  return "'" .. tostring(s):gsub("'", "'\\''") .. "'"
end

local function appIsRunning(name)
  return hs.application.get(name) ~= nil
end

local function hideAppByName(name)
  local launched = hs.application.get(name)
  if launched then
    launched:hide()
    return true
  end
  return false
end

local function hideAppRepeatedly(name, opts)
  opts = opts or {}

  local interval   = opts.interval or 0.5
  local maxSeconds = opts.maxSeconds or 12
  local elapsed    = 0

  local timer
  timer = hs.timer.doEvery(interval, function()
    elapsed = elapsed + interval

    -- Electron apps often activate a window several seconds after the
    -- process appears. Re-hide repeatedly during the startup window.
    hideAppByName(name)

    if elapsed >= maxSeconds then
      timer:stop()
    end
  end)

  -- Try once immediately too, in case Launch Services already registered it.
  hideAppByName(name)
end

local function launchHiddenIfNotRunning(name, opts)
  opts = opts or {}

  if appIsRunning(name) then
    return false
  end

  hs.application.launchOrFocus(name)

  hideAppRepeatedly(name, {
    interval = opts.interval or 0.5,
    maxSeconds = opts.maxSeconds or 12,
  })

  return true
end

-- Slack is stubborn on launch. Keep this intentionally conservative.
-- The previous aggressive version could mistake a partial Slack process for
-- a fully running app and skip launch behavior. This version:
--   1. Checks specifically for visible Slack windows.
--   2. If Slack has no visible windows, calls `open -a Slack`.
--   3. After a delay, repeatedly asks macOS to hide Slack.
--   4. Does not minimize windows or activate Slack/press Cmd-H.
local function slackWindowCount()
  local output = hs.execute([[/usr/bin/osascript -e 'tell application "System Events"
    if exists process "Slack" then
      return count of windows of process "Slack"
    else
      return 0
    end if
  end tell']], true)

  return tonumber(output) or 0
end

local function slackHasWindows()
  return slackWindowCount() > 0
end

local function safeHideSlackRepeatedly(opts)
  opts = opts or {}

  local interval   = opts.interval or 1.0
  local maxSeconds = opts.maxSeconds or 30
  local startDelay = opts.startDelay or 4.0
  local elapsed    = 0

  local function hideOnce()
    local app = hs.application.get('Slack')
    if app then app:hide() end

    hs.task.new('/usr/bin/osascript', nil, {
      '-e', 'tell application "System Events" to if exists process "Slack" then set visible of process "Slack" to false'
    }):start()
  end

  hs.timer.doAfter(startDelay, function()
    local timer
    timer = hs.timer.doEvery(interval, function()
      elapsed = elapsed + interval
      hideOnce()

      if elapsed >= maxSeconds then
        timer:stop()
      end
    end)

    hideOnce()
  end)
end

local function launchSlackHiddenIfNotRunning(opts)
  opts = opts or {}

  -- If Slack has real windows, treat it as already running and leave it alone.
  -- If only helper/background processes exist, still ask macOS to open Slack.
  if not slackHasWindows() then
    hs.execute('/usr/bin/open -a Slack', true)

    safeHideSlackRepeatedly({
      startDelay = opts.startDelay or 5.0,
      interval = opts.interval or 1.0,
      maxSeconds = opts.maxSeconds or 30,
    })

    return true
  end

  return false
end

-- ── Claude / Anthropic profiles ───────────────────────────────────────
--
-- We launch Claude with profile-specific user-data-dir paths.
-- To avoid duplicate profile instances, we detect whether a process already
-- contains that profile path in its command line before running `open -n`.
--
-- Conservative hiding rule:
--   If any Claude instance was already running before launching another
--   profile, do not call app:hide(), because macOS/Hammerspoon cannot
--   reliably hide only one same-bundle Claude profile instance.

local anthropicMode  = hs.hotkey.modal.new()
local anthropicTimer = nil
local HOME           = os.getenv('HOME')

local claudeProfiles = {
  personal = HOME .. '/Library/Application Support/Claude-Keane',
  curewise = HOME .. '/Library/Application Support/Claude',
}

local function anyClaudeRunning()
  return appIsRunning('Claude')
end

local function claudeProfileIsRunning(profile)
  local dir = claudeProfiles[profile]
  if not dir then return false end

  local cmd = string.format("ps ax -o command= | grep -F -- %s | grep -v grep", shQuote(dir))
  local output = hs.execute(cmd, true)
  return output ~= nil and output ~= ''
end

local function launchClaude(profile, opts)
  opts = opts or {}

  if anthropicTimer then anthropicTimer:stop(); anthropicTimer = nil end
  anthropicMode:exit()

  local dir = claudeProfiles[profile]
  if not dir then
    hs.alert.show('Unknown Claude profile: ' .. tostring(profile))
    return false
  end

  if claudeProfileIsRunning(profile) then
    hs.alert.show('Claude ' .. profile .. ' already running', 0.8)
    return false
  end

  local hadAnyClaude = anyClaudeRunning()

  hs.task.new('/bin/zsh', nil, {
    '-c',
    string.format('open -n -a "/Applications/Claude.app" --args --user-data-dir=%s', shQuote(dir))
  }):start()

  if opts.hideAfterLaunch and not hadAnyClaude then
    hideAppRepeatedly('Claude', {
      interval = opts.hideInterval or 0.5,
      maxSeconds = opts.hideMaxSeconds or 15,
    })
  end

  return true
end

-- ── Apps ──────────────────────────────────────────────────────────────

leader:bind({}, 'g', app('Ghostty'))
leader:bind({}, 'f', app('Finder'))
leader:bind({}, 'm', app('Mail'))
leader:bind({}, 'o', app('Obsidian'))
leader:bind({}, 's', app('Safari'))
leader:bind({}, 'c', app('Cursor'))
leader:bind({}, 'v', app('Cursor')) -- optional alias; remove once muscle memory settles

-- CureWise work session:
--   - Launches missing apps only.
--   - Newly launched normal apps are hidden after launch.
--   - Already-running apps are left untouched.
--   - Claude CureWise is launched only if that profile is not already running.
leader:bind({}, 'w', function()
  exitLeader(false)

  launchHiddenIfNotRunning('Linear',   { maxSeconds = 8  })
  launchSlackHiddenIfNotRunning({ startDelay = 5, maxSeconds = 30 })
  launchHiddenIfNotRunning('Mail',     { maxSeconds = 8  })
  launchHiddenIfNotRunning('Calendar', { maxSeconds = 8  })
  launchHiddenIfNotRunning('Obsidian', { maxSeconds = 10 })

  launchClaude('curewise', {
    hideAfterLaunch = true,
    hideMaxSeconds = 15,
  })

  hs.alert.show('CureWise work apps checked', 0.8)
end)


leader:bind({}, 'p', function()
  exitLeader(false)

  -- Personal and work overlap intentionally. These launch only if missing;
  -- already-running apps are left as-is.
  launchHiddenIfNotRunning('Mail',     { maxSeconds = 8  })
  launchHiddenIfNotRunning('Calendar', { maxSeconds = 8  })

  launchClaude('personal', {
    hideAfterLaunch = true,
    hideMaxSeconds = 15,
  })

  launchHiddenIfNotRunning('Obsidian', { maxSeconds = 10 })
  launchHiddenIfNotRunning('ChatGPT',  { maxSeconds = 8  })
  launchHiddenIfNotRunning('Messages', { maxSeconds = 8  })
  launchHiddenIfNotRunning('Hermes',   { maxSeconds = 8  })
  launchHiddenIfNotRunning('Spotify',  { maxSeconds = 8  })

  hs.alert.show('Personal apps checked', 0.8)
end)

-- ── Anthropic sub-mode ────────────────────────────────────────────────
--
--   leader → a → [1.5s timeout]  →  personal  (Claude-Keane profile)
--   leader → a → c               →  CureWise  (Claude profile)
--   leader → a → esc             →  cancel
--
anthropicMode:bind({}, 'c', function() launchClaude('curewise') end)
anthropicMode:bind({}, 'escape', function()
  if anthropicTimer then anthropicTimer:stop(); anthropicTimer = nil end
  anthropicMode:exit()
end)

leader:bind({}, 'a', function()
  exitLeader(false)
  anthropicMode:enter()
  hs.alert.show('anthropic: [c]ureWise  ·  wait=personal', 1.5)
  anthropicTimer = hs.timer.doAfter(1.5, function()
    launchClaude('personal')
  end)
end)

-- ── Scripts ───────────────────────────────────────────────────────────

-- leader:bind({}, '1', shell('docker start my-dev-container'))
-- leader:bind({}, '2', shell('cd ~/Projects && docker compose up -d'))
-- leader:bind({}, '3', shell('ssh -N -L 7860:localhost:7860 your-vps'))
-- leader:bind({}, '4', shell('ollama serve'))
