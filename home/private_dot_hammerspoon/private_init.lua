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

-- Bundles under /System/Applications: use explicit paths for open(), and a
-- stricter "already running" check (see appIsRunning) because hs.application.get
-- can match background-only processes so w/p would skip launch while z/q still work.
local defaultAppPaths = {
  Calendar = '/System/Applications/Calendar.app',
  Messages = '/System/Applications/Messages.app',
  Mail     = '/System/Applications/Mail.app',
}

local function appIsRunning(name)
  local app = hs.application.get(name)
  if not app then
    return false
  end
  if defaultAppPaths[name] then
    local wins = app:allWindows() or {}
    return #wins > 0
  end
  return true
end

-- Short-name hs.application.launchOrFocus can miss apps whose default bundle
-- is under /System/Applications; map those above and use open-by-path.

local function launchAppByNameOrPath(name, opts)
  opts = opts or {}
  local path = opts.appPath or defaultAppPaths[name]
  if path and hs.fs.attributes(path) then
    hs.application.open(path, false)
  else
    hs.application.launchOrFocus(name)
  end
end

local function app(name, opts)
  opts = opts or {}
  return function()
    exitLeader(false)
    launchAppByNameOrPath(name, opts)
  end
end

local function hideAppByName(name)
  local launched = hs.application.get(name)
  if launched then
    launched:hide()
    return true
  end
  return false
end

-- One hide-retry campaign per app name (avoids stacked timers on repeated hotkeys).
local hideCampaignByApp = {}

local function cancelHideAppCampaign(name)
  local c = hideCampaignByApp[name]
  if not c then return end
  if c.startTimer then c.startTimer:stop() end
  if c.repeatTimer then c.repeatTimer:stop() end
  hideCampaignByApp[name] = nil
end

local function hideAppRepeatedly(name, opts)
  opts = opts or {}

  cancelHideAppCampaign(name)

  local interval   = opts.interval or 0.5
  local maxSeconds = opts.maxSeconds or 8
  local startDelay = opts.startDelay or 0
  local elapsed    = 0

  local function armRepeat()
    local repeatTimer
    repeatTimer = hs.timer.doEvery(interval, function()
      elapsed = elapsed + interval

      -- Electron apps often activate a window several seconds after the
      -- process appears. Re-hide repeatedly during the startup window.
      hideAppByName(name)

      if elapsed >= maxSeconds then
        repeatTimer:stop()
        cancelHideAppCampaign(name)
      end
    end)

    -- Try once immediately too, in case Launch Services already registered it.
    hideAppByName(name)

    local entry = hideCampaignByApp[name] or {}
    entry.repeatTimer = repeatTimer
    hideCampaignByApp[name] = entry
  end

  if startDelay > 0 then
    local startTimer = hs.timer.doAfter(startDelay, function()
      local entry = hideCampaignByApp[name]
      if not entry or not entry.startTimer then return end
      entry.startTimer = nil
      armRepeat()
    end)
    hideCampaignByApp[name] = { startTimer = startTimer }
  else
    hideCampaignByApp[name] = {}
    armRepeat()
  end
end

local function launchHiddenIfNotRunning(name, opts)
  opts = opts or {}

  if appIsRunning(name) then
    return false
  end

  launchAppByNameOrPath(name, opts)

  hideAppRepeatedly(name, {
    interval   = opts.interval or 0.5,
    maxSeconds = opts.maxSeconds or 8,
    startDelay = opts.startDelay or 0,
  })

  return true
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
      maxSeconds = opts.hideMaxSeconds or 10,
    })
  end

  return true
end

-- ── Apps ──────────────────────────────────────────────────────────────
leader:bind({}, 'f', app('Finder'))
leader:bind({}, 'g', app('Ghostty'))
leader:bind({}, 'h', app('Hermes'))
leader:bind({}, 'm', app('Mail'))
leader:bind({}, 'o', app('Obsidian'))
leader:bind({}, 's', app('Safari'))
leader:bind({}, 'c', app('Cursor'))

-- CureWise work session:
--   - Launches missing apps only.
--   - Newly launched normal apps are hidden after launch.
--   - Already-running apps are left untouched.
--   - Claude CureWise is launched only if that profile is not already running.
leader:bind({}, 'w', function()
  exitLeader(false)

  launchHiddenIfNotRunning('Mail',     { maxSeconds = 5  })
  launchHiddenIfNotRunning('Calendar', { maxSeconds = 5  })
  launchHiddenIfNotRunning('Messages', { maxSeconds = 5  })

  launchHiddenIfNotRunning('Linear',   { maxSeconds = 5  })
  launchHiddenIfNotRunning('Obsidian', { maxSeconds = 5 })
  launchHiddenIfNotRunning('Slack',    { maxSeconds = 5  })


  launchClaude('curewise', {
    hideAfterLaunch = true,
    hideMaxSeconds = 10,
  })

  hs.alert.show('CureWise work apps checked', 0.8)
end)


leader:bind({}, 'p', function()
  exitLeader(false)

  -- Personal and work overlap intentionally. These launch only if missing;
  -- already-running apps are left as-is.
  launchHiddenIfNotRunning('Mail',     { maxSeconds = 5  })
  launchHiddenIfNotRunning('Calendar', { maxSeconds = 5  })
  launchHiddenIfNotRunning('Messages', { maxSeconds = 5  })

  launchHiddenIfNotRunning('Obsidian', { maxSeconds = 5 })
  launchHiddenIfNotRunning('ChatGPT',  { maxSeconds = 5  })
  launchHiddenIfNotRunning('Spotify',  { maxSeconds = 5  })

  launchClaude('personal', {
    hideAfterLaunch = true,
    hideMaxSeconds = 10,
  })

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
