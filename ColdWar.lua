--[[ ColdWar.lua — Cold War [VIETNAM] (place 13687899540)
   Custom build — Perfectly synced with AmericanCheesecake67 UI
]]

local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local UserInputService  = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting          = game:GetService("Lighting")

local plr    = Players.LocalPlayer
local camera = workspace.CurrentCamera
workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
	if workspace.CurrentCamera then camera = workspace.CurrentCamera end
end)

_G.__CWAR = (_G.__CWAR or 0) + 1
local GEN = _G.__CWAR

local STUDS_PER_M = 3.5714285714285716
local LIMBS = { "Head", "Torso", "Left Arm", "Right Arm", "Left Leg", "Right Leg" }
local LIMBSET = {}
for _, n in ipairs(LIMBS) do LIMBSET[n] = true end

local HAS_DRAWING = (Drawing ~= nil and Drawing.new ~= nil)
local moveMouse
for _, get in ipairs({
	function() return getgenv and getgenv()["mousemoverel"] or nil end,
	function() return getfenv()["mousemoverel"] end,
}) do
	local ok, v = pcall(get)
	if ok and type(v) == "function" then moveMouse = v break end
end

--------------------------------------------------------------------------------
-- CONFIG
--------------------------------------------------------------------------------

local CONFIG = {
	esp         = true, espBox      = true, espName     = true, espInfo     = true,
	espClass    = true, espHealth   = true, espLimbs    = false, espFlags    = true,
	espSkeleton = false, espTracer   = false, espHeadDot  = false, espVisOnly  = false,
	espDimHidden = true, espTeam     = false, espVehicles = true, espEmptyVeh = false,
	espMaxM     = 1000, espTextSize = 13,

	aim         = false, aimActive   = "Hotkey", aimKey      = "MouseButton2",
	aimPart     = "Head", aimFov      = 120, aimSmoothH  = 14, aimSmoothV  = 16,
	aimVisible  = true, aimPredict  = true, aimSticky   = true, aimMaxM     = 600,
	aimCircle   = true, aimDeliver  = "Camera", hum         = true, humReactMin = 80,
	humReactMax = 170, humRampMs   = 180, humMaxDegS  = 420,

	silent      = false, silentFovDeg = 7, silentPart  = "Head", silentChance = 100,
	silentMaxM  = 800, silentLead  = true, silentCircle = true,

	skipDowned  = true, skipSpawn   = true,
	noFog       = false, fullbright  = false, noSuppress  = false,
	panicKey    = "F1",
}

local COL = {
	enemy   = Color3.fromRGB(255, 86, 86), visible = Color3.fromRGB(255, 214, 90),
	team    = Color3.fromRGB(90, 160, 255), text    = Color3.fromRGB(240, 240, 240),
	fov     = Color3.fromRGB(255, 255, 255), silent  = Color3.fromRGB(255, 120, 200),
	veh     = Color3.fromRGB(255, 160, 60), vehTeam = Color3.fromRGB(110, 170, 255),
}

local STATE = {
	enemies   = 0, drawn     = 0, target    = "-", silentTarget = "-",
	bent      = 0, skipped   = 0, noLanding = 0, lastBend  = 0,
	hookNote  = "not installed", weapon    = "-", panelOpen = false,
}

--------------------------------------------------------------------------------
-- GAME HANDLES & UTILS (Logic หลัก)
--------------------------------------------------------------------------------

local GAME = {}
local function req(inst) if not inst then return nil end local ok, m = pcall(require, inst) return ok and m or nil end

local function resolveGame()
	if GAME.ok then return true end
	local shared = ReplicatedStorage:FindFirstChild("Shared")
	local bal = shared and shared:FindFirstChild("Ballistics")
	local src = bal and bal:FindFirstChild("Sources")
	local ps = plr:FindFirstChild("PlayerScripts")
	local bc = ps and ps:FindFirstChild("BallisticsClient")
	GAME.Traj = GAME.Traj or req(bal and bal:FindFirstChild("Trajectory"))
	GAME.WS = GAME.WS or req(src and src:FindFirstChild("WeaponSource"))
	GAME.CF = GAME.CF or req(bc and bc:FindFirstChild("ClientFire"))
	GAME.ok = (GAME.Traj and GAME.WS and GAME.CF) and true or false
	return GAME.ok
end

local COMBAT = { NATO = true, PACT = true }
local function teamName(p) local t = p.Team return t and t.Name or nil end
local function isEnemy(p)
	if p == plr then return false end
	local mine, theirs = teamName(plr), teamName(p)
	return COMBAT[mine] == true and COMBAT[theirs] == true and mine ~= theirs
end
local function isMate(p)
	if p == plr then return false end
	local mine = teamName(plr)
	return COMBAT[mine] == true and teamName(p) == mine
end
local function limbHealth(char, name)
	local part = char:FindFirstChild(name)
	local h = part and part:FindFirstChild("Health")
	if h and h:IsA("NumberValue") then return h.Value, (h:GetAttribute("MaxHealth") or h.Value) end
	return nil
end
local charsFolder = workspace:FindFirstChild("Characters")
local function liveChar(p)
	local char = p.Character
	if not char or not char.Parent then return nil end
	charsFolder = charsFolder or workspace:FindFirstChild("Characters")
	if charsFolder and char.Parent ~= charsFolder then return nil end
	if char:GetAttribute("Ragdolled") ~= nil then return nil end
	local root = char:FindFirstChild("HumanoidRootPart")
	if not root then return nil end
	local hh = limbHealth(char, "Head")
	local th = limbHealth(char, "Torso")
	if (hh and hh <= 0) or (th and th <= 0) then return nil end
	local sum, max = 0, 0
	for _, n in ipairs(LIMBS) do local v, m = limbHealth(char, n) if v then sum = sum + math.max(v, 0) max = max + m end end
	return char, root, sum, max
end
local function isDowned(char) local cv = char:FindFirstChild("CharacterValues") local u = cv and cv:FindFirstChild("Unconscious") return u ~= nil and u.Value == true end
local function hasSpawnShield(char) return char:FindFirstChildOfClass("ForceField") ~= nil end
local function isDisguised(char) return char:GetAttribute("DisguiseName") ~= nil end

local function shootable(p)
	if not isEnemy(p) then return nil end
	local char, root = liveChar(p)
	if not char then return nil end
	if CONFIG.skipDowned and isDowned(char) then return nil end
	if CONFIG.skipSpawn and hasSpawnShield(char) then return nil end
	return char, root
end

local ROLE_PREFIX = { "EastGerman", "WestGer", "NavySeals", "DeltaForce", "Soviet", "Polish", "Czech", "French", "Spetsnaz", "Reserve", "VDV", "VMF", "GRU", "US", "UK", "NG" }
local function roleOf(p)
	local cn = p:GetAttribute("ClassName")
	if type(cn) ~= "string" or cn == "" then local ct = p:GetAttribute("ClassType") return type(ct) == "string" and ct or nil end
	local s = cn
	for _ = 1, 3 do for _, pre in ipairs(ROLE_PREFIX) do if s:sub(1, #pre) == pre and #s > #pre then s = s:sub(#pre + 1) end end end
	return s
end
local function weaponOf(char)
	local tool = char:FindFirstChildOfClass("Tool")
	if tool then return tool.Name end
	for _, k in ipairs(char:GetChildren()) do if k:IsA("Model") and k.Name:sub(-5) == "Model" then return k.Name:sub(1, -6) end end
	return nil
end

-- Ballistics & Silent Aim (The Brain)
local fpCache = { tool = nil, at = 0, fp = nil }
local function fireParamsFor(tool, origin, dir, mi, bi)
	if not resolveGame() then return nil end
	local ok, fp = pcall(GAME.WS.toFireParams, { Tool = tool, MuzzleIndex = mi or 1, BulletIndex = bi or 1, Origin = origin, Direction = dir or Vector3.new(0, 0, -1), Owner = plr })
	return ok and fp or nil
end
local function heldWeapon() local char = plr.Character local tool = char and char:FindFirstChildOfClass("Tool") if tool and tool:GetAttribute("ToolType") == "Weapon" then return tool end return nil end
local function cachedFireParams()
	local tool = heldWeapon() local now = os.clock()
	if tool ~= fpCache.tool or now - fpCache.at > 1 then fpCache.tool, fpCache.at = tool, now fpCache.fp = tool and fireParamsFor(tool, camera.CFrame.Position) or nil end
	return fpCache.fp
end

local visParams = RaycastParams.new() visParams.FilterType = Enum.RaycastFilterType.Exclude visParams.IgnoreWater = true
local visAt = 0
local function refreshVisParams()
	local now = os.clock() if now - visAt < 1 then return end
	visAt = now local list = { plr.Character } local ign = workspace:FindFirstChild("Ignore") if ign then table.insert(list, ign) end visParams.FilterDescendantsInstances = list
end
local function seen(char, part) local o = camera.CFrame.Position local fp = cachedFireParams() local params = fp and fp.RaycastParams or visParams local r = workspace:Raycast(o, part.Position - o, params) return (r == nil) or r.Instance:IsDescendantOf(char) end
local function trajOf(o, dir, w) return GAME.Traj.new({ Origin = o, Direction = dir, MuzzleSpeed = w.MuzzleSpeed, K = w.K }) end

local function solveArc(o, T, w, vel)
	local tr = trajOf(o, Vector3.new(0, 0, -1), w)
	local t = GAME.Traj.GetTimeForDistance(tr, (T - o).Magnitude)
	if not t then return nil end
	local aim
	for _ = 1, 6 do
		local Tl = vel and (T + vel * t) or T
		aim = (Tl - o) + Vector3.new(0, tr.Gravity * 0.5 * t * t, 0)
		t = GAME.Traj.GetTimeForDistance(tr, aim.Magnitude)
		if not t then return nil end
	end
	return aim.Unit, t
end

local function arcLands(o, dir, t, fp, char, vel)
	local tr = trajOf(o, dir, fp.Weapon) local last = o local N = 12
	for i = 1, N do
		local tt = t * 1.08 * i / N
		local p = GAME.Traj.GetPositionAtTime(tr, tt)
		if vel then p = p - vel * tt end
		local r = workspace:Raycast(last, p - last, fp.RaycastParams)
		if r then
			if r.Instance:IsDescendantOf(char) and LIMBSET[r.Instance.Name] then return r.Instance.Name end
			return nil
		end
		last = p
	end
	return nil
end
local function leadOf(root, on) if not on then return nil end local v = root.AssemblyLinearVelocity if v.Magnitude > 80 or v.Magnitude < 0.5 then return nil end return v end

local function centre() local vp = camera.ViewportSize return Vector2.new(vp.X / 2, vp.Y / 2) end
local function focalPx() local vp = camera.ViewportSize return (vp.Y / 2) / math.tan(math.rad(camera.FieldOfView) / 2) end
local function degToPx(deg) if deg >= 89 then return 4000 end return focalPx() * math.tan(math.rad(deg)) end
local function angleTo(pos) local cf = camera.CFrame local d = (pos - cf.Position) if d.Magnitude < 1e-3 then return 0 end return math.deg(math.acos(math.clamp(cf.LookVector:Dot(d.Unit), -1, 1))) end

local PART_ORDER = { Head = { "Head", "Torso", "Left Arm", "Right Arm" }, Torso = { "Torso", "Head", "Left Leg", "Right Leg" }, Nearest = nil, Random = nil }
local function partsFor(char, mode)
	if mode == "Random" then
		local list = { "Head", "Torso" } if math.random() < 0.5 then list = { "Torso", "Head" } end
		table.insert(list, "Left Arm") table.insert(list, "Right Arm") return list
	end
	if mode == "Nearest" then
		local best, bestA
		for _, n in ipairs({ "Head", "Torso" }) do
			local part = char:FindFirstChild(n)
			if part then local a = angleTo(part.Position) if not bestA or a < bestA then best, bestA = n, a end end
		end
		local other = (best == "Head") and "Torso" or "Head"
		return { best or "Head", other, "Left Arm", "Right Arm" }
	end
	return PART_ORDER[mode] or PART_ORDER.Head
end

local function silentBend(tool, mi, bi, origin, dir0)
	if not CONFIG.silent then return nil end
	if CONFIG.silentChance < 100 and math.random(1, 100) > CONFIG.silentChance then STATE.skipped = STATE.skipped + 1 return nil end
	local fp = fireParamsFor(tool, origin, dir0, mi, bi)
	if not fp or not fp.Weapon or (fp.Weapon.MuzzleSpeed or 0) <= 0 then return nil end
	if fp.Weapon.Explosive then return nil end
	local maxStuds = CONFIG.silentMaxM * STUDS_PER_M local fovDeg = CONFIG.silentFovDeg local cands = {}
	for _, p in ipairs(Players:GetPlayers()) do
		local char, root = shootable(p)
		if char then
			local head = char:FindFirstChild("Head") or root local d = (head.Position - origin).Magnitude
			if d <= maxStuds then
				local a = angleTo(head.Position)
				if fovDeg >= 180 or a <= fovDeg then table.insert(cands, { p = p, char = char, root = root, a = a }) end
			end
		end
	end
	if #cands == 0 then return nil end
	table.sort(cands, function(x, y) return x.a < y.a end)
	for i = 1, math.min(#cands, 3) do
		local c = cands[i] local vel = leadOf(c.root, CONFIG.silentLead)
		for _, n in ipairs(partsFor(c.char, CONFIG.silentPart)) do
			local part = c.char:FindFirstChild(n)
			if part then
				local dir, t = solveArc(origin, part.Position, fp.Weapon, vel)
				if dir and arcLands(origin, dir, t, fp, c.char, vel) then
					STATE.bent = STATE.bent + 1 STATE.lastBend = math.deg(math.acos(math.clamp(dir0.Unit:Dot(dir), -1, 1))) STATE.silentTarget = c.p.Name .. " / " .. n
					return dir
				end
			end
		end
	end
	STATE.noLanding = STATE.noLanding + 1 return nil
end

_G.__CWAR_LIVE = { bend = silentBend, gen = GEN }
local function installSilent()
	if not resolveGame() then STATE.hookNote = "game modules not found" return false end
	local H = _G.__CWAR_HOOK local CF = GAME.CF
	if H and H.cf == CF and CF[H.key] == H.wrapper then STATE.hookNote = "active (" .. H.key .. ")" return true end
	local key
	for k, v in pairs(CF) do if k ~= "fire" and type(v) == "function" and not (H and v == H.wrapper) then if key then STATE.hookNote = "ambiguous volley" return false end key = k end end
	if not key then STATE.hookNote = "volley not found" return false end
	local orig = CF[key]
	local wrapper
	wrapper = function(tool, mi, bi, origin, dirs, opts, ...)
		local live = _G.__CWAR_LIVE
		if live and live.bend and opts == nil and typeof(tool) == "Instance" and typeof(origin) == "Vector3" and type(dirs) == "table" and dirs[1] then
			local ok, dir = pcall(live.bend, tool, mi, bi, origin, dirs[1])
			if ok and typeof(dir) == "Vector3" then for i = 1, #dirs do dirs[i] = dir end end
		end
		return orig(tool, mi, bi, origin, dirs, opts, ...)
	end
	CF[key] = wrapper
	_G.__CWAR_HOOK = { cf = CF, key = key, orig = orig, wrapper = wrapper }
	STATE.hookNote = "active (" .. key .. ")"
	return true
end

-- Drawing & Render
local pool = {}
if _G.__CWAR_POOL then for _, obj in ipairs(_G.__CWAR_POOL) do pcall(function() obj:Remove() end) end end
_G.__CWAR_POOL = pool
local function make(kind, props)
	if not HAS_DRAWING then return nil end
	local ok, obj = pcall(function() return Drawing.new(kind) end)
	if not ok or not obj then return nil end
	obj.Visible = false
	for k, v in pairs(props or {}) do pcall(function() obj[k] = v end) end
	table.insert(pool, obj) return obj
end
local drawn, vdrawn = {}, {}
local function objectsFor(p)
	local set = drawn[p] if set then return set end
	set = { outline = make("Square", { Thickness = 3, Filled = false, ZIndex = 1, Color = Color3.new(0, 0, 0), Transparency = 0.6 }), box = make("Square", { Thickness = 1, Filled = false, ZIndex = 2 }), hpBg = make("Square", { Filled = true, ZIndex = 1, Color = Color3.new(0, 0, 0), Transparency = 0.6 }), hp = make("Square", { Filled = true, ZIndex = 2 }), name = make("Text", { Size = 13, Center = true, Outline = true, ZIndex = 3 }), role = make("Text", { Size = 12, Center = true, Outline = true, ZIndex = 3 }), info = make("Text", { Size = 12, Center = true, Outline = true, ZIndex = 3 }), flags = make("Text", { Size = 12, Center = false, Outline = true, ZIndex = 3 }), tracer = make("Line", { Thickness = 1, ZIndex = 1 }), head = make("Circle", { Thickness = 1, Filled = false, NumSides = 14, ZIndex = 3 }), bones = {} }
	for i = 1, 8 do set.bones[i] = make("Line", { Thickness = 1, ZIndex = 2 }) end
	drawn[p] = set return set
end
local function hideSet(set)
	for k, obj in pairs(set) do if k == "bones" then for _, b in ipairs(obj) do if b then b.Visible = false end end elseif obj and obj.Visible ~= nil then obj.Visible = false end end
end
local function hideAll() for _, set in pairs(drawn) do hideSet(set) end for _, t in pairs(vdrawn) do if t then t.Visible = false end end end
local fovCircle = make("Circle", { Thickness = 1, NumSides = 48, Filled = false, Transparency = 0.5, ZIndex = 1 })
local silentCircle = make("Circle", { Thickness = 1, NumSides = 48, Filled = false, Transparency = 0.6, ZIndex = 1 })
local function screenBox(char)
	local head = char:FindFirstChild("Head") local ll, rl = char:FindFirstChild("Left Leg"), char:FindFirstChild("Right Leg")
	if not head or not (ll or rl) then return nil end
	local low = ll or rl if ll and rl then low = (ll.Position.Y <= rl.Position.Y) and ll or rl end
	local top = head.Position + Vector3.new(0, head.Size.Y / 2 + 0.3, 0) local bot = low.Position - Vector3.new(0, low.Size.Y / 2, 0)
	local sTop = camera:WorldToViewportPoint(top) local sBot = camera:WorldToViewportPoint(bot)
	if sTop.Z <= 0 or sBot.Z <= 0 then return nil end
	local h = math.abs(sBot.Y - sTop.Y) if h < 1 then return nil end
	local w = math.max(h * 0.5, math.abs(sBot.X - sTop.X)) local cx = (sTop.X + sBot.X) / 2
	return cx - w / 2, math.min(sTop.Y, sBot.Y), w, h
end
local function boneEnds(char)
	local t = char:FindFirstChild("Torso") local h = char:FindFirstChild("Head")
	if not t or not h then return nil end
	local la, ra = char:FindFirstChild("Left Arm"), char:FindFirstChild("Right Arm") local lg, rg = char:FindFirstChild("Left Leg"), char:FindFirstChild("Right Leg")
	local top = (t.CFrame * CFrame.new(0, 1, 0)).Position local bot = (t.CFrame * CFrame.new(0, -1, 0)).Position
	local function ends(part) if not part then return nil end return (part.CFrame * CFrame.new(0, 0.8, 0)).Position, (part.CFrame * CFrame.new(0, -1, 0)).Position end
	local la1, la2 = ends(la) local ra1, ra2 = ends(ra) local lg1, lg2 = ends(lg) local rg1, rg2 = ends(rg)
	return { { h.Position, top }, { top, bot }, la1 and ra1 and { la1, ra1 } or nil, lg1 and rg1 and { lg1, rg1 } or nil, la1 and { la1, la2 } or nil, ra1 and { ra1, ra2 } or nil, lg1 and { lg1, lg2 } or nil, rg1 and { rg1, rg2 } or nil }
end
local visCache = setmetatable({}, { __mode = "k" })
local function visibleCached(p, char, part)
	local now = os.clock() local c = visCache[p]
	if c and now - c.at < 0.12 then return c.v end
	local v = seen(char, part) visCache[p] = { at = now + math.random() * 0.04, v = v }
	return v
end
local function renderVehicles(mid)
	local V = workspace:FindFirstChild("Vehicles") local used = {}
	if CONFIG.espVehicles and V then
		local mine = teamName(plr) local camPos = camera.CFrame.Position local maxStuds = CONFIG.espMaxM * STUDS_PER_M
		for _, m in ipairs(V:GetChildren()) do
			if m:IsA("Model") and m:GetAttribute("Wrecked") ~= true then
				local crew = m:GetAttribute("CrewTeam") local side = crew or m:GetAttribute("Team")
				local hostile = side ~= nil and COMBAT[side] and side ~= mine local manned = crew ~= nil
				if (manned or CONFIG.espEmptyVeh) and (hostile or CONFIG.espTeam) then
					local root = m:FindFirstChild("RootPart") or m.PrimaryPart
					if root and root:IsA("BasePart") then
						local d = (root.Position - camPos).Magnitude
						if d <= maxStuds then
							local sp = camera:WorldToViewportPoint(root.Position + Vector3.new(0, 4, 0))
							if sp.Z > 0 then
								local t = vdrawn[m]
								if not t then t = make("Text", { Size = 13, Center = true, Outline = true, ZIndex = 3 }) vdrawn[m] = t end
								if t then
									t.Text = string.format("%s  %s  %dm%s", tostring(m:GetAttribute("VehicleName") or m.Name), tostring(m:GetAttribute("VehicleType") or ""), math.floor(d / STUDS_PER_M), manned and "" or "  (empty)")
									t.Position = Vector2.new(sp.X, sp.Y) t.Color = hostile and COL.veh or COL.vehTeam t.Size = math.max(12, CONFIG.espTextSize) t.Visible = true used[m] = true
								end
							end
						end
					end
				end
			end
		end
	end
	for m, t in pairs(vdrawn) do if not used[m] then if t then t.Visible = false end if not m.Parent then pcall(function() t:Remove() end) vdrawn[m] = nil end end end
end
local function renderPass()
	if _G.__CWAR ~= GEN then return end
	refreshVisParams() local mid = centre()
	if fovCircle then fovCircle.Visible = CONFIG.aim and CONFIG.aimCircle if fovCircle.Visible then fovCircle.Position = mid fovCircle.Radius = CONFIG.aimFov fovCircle.Color = COL.fov end end
	if silentCircle then silentCircle.Visible = CONFIG.silent and CONFIG.silentCircle and CONFIG.silentFovDeg < 89 if silentCircle.Visible then silentCircle.Position = mid silentCircle.Radius = degToPx(CONFIG.silentFovDeg) silentCircle.Color = COL.silent end end
	if not CONFIG.esp or not HAS_DRAWING then hideAll() STATE.drawn = 0 return end
	local camPos = camera.CFrame.Position local maxStuds = CONFIG.espMaxM * STUDS_PER_M local count, enemies = 0, 0 local txt = math.max(12, math.floor(CONFIG.espTextSize))
	for _, p in ipairs(Players:GetPlayers()) do
		local set = objectsFor(p) local shown = false local enemy = isEnemy(p)
		if enemy then enemies = enemies + 1 end
		if set.box and (enemy or (CONFIG.espTeam and isMate(p))) then
			local char, root, hp, maxHp = liveChar(p)
			if char then
				local dist = (camPos - root.Position).Magnitude
				if dist <= maxStuds then
					local head = char:FindFirstChild("Head") or root local vis = enemy and visibleCached(p, char, head) or false
					if vis or not CONFIG.espVisOnly or not enemy then
						local x, y, w, h = screenBox(char)
						if x then
							count = count + 1 shown = true local col = (not enemy) and COL.team or (vis and COL.visible or COL.enemy)
							local alpha = (vis or not enemy or not CONFIG.espDimHidden) and 1 or 0.55
							if CONFIG.espBox then set.outline.Position = Vector2.new(x, y) set.outline.Size = Vector2.new(w, h) set.outline.Transparency = 0.6 * alpha set.outline.Visible = true set.box.Position = Vector2.new(x, y) set.box.Size = Vector2.new(w, h) set.box.Color = col set.box.Transparency = alpha set.box.Visible = true else set.outline.Visible = false set.box.Visible = false end
							if CONFIG.espHealth and maxHp > 0 then local frac = math.clamp(hp / maxHp, 0, 1) set.hpBg.Position = Vector2.new(x - 6, y) set.hpBg.Size = Vector2.new(3, h) set.hpBg.Visible = true set.hp.Position = Vector2.new(x - 6, y + h * (1 - frac)) set.hp.Size = Vector2.new(3, h * frac) set.hp.Color = Color3.fromRGB(255, 70, 70):Lerp(Color3.fromRGB(90, 235, 110), frac) set.hp.Visible = true else set.hpBg.Visible = false set.hp.Visible = false end
							local nameY = y - txt - 2
							if CONFIG.espName then set.name.Text = (p.DisplayName ~= "" and p.DisplayName) or p.Name set.name.Size = txt set.name.Position = Vector2.new(x + w / 2, nameY) set.name.Color = COL.text set.name.Transparency = alpha set.name.Visible = true else set.name.Visible = false end
							local role = CONFIG.espClass and roleOf(p) or nil
							if role then set.role.Text = role set.role.Size = math.max(12, txt - 1) set.role.Position = Vector2.new(x + w / 2, nameY - txt) set.role.Color = col set.role.Transparency = alpha set.role.Visible = true else set.role.Visible = false end
							if CONFIG.espInfo or CONFIG.espLimbs then
								local parts = {}
								if CONFIG.espInfo then table.insert(parts, math.floor(dist / STUDS_PER_M) .. "m") local wpn = weaponOf(char) if wpn then table.insert(parts, wpn) end end
								if CONFIG.espLimbs then local hh = limbHealth(char, "Head") local th = limbHealth(char, "Torso") table.insert(parts, "H" .. math.floor(hh or 0) .. " T" .. math.floor(th or 0)) end
								set.info.Text = table.concat(parts, "  ") set.info.Size = math.max(12, txt - 1) set.info.Position = Vector2.new(x + w / 2, y + h + 1) set.info.Color = COL.text set.info.Transparency = alpha set.info.Visible = true
							else set.info.Visible = false end
							if CONFIG.espFlags then
								local f = {}
								if isDowned(char) then table.insert(f, "DOWNED") end if hasSpawnShield(char) then table.insert(f, "SPAWN") end if isDisguised(char) then table.insert(f, "DISGUISED") end if char:GetAttribute("InVehicle") ~= nil then table.insert(f, "VEHICLE") end
								if #f > 0 then set.flags.Text = table.concat(f, "\n") set.flags.Size = 12 set.flags.Position = Vector2.new(x + w + 4, y) set.flags.Color = COL.visible set.flags.Transparency = alpha set.flags.Visible = true else set.flags.Visible = false end
							else set.flags.Visible = false end
							if CONFIG.espTracer then set.tracer.From = Vector2.new(mid.X, camera.ViewportSize.Y) set.tracer.To = Vector2.new(x + w / 2, y + h) set.tracer.Color = col set.tracer.Transparency = alpha set.tracer.Visible = true else set.tracer.Visible = false end
							if CONFIG.espHeadDot then local sp = camera:WorldToViewportPoint(head.Position) if sp.Z > 0 then set.head.Position = Vector2.new(sp.X, sp.Y) set.head.Radius = math.max(2, h * 0.07) set.head.Color = col set.head.Transparency = alpha set.head.Visible = true else set.head.Visible = false end else set.head.Visible = false end
							local bones = CONFIG.espSkeleton and boneEnds(char) or nil
							for i = 1, 8 do
								local line = set.bones[i] local seg = bones and bones[i]
								if line and seg then local a = camera:WorldToViewportPoint(seg[1]) local b = camera:WorldToViewportPoint(seg[2]) if a.Z > 0 and b.Z > 0 then line.From = Vector2.new(a.X, a.Y) line.To = Vector2.new(b.X, b.Y) line.Color = col line.Transparency = alpha line.Visible = true else line.Visible = false end elseif line then line.Visible = false end
							end
						end
					end
				end
			end
		end
		if not shown then hideSet(set) end
	end
	STATE.drawn = count STATE.enemies = enemies renderVehicles(mid)
end
Players.PlayerRemoving:Connect(function(p) local set = drawn[p] if set then hideSet(set) drawn[p] = nil end end)

-- Aim
local function keyFromName(name) if type(name) ~= "string" then return nil end if name:sub(1, 11) == "MouseButton" then return Enum.UserInputType[name] end return Enum.KeyCode[name] end
local function hotkeyHeld(name) local k = keyFromName(name) if not k then return false end local ok, held = pcall(function() if k.EnumType == Enum.UserInputType then return UserInputService:IsMouseButtonPressed(k) end return UserInputService:IsKeyDown(k) end) return ok and held or false end
local function aimActive()
	if not CONFIG.aim then return false end
	if CONFIG.aimActive == "Always" then return true end
	if CONFIG.aimActive == "While firing" then return UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) end
	return hotkeyHeld(CONFIG.aimKey)
end
local function approach(smooth, dt) local base = 1 / math.max(1, smooth) return 1 - (1 - base) ^ math.max(dt * 60, 0.0001) end
local function angleDelta(a, b) local d = (b - a) % (math.pi * 2) if d > math.pi then d = d - math.pi * 2 end return d end
local function aimPointFor(part, root)
	local camPos = camera.CFrame.Position if not CONFIG.aimPredict then return part.Position end
	local fp = cachedFireParams() if not fp or not fp.Weapon or (fp.Weapon.MuzzleSpeed or 0) <= 0 then return part.Position end
	local vel = leadOf(root, true) local dir = solveArc(camPos, part.Position, fp.Weapon, vel)
	if not dir then return part.Position end
	return camPos + dir * (part.Position - camPos).Magnitude
end
local function aimPartOf(char) if CONFIG.aimPart == "Torso" then return char:FindFirstChild("Torso") or char:FindFirstChild("Head") end if CONFIG.aimPart == "Nearest" then local h, t = char:FindFirstChild("Head"), char:FindFirstChild("Torso") if h and t then return (angleTo(h.Position) <= angleTo(t.Position)) and h or t end end return char:FindFirstChild("Head") or char:FindFirstChild("Torso") end
local function pickAimTarget(sticky)
	local mid = centre() local maxStuds = CONFIG.aimMaxM * STUDS_PER_M local camPos = camera.CFrame.Position local best, bestPx
	for _, p in ipairs(Players:GetPlayers()) do
		local char, root = shootable(p)
		if char then
			local part = aimPartOf(char)
			if part and (part.Position - camPos).Magnitude <= maxStuds then
				local sp = camera:WorldToViewportPoint(part.Position)
				if sp.Z > 0 then
					local px = (Vector2.new(sp.X, sp.Y) - mid).Magnitude local limit = (sticky == p) and CONFIG.aimFov * 1.35 or CONFIG.aimFov
					if px <= limit and ((not CONFIG.aimVisible) or seen(char, part)) then if not bestPx or px < bestPx or sticky == p then best, bestPx = { player = p, part = part, root = root, px = px }, px if sticky == p then return best end end end
				end
			end
		end
	end
	return best
end
local stickyTarget, lockedAt, reactUntil = nil, 0, 0
local function aimPass(dt)
	if _G.__CWAR ~= GEN then return end
	if not aimActive() then STATE.target, stickyTarget = "-", nil return end
	local nowMs = os.clock() * 1000 local pick = pickAimTarget(CONFIG.aimSticky and stickyTarget or nil)
	if not pick then STATE.target, stickyTarget = "-", nil return end
	if pick.player ~= stickyTarget then
		local lo = math.min(CONFIG.humReactMin, CONFIG.humReactMax) local hi = math.max(CONFIG.humReactMin, CONFIG.humReactMax)
		reactUntil = (CONFIG.hum and hi > 0) and (nowMs + math.random(lo, hi)) or 0 lockedAt = nowMs
	end
	stickyTarget = pick.player STATE.target = pick.player.Name
	if reactUntil > nowMs then return end
	local smoothH, smoothV = CONFIG.aimSmoothH, CONFIG.aimSmoothV
	if CONFIG.hum and CONFIG.humRampMs > 0 then local age = nowMs - lockedAt if age < CONFIG.humRampMs then local slow = 3 - 2 * (age / CONFIG.humRampMs) smoothH, smoothV = smoothH * slow, smoothV * slow end end
	local cf = camera.CFrame local pitchNow, yawNow = cf:ToOrientation()
	local want = CFrame.lookAt(cf.Position, aimPointFor(pick.part, pick.root)) local wantPitch, wantYaw = want:ToOrientation()
	local dYaw, dPitch = angleDelta(yawNow, wantYaw), angleDelta(pitchNow, wantPitch)
	local moveYaw, movePitch = dYaw * approach(smoothH, dt), dPitch * approach(smoothV, dt)
	if CONFIG.hum and CONFIG.humMaxDegS > 0 then
		local cap = math.rad(CONFIG.humMaxDegS) * dt local mag = math.sqrt(moveYaw * moveYaw + movePitch * movePitch)
		if mag > cap and mag > 0 then local k = cap / mag moveYaw, movePitch = moveYaw * k, movePitch * k end
	end
	if CONFIG.aimDeliver == "Mouse" and moveMouse then
		local dx, dy = -moveYaw / 0.007, -movePitch / 0.007
		if math.abs(dx) >= 1 or math.abs(dy) >= 1 then pcall(function() moveMouse(math.floor(dx + 0.5), math.floor(dy + 0.5)) end) end
	else
		camera.CFrame = CFrame.new(cf.Position) * CFrame.fromOrientation(pitchNow + movePitch, yawNow + moveYaw, 0)
	end
end

-- World
local WORLD = { atm = {}, light = {}, fx = {} }
local function worldPass()
	if _G.__CWAR ~= GEN then return end
	local atm = Lighting:FindFirstChildOfClass("Atmosphere")
	if atm then
		if CONFIG.noFog then if atm.Density ~= 0 then WORLD.atm.Density = atm.Density end if atm.Haze ~= 0 then WORLD.atm.Haze = atm.Haze end atm.Density, atm.Haze = 0, 0 WORLD.atmOn = true
		elseif WORLD.atmOn then if WORLD.atm.Density then atm.Density = WORLD.atm.Density end if WORLD.atm.Haze then atm.Haze = WORLD.atm.Haze end WORLD.atmOn = false end
	end
	local FB = { Ambient = Color3.fromRGB(178, 178, 178), OutdoorAmbient = Color3.fromRGB(178, 178, 178), GlobalShadows = false }
	if CONFIG.fullbright then for k, v in pairs(FB) do if Lighting[k] ~= v then WORLD.light[k] = Lighting[k] Lighting[k] = v end end WORLD.lightOn = true
	elseif WORLD.lightOn then for k, v in pairs(WORLD.light) do Lighting[k] = v end WORLD.light = {} WORLD.lightOn = false end
	if CONFIG.noSuppress then for _, n in ipairs({ "SuppressionDepthOfField", "Blur" }) do local e = Lighting:FindFirstChild(n) if e and e.Enabled then WORLD.fx[e] = true e.Enabled = false end end WORLD.fxOn = true
	elseif WORLD.fxOn then for e in pairs(WORLD.fx) do if e.Parent then e.Enabled = true end end WORLD.fx = {} WORLD.fxOn = false end
end

--------------------------------------------------------------------------------
-- INIT: UI (Final Synced Version)
--------------------------------------------------------------------------------

-- ใช้ Cache Buster ต่อท้าย URL ป้องกันติดแคช GitHub
local UI_URL = "https://raw.githubusercontent.com/AmericanCheesecake67/AmericanCheesecake-ui/refs/heads/main/ui-template.lua?t=" .. tostring(os.time())
local UI_LOADED, UITemplate = pcall(function() return loadstring(game:HttpGet(UI_URL))() end)

if not UI_LOADED or not UITemplate then
	error("[ColdWar] Failed to load UI from GitHub. Check the URL or your internet connection.")
end

-- ดึงรูปโปรไฟล์ผู้เล่น (Avatar Headshot)
local userThumbnail = "rbxthumb://type=AvatarHeadShot&id=" .. tostring(plr.UserId) .. "&w=150&h=150"

-- สร้าง Window (ปล่อยให้ Template จัดการ ToggleKey เองทั้งหมด)
local win = UITemplate:CreateWindow({
	Title = "COLDWAR | AmericanCheesecake67",
	ToggleKey = Enum.KeyCode.Home,
	ButtonImage = userThumbnail,
})

-- ใช้ CreateSection ตาม Template
local espSection = win:CreateSection("ESP")
espSection:AddToggle("ESP Master", CONFIG.esp, function(v) CONFIG.esp = v end)
espSection:AddToggle("Box", CONFIG.espBox, function(v) CONFIG.espBox = v end)
espSection:AddToggle("Name", CONFIG.espName, function(v) CONFIG.espName = v end)
espSection:AddToggle("Class", CONFIG.espClass, function(v) CONFIG.espClass = v end)
espSection:AddToggle("Health", CONFIG.espHealth, function(v) CONFIG.espHealth = v end)
espSection:AddToggle("Skeleton", CONFIG.espSkeleton, function(v) CONFIG.espSkeleton = v end)
espSection:AddToggle("Tracer", CONFIG.espTracer, function(v) CONFIG.espTracer = v end)

local filterSection = win:CreateSection("ESP FILTER")
filterSection:AddToggle("Visible only", CONFIG.espVisOnly, function(v) CONFIG.espVisOnly = v end)
filterSection:AddToggle("Teammates", CONFIG.espTeam, function(v) CONFIG.espTeam = v end)
filterSection:AddSlider("Range (m)", 50, 1500, CONFIG.espMaxM, function(v) CONFIG.espMaxM = v end)
filterSection:AddColorBox("Enemy Color", COL.enemy, function(c) COL.enemy = c end)
filterSection:AddColorBox("Visible Color", COL.visible, function(c) COL.visible = c end)

local aimSection = win:CreateSection("AIMBOT")
aimSection:AddToggle("Aimbot", CONFIG.aim, function(v) CONFIG.aim = v end)
aimSection:AddDropdown("Key", { "MouseButton2", "MouseButton1", "LeftShift", "E", "Q", "C" }, CONFIG.aimKey, function(v) CONFIG.aimKey = v end)
aimSection:AddDropdown("Target Part", { "Head", "Torso", "Nearest" }, CONFIG.aimPart, function(v) CONFIG.aimPart = v end)
aimSection:AddToggle("Predict (Bullet Drop/Lead)", CONFIG.aimPredict, function(v) CONFIG.aimPredict = v end)

local tuneSection = win:CreateSection("AIM TUNING")
tuneSection:AddSlider("FOV (px)", 5, 600, CONFIG.aimFov, function(v) CONFIG.aimFov = v end)
tuneSection:AddSlider("Smooth H", 1, 100, CONFIG.aimSmoothH, function(v) CONFIG.aimSmoothH = v end)
tuneSection:AddSlider("Smooth V", 1, 100, CONFIG.aimSmoothV, function(v) CONFIG.aimSmoothV = v end)

local silSection = win:CreateSection("SILENT AIM")
silSection:AddToggle("Silent Aim", CONFIG.silent, function(v) CONFIG.silent = v if v then installSilent() end end)
silSection:AddDropdown("Hit Part", { "Head", "Torso", "Nearest", "Random" }, CONFIG.silentPart, function(v) CONFIG.silentPart = v end)
silSection:AddSlider("FOV (deg)", 1, 180, CONFIG.silentFovDeg, function(v) CONFIG.silentFovDeg = v end)
silSection:AddSlider("Hit Chance %", 1, 100, CONFIG.silentChance, function(v) CONFIG.silentChance = v end)

local worldSection = win:CreateSection("WORLD")
worldSection:AddToggle("No Fog", CONFIG.noFog, function(v) CONFIG.noFog = v end)
worldSection:AddToggle("Fullbright", CONFIG.fullbright, function(v) CONFIG.fullbright = v end)
worldSection:AddToggle("No Suppression", CONFIG.noSuppress, function(v) CONFIG.noSuppress = v end)

--------------------------------------------------------------------------------
-- LOOPS & BINDINGS
--------------------------------------------------------------------------------

RunService:BindToRenderStep("CWAim", Enum.RenderPriority.Camera.Value + 1, function(dt) pcall(aimPass, dt) end)
RunService:BindToRenderStep("CWESP", Enum.RenderPriority.Camera.Value + 2, function() pcall(renderPass) pcall(worldPass) end)

-- Panic Key (F1)
UserInputService.InputBegan:Connect(function(input, typing)
	if _G.__CWAR ~= GEN or typing then return end
	local k = keyFromName(CONFIG.panicKey)
	if k and input.KeyCode == k then
		CONFIG.aim, CONFIG.silent = false, false
	end
end)

if CONFIG.silent then installSilent() end
print("[coldwar] Loaded perfectly. UI is managed by the template.")
