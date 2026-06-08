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
-- │  t  Ghostty        1  start dev container   │
-- │  c  Claude ›       2  docker compose up     │
-- │  o  Obsidian       3  ssh tunnel            │
-- │  s  Slack          4  ollama serve          │
-- │  f  Finder                                  │
-- │  v  Cursor                                  │
-- │  m  Mail                                    │
-- │  w  work session ›                          │
-- │       Slack + Linear + Claude (CureWise)    │
-- │                                             │
-- │  Claude sub-mode (after leader → c):        │
-- │  c        CureWise profile                  │
-- │  timeout  personal profile                  │
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

-- ── Apps ──────────────────────────────────────────────────────────────

leader:bind({}, 'g', app('Ghostty'))
leader:bind({}, 'f', app('Finder'))
leader:bind({}, 'm', app('Mail'))
leader:bind({}, 'o', app('Obsidian'))
leader:bind({}, 's', app('Safari'))
leader:bind({}, 'v', app('Cursor'))
leader:bind({}, 'w', function()
  exitLeader(false)
  hs.application.launchOrFocus('Slack')
  hs.application.launchOrFocus('Linear')
  launchClaude('curewise')
end)

-- ── Claude sub-mode ───────────────────────────────────────────────────
--
--   leader → c → [1.5s timeout]  →  personal  (Claude-Keane profile)
--   leader → c → c               →  CureWise  (Claude profile)
--   leader → c → esc             →  cancel
--
local claudeMode  = hs.hotkey.modal.new()
local claudeTimer = nil
local HOME        = os.getenv('HOME')

local claudeProfiles = {
  personal = HOME .. '/Library/Application Support/Claude-Keane',
  curewise = HOME .. '/Library/Application Support/Claude',
}

function launchClaude(profile)
  if claudeTimer then claudeTimer:stop(); claudeTimer = nil end
  claudeMode:exit()
  local dir = claudeProfiles[profile]
  hs.task.new('/bin/zsh', nil, {
    '-c',
    string.format('open -n -a "/Applications/Claude.app" --args --user-data-dir="%s"', dir)
  }):start()
end

claudeMode:bind({}, 'c',      function() launchClaude('curewise') end)
claudeMode:bind({}, 'escape', function()
  if claudeTimer then claudeTimer:stop(); claudeTimer = nil end
  claudeMode:exit()
end)

leader:bind({}, 'c', function()
  exitLeader(false)
  claudeMode:enter()
  hs.alert.show('claude: [c]ureWise  ·  wait=personal', 1.5)
  claudeTimer = hs.timer.doAfter(1.5, function()
    launchClaude('personal')
  end)
end)

-- ── Scripts ───────────────────────────────────────────────────────────

-- leader:bind({}, '1', shell('docker start my-dev-container'))
-- leader:bind({}, '2', shell('cd ~/Projects && docker compose up -d'))
-- leader:bind({}, '3', shell('ssh -N -L 7860:localhost:7860 your-vps'))
-- leader:bind({}, '4', shell('ollama serve'))