local Players=game:GetService("Players")
local RunService=game:GetService("RunService")
local UIS=game:GetService("UserInputService")
local VIM=game:GetService("VirtualInputManager")
local GuiService=game:GetService("GuiService")
local Workspace=game:GetService("Workspace")

local LP=Players.LocalPlayer
local PG=LP:WaitForChild("PlayerGui")
local Camera=Workspace.CurrentCamera

local AUTO_FIRE=false
local HOLD_FIRE=false
local TEAM_CHECK=true
local WALL_CHECK=true
local DRAG_MODE=false
local PULL_AIM=false
local AUTO_SHOULDER=true
local COUNTER_STRAFE=true
local CIRCLE_STRAFE=true
local MOVEMENT_RANGE_VISIBLE=true

local FIRE_DELAY=0.15
local KILL_SWITCH_DELAY_MIN=0.12
local KILL_SWITCH_DELAY_MAX=0.30
local COMBAT_LOCK_LOST_GRACE=0.35
local SEEN_HIGHLIGHT_TIME=1.50
local SEEN_SCAN_INTERVAL=0.05
local MAX_DISTANCE=500
local SPREAD_MULTIPLIER=0.45

local MEMORY_TIME=10
local REACQUIRE_HOLD=0.30

local HYSTERESIS_HOLD_TIME=0.16
local HYSTERESIS_RETURN_WINDOW=0.55

local PEEK_WINDOW=0.55
local PEEK_REACQUIRE_HOLD=0.12
local PEEK_WAIT_TIME=0.25
local PEEK_SAMPLE_LIMIT=5

local TRANSPARENCY_LIMIT=0.90
local TRANSPARENT_RATIO=0.75

local NEAR_DISTANCE=15
local MID_DISTANCE=75
local FAR_DISTANCE=200
local NEAR_RATIO=1.50
local MID_RATIO=1.55
local FAR_RATIO=1.15
local MIN_SPREAD_PX=0.8
local MAX_SPREAD_PX=30

local CLOSE_SPREAD_END=40
local CLOSE_SPREAD_BONUS=0.30

local FAR_FORCE_START=60
local FAR_FORCE_END=220
local FAR_MIN_START=1.2
local FAR_MIN_END=7.5

local LEAD_TIME=0.020
local VELOCITY_SMOOTH=0.35
local MAX_LEAD_PX=22
local MOTION_FULL=700

local JUMP_SCREEN_Y_THRESHOLD=90
local JUMP_VERTICAL_LEAD_SCALE=0.55
local JUMP_MAX_VERTICAL_LEAD_PX=10
local LANDING_VERTICAL_LEAD_SCALE=0.15
local LANDING_CHECK_EXTRA=3.5
local LANDING_DAMP_TIME=0.12

local CAMERA_EQ_HIGHLIGHT_TIME=1.50
local CAMERA_EQ_SCAN_INTERVAL=0.07
local CAMERA_EQ_RADIUS=12
local CAMERA_EQ_SIDE_RADIUS=10
local CAMERA_EQ_HEIGHT=4.5
local CAMERA_EQ_EXTRA_HEIGHT=7
local CAMERA_EQ_SAMPLE_COUNT=8

local SHOULDER_OFFSET=1.55
local SHOULDER_WALL_CHECK=4.5
local SHOULDER_SWITCH_MARGIN=0.65
local SHOULDER_SWITCH_COOLDOWN=0.20
local SHOULDER_SMOOTH_TIME=0.22
local SHOULDER_MIN_CAMERA_DISTANCE=2.5
local SHOULDER_DEFAULT_SIDE=1

local COUNTER_STRAFE_SCREEN_THRESHOLD=85
local COUNTER_STRAFE_FULL_SPEED=420
local COUNTER_STRAFE_MIN_STRENGTH=0.28
local COUNTER_STRAFE_MAX_STRENGTH=0.78
local COUNTER_STRAFE_WALL_CHECK=3.2
local COUNTER_STRAFE_DISTANCE=120
local COUNTER_STRAFE_SMOOTH=10
local COUNTER_STRAFE_RELEASE=14

local CIRCLE_STRAFE_MAX_DISTANCE=14
local CIRCLE_STRAFE_IDEAL_DISTANCE=8
local CIRCLE_STRAFE_MIN_DISTANCE=5
local CIRCLE_STRAFE_MIN_STRENGTH=0.62
local CIRCLE_STRAFE_MAX_STRENGTH=0.90
local CIRCLE_STRAFE_RADIAL_GAIN=0.075
local CIRCLE_STRAFE_WALL_CHECK=3.6
local CIRCLE_STRAFE_SWITCH_COOLDOWN=0.24
local CIRCLE_STRAFE_RANDOM_SWITCH_MIN=0.34
local CIRCLE_STRAFE_RANDOM_SWITCH_MAX=0.72
local CIRCLE_STRAFE_SMOOTH=11
local CIRCLE_STRAFE_RELEASE=15

local SCRAMBLE_MAX_DISTANCE=6.5
local SCRAMBLE_JUMP_DISTANCE=5.3
local SCRAMBLE_JUMP_MOVE_TIME=0.52
local SCRAMBLE_JUMP_COOLDOWN_MIN=0.72
local SCRAMBLE_JUMP_COOLDOWN_MAX=1.15
local SCRAMBLE_TANGENT_BIAS=0.72
local SCRAMBLE_FORWARD_BIAS=1.00
local SCRAMBLE_MOVE_STRENGTH=1.00
local SCRAMBLE_WALL_CHECK=3.2
local SCRAMBLE_CEILING_CHECK=5.2
local SCRAMBLE_SIDE_SWITCH_MIN=0.18
local SCRAMBLE_SIDE_SWITCH_MAX=0.38

local RANGE_RING_HEIGHT_OFFSET=-2.65
local RANGE_RING_THICKNESS=0.16
local RANGE_RING_SEGMENTS_OUTER=40
local RANGE_RING_SEGMENTS_MID=32
local RANGE_RING_SEGMENTS_INNER=28
local RANGE_RING_TRANSPARENCY=0.34

local PULL_SPEED=16
local PULL_MAX_STEP_DEG=7
local PULL_FIRE_RADIUS=15

local Whitelist={}
local Blacklist={}

local CurrentPlayer=nil
local CurrentPart=nil
local CurrentDistance=0
local CurrentWorld=nil
local CurrentMode=nil

local ManualPlayer=nil
local CombatLockPlayer=nil
local CombatLockLastPosition=nil
local CombatLockLostAt=0
local LastAutoPlayer=nil
local LastAutoPosition=nil
local Memories={}
local MemorySerial=0
local Reacquire={Player=nil,Until=0}
local TargetHysteresis={
	Player=nil,
	LastPosition=nil,
	LostAt=0,
	HoldUntil=0,
	ReturnUntil=0
}
local PeekStates={}
local ActivePeekPlayer=nil
local Motion={Player=nil,Pos=nil,Time=nil,Velocity=Vector2.zero}

local JumpTrack={
	Player=nil,
	Airborne=false,
	LandedAt=0,
	State="GROUND"
}

local Engagement={
	State="SEARCH",
	Player=nil,
	LastPosition=nil
}

local lastFire=0
local KillSwitchDelayUntil=0
local WatchedFirePlayer=nil
local WatchedHumanoid=nil
local WatchedDiedConnection=nil
local SeenHighlights={}
local PinkHighlights={}
local SeenScanAccum=0
local PinkScanAccum=0
local ShoulderState={
	Humanoid=nil,
	BaseOffset=Vector3.zero,
	CurrentX=0,
	VelocityX=0,
	Side=SHOULDER_DEFAULT_SIDE,
	LastSwitch=0
}
local CounterStrafeState={
	Strength=0,
	Direction=0
}
local CircleStrafeState={
	Strength=0,
	Side=(math.random()<0.5) and -1 or 1,
	LastSwitch=0,
	NextSwitch=0,
	Player=nil
}
local ScrambleState={
	Player=nil,
	Side=(math.random()<0.5) and -1 or 1,
	JumpUntil=0,
	NextJump=0,
	NextSideSwitch=0
}
local MovementRangeVisual={
	Character=nil,
	Folder=nil,
	Parts={}
}
local MovementFSM={
	State="NONE"
}
local touchId=5000
local RENDER_NAME="UniversalTPS"

pcall(function() RunService:UnbindFromRenderStep(RENDER_NAME) end)
for _,n in ipairs({"UniversalTPSUI","UniversalTPSOverlay"}) do
	local o=PG:FindFirstChild(n)
	if o then o:Destroy() end
end
local oh=Workspace:FindFirstChild("UniversalTPSTargetHighlight")
if oh then oh:Destroy() end
local oldSeenFolder=Workspace:FindFirstChild("UniversalTPSSeenHighlights")
if oldSeenFolder then oldSeenFolder:Destroy() end
local oldPinkFolder=Workspace:FindFirstChild("UniversalTPSPinkHighlights")
if oldPinkFolder then oldPinkFolder:Destroy() end
local oldRangeFolder=Workspace:FindFirstChild("UniversalTPSMovementRanges")
if oldRangeFolder then oldRangeFolder:Destroy() end

local Gui=Instance.new("ScreenGui")
Gui.Name="UniversalTPSUI"
Gui.ResetOnSpawn=false
Gui.Parent=PG

local Overlay=Instance.new("ScreenGui")
Overlay.Name="UniversalTPSOverlay"
Overlay.ResetOnSpawn=false
Overlay.IgnoreGuiInset=true
Overlay.DisplayOrder=999
Overlay.Parent=PG

pcall(function()
	Overlay.ScreenInsets=Enum.ScreenInsets.None
	Overlay.ClipToDeviceSafeArea=false
end)

local function corner(o,r)
	local c=Instance.new("UICorner")
	c.CornerRadius=UDim.new(0,r)
	c.Parent=o
end

local function stroke(o,t)
	local s=Instance.new("UIStroke")
	s.Thickness=t or 1
	s.Parent=o
end

local function button(parent,text,pos,size)
	local b=Instance.new("TextButton")
	b.Size=size
	b.Position=pos
	b.BackgroundColor3=Color3.fromRGB(60,60,70)
	b.BorderSizePixel=0
	b.Text=text
	b.TextColor3=Color3.new(1,1,1)
	b.Font=Enum.Font.GothamBold
	b.TextSize=12
	b.Active=true
	b.Parent=parent
	corner(b,7)
	return b
end

local Main=Instance.new("Frame")
Main.Size=UDim2.fromOffset(280,494)
Main.Position=UDim2.new(0.04,0,0.12,0)
Main.BackgroundColor3=Color3.fromRGB(25,25,30)
Main.BorderSizePixel=0
Main.Active=true
Main.Parent=Gui
corner(Main,12)
stroke(Main,2)

local Title=Instance.new("TextLabel")
Title.Size=UDim2.new(1,-40,0,40)
Title.Position=UDim2.fromOffset(10,0)
Title.BackgroundTransparency=1
Title.Text="Universal TPS"
Title.TextColor3=Color3.new(1,1,1)
Title.Font=Enum.Font.GothamBold
Title.TextSize=16
Title.TextXAlignment=Enum.TextXAlignment.Left
Title.Active=true
Title.Parent=Main

local Close=button(Main,"X",UDim2.new(1,-36,0,5),UDim2.fromOffset(30,30))
local AutoBtn=button(Main,"자동사격: OFF",UDim2.fromOffset(10,45),UDim2.new(1,-20,0,36))
local TeamBtn=button(Main,"팀: ON",UDim2.fromOffset(10,87),UDim2.new(0.31,-3,0,30))
local WallBtn=button(Main,"월: ON",UDim2.new(0.34,0,0,87),UDim2.new(0.31,-3,0,30))
local DragBtn=button(Main,"드래그: OFF",UDim2.new(0.67,0,0,87),UDim2.new(0.31,-3,0,30))
local PullBtn=button(Main,"끌어치기: OFF",UDim2.fromOffset(10,123),UDim2.new(0.5,-15,0,30))
local ShoulderBtn=button(Main,"숄더: ON",UDim2.new(0.5,5,0,123),UDim2.new(0.5,-15,0,30))
local CounterBtn=button(Main,"반대 스트레이프: ON",UDim2.fromOffset(10,159),UDim2.new(0.5,-15,0,30))
local CircleBtn=button(Main,"원형: ON",UDim2.new(0.5,5,0,159),UDim2.new(0.5,-15,0,30))
local RangeBtn=button(Main,"무빙 범위: ON",UDim2.fromOffset(10,195),UDim2.new(1,-20,0,30))

local function inputRow(label,y,default)
	local l=Instance.new("TextLabel")
	l.Size=UDim2.new(0.45,0,0,27)
	l.Position=UDim2.fromOffset(12,y)
	l.BackgroundTransparency=1
	l.Text=label
	l.TextColor3=Color3.new(0.9,0.9,0.9)
	l.Font=Enum.Font.Gotham
	l.TextSize=12
	l.TextXAlignment=Enum.TextXAlignment.Left
	l.Parent=Main

	local x=Instance.new("TextBox")
	x.Size=UDim2.new(0.45,0,0,26)
	x.Position=UDim2.new(0.52,0,0,y)
	x.BackgroundColor3=Color3.fromRGB(45,45,55)
	x.BorderSizePixel=0
	x.Text=tostring(default)
	x.TextColor3=Color3.new(1,1,1)
	x.Font=Enum.Font.Gotham
	x.TextSize=12
	x.ClearTextOnFocus=false
	x.Parent=Main
	corner(x,6)
	return x
end

local DelayBox=inputRow("발사 간격",234,FIRE_DELAY)
local DistanceBox=inputRow("최대 거리",266,MAX_DISTANCE)
local SpreadBox=inputRow("퍼짐 배율",298,SPREAD_MULTIPLIER)

local Status=Instance.new("TextLabel")
Status.Size=UDim2.new(1,-20,0,145)
Status.Position=UDim2.fromOffset(10,336)
Status.BackgroundColor3=Color3.fromRGB(15,15,20)
Status.BorderSizePixel=0
Status.Text="대상 탐색 중"
Status.TextColor3=Color3.fromRGB(210,210,215)
Status.Font=Enum.Font.Gotham
Status.TextSize=10
Status.TextWrapped=true
Status.TextXAlignment=Enum.TextXAlignment.Left
Status.TextYAlignment=Enum.TextYAlignment.Top
Status.Parent=Main
corner(Status,7)

local List=Instance.new("Frame")
List.Size=UDim2.fromOffset(230,250)
List.Position=UDim2.new(0.04,290,0.12,0)
List.BackgroundColor3=Color3.fromRGB(25,25,30)
List.BorderSizePixel=0
List.Active=true
List.Parent=Gui
corner(List,12)
stroke(List,2)

local ListTitle=Instance.new("TextLabel")
ListTitle.Size=UDim2.new(1,0,0,38)
ListTitle.BackgroundTransparency=1
ListTitle.Text="타겟 필터"
ListTitle.TextColor3=Color3.new(1,1,1)
ListTitle.Font=Enum.Font.GothamBold
ListTitle.TextSize=15
ListTitle.Active=true
ListTitle.Parent=List

local NameBox=Instance.new("TextBox")
NameBox.Size=UDim2.new(1,-20,0,32)
NameBox.Position=UDim2.fromOffset(10,40)
NameBox.BackgroundColor3=Color3.fromRGB(45,45,55)
NameBox.BorderSizePixel=0
NameBox.PlaceholderText="플레이어 이름"
NameBox.Text=""
NameBox.TextColor3=Color3.new(1,1,1)
NameBox.Font=Enum.Font.Gotham
NameBox.TextSize=12
NameBox.ClearTextOnFocus=false
NameBox.Parent=List
corner(NameBox,6)

local WhiteBtn=button(List,"화이트",UDim2.fromOffset(10,78),UDim2.new(0.5,-15,0,28))
local BlackBtn=button(List,"블랙",UDim2.new(0.5,5,0,78),UDim2.new(0.5,-15,0,28))
local RemoveBtn=button(List,"제거",UDim2.fromOffset(10,112),UDim2.new(1,-20,0,28))

local ListText=Instance.new("TextLabel")
ListText.Size=UDim2.new(1,-20,0,95)
ListText.Position=UDim2.fromOffset(10,146)
ListText.BackgroundColor3=Color3.fromRGB(15,15,20)
ListText.BorderSizePixel=0
ListText.Text=""
ListText.TextColor3=Color3.new(0.85,0.85,0.85)
ListText.Font=Enum.Font.Gotham
ListText.TextSize=10
ListText.TextWrapped=true
ListText.TextXAlignment=Enum.TextXAlignment.Left
ListText.TextYAlignment=Enum.TextYAlignment.Top
ListText.Parent=List
corner(ListText,6)

local FireBtn=button(Gui,"FIRE",UDim2.new(0.80,-37,0.66,-37),UDim2.fromOffset(75,75))
FireBtn.Name="MobileFireBtn"
FireBtn.BackgroundColor3=Color3.fromRGB(220,50,50)
FireBtn.TextSize=16
local fc=FireBtn:FindFirstChildOfClass("UICorner")
if fc then fc.CornerRadius=UDim.new(1,0) end
stroke(FireBtn,3)

local LockBtn=button(Gui,"🎯",UDim2.new(0.80,-105,0.66,-25),UDim2.fromOffset(52,52))
LockBtn.Name="KillLockBtn"
LockBtn.TextSize=25
corner(LockBtn,13)
stroke(LockBtn,2)

local Aim=Instance.new("Frame")
Aim.Size=UDim2.fromOffset(18,18)
Aim.AnchorPoint=Vector2.new(0.5,0.5)
Aim.BackgroundTransparency=1
Aim.BorderSizePixel=0
Aim.Visible=false
Aim.ZIndex=100
Aim.Parent=Overlay
corner(Aim,9)

local Center=Instance.new("Frame")
Center.Size=UDim2.fromOffset(10,10)
Center.AnchorPoint=Vector2.new(0.5,0.5)
Center.BackgroundColor3=Color3.fromRGB(255,210,45)
Center.BorderSizePixel=0
Center.Visible=false
Center.ZIndex=101
Center.Parent=Overlay
corner(Center,5)

local Highlight=Instance.new("Highlight")
Highlight.Name="UniversalTPSTargetHighlight"
Highlight.Enabled=false
Highlight.DepthMode=Enum.HighlightDepthMode.Occluded
Highlight.FillTransparency=0.30
Highlight.OutlineTransparency=0.05
Highlight.Parent=Workspace

local SeenFolder=Instance.new("Folder")
SeenFolder.Name="UniversalTPSSeenHighlights"
SeenFolder.Parent=Workspace

local PinkFolder=Instance.new("Folder")
PinkFolder.Name="UniversalTPSPinkHighlights"
PinkFolder.Parent=Workspace

local function draggable(frame,handle)
	handle=handle or frame
	local dragging=false
	local startPos
	local startInput
	local active

	handle.InputBegan:Connect(function(i)
		if i.UserInputType~=Enum.UserInputType.Touch and i.UserInputType~=Enum.UserInputType.MouseButton1 then return end
		if (frame==FireBtn or frame==LockBtn) and not DRAG_MODE then return end
		dragging=true
		active=i
		startInput=Vector2.new(i.Position.X,i.Position.Y)
		startPos=frame.Position
	end)

	UIS.InputChanged:Connect(function(i)
		if not dragging then return end
		if i~=active and i.UserInputType~=Enum.UserInputType.Touch and i.UserInputType~=Enum.UserInputType.MouseMovement then return end
		local p=Vector2.new(i.Position.X,i.Position.Y)
		local d=p-startInput
		frame.Position=UDim2.new(startPos.X.Scale,startPos.X.Offset+d.X,startPos.Y.Scale,startPos.Y.Offset+d.Y)
	end)

	UIS.InputEnded:Connect(function(i)
		if i==active then
			dragging=false
			active=nil
		end
	end)
end

draggable(Main,Title)
draggable(List,ListTitle)
draggable(FireBtn)
draggable(LockBtn)

local function clearMovementRangeVisual()
	if MovementRangeVisual.Folder then
		MovementRangeVisual.Folder:Destroy()
	end
	MovementRangeVisual.Character=nil
	MovementRangeVisual.Folder=nil
	MovementRangeVisual.Parts={}
end

local function createRangeRing(root,radius,segments,color,name,enabledFn)
	local folder=MovementRangeVisual.Folder
	if not folder or not root then return end

	local circumference=2*math.pi*radius
	local segmentLength=(circumference/segments)*0.88

	for i=1,segments do
		local a=(i-1)/segments*math.pi*2
		local center=root.Position+
			Vector3.new(math.cos(a)*radius,RANGE_RING_HEIGHT_OFFSET,math.sin(a)*radius)

		local p=Instance.new("Part")
		p.Name=name
		p.Size=Vector3.new(segmentLength,RANGE_RING_THICKNESS,RANGE_RING_THICKNESS)
		p.Material=Enum.Material.Neon
		p.Color=color
		p.Transparency=RANGE_RING_TRANSPARENCY
		p.CanCollide=false
		p.CanTouch=false
		p.CanQuery=false
		p.CastShadow=false
		p.Massless=true
		p.Anchored=false
		p.CFrame=CFrame.new(center)*CFrame.Angles(0,-a,0)
		p.Parent=folder

		local weld=Instance.new("WeldConstraint")
		weld.Part0=root
		weld.Part1=p
		weld.Parent=p

		table.insert(MovementRangeVisual.Parts,{
			Part=p,
			EnabledFn=enabledFn
		})
	end
end

local function createRangeLabel(root,radius,text,color,enabledFn)
	local folder=MovementRangeVisual.Folder
	if not folder or not root then return end

	local anchor=Instance.new("Part")
	anchor.Name="RangeLabel_"..text
	anchor.Size=Vector3.new(0.2,0.2,0.2)
	anchor.Transparency=1
	anchor.CanCollide=false
	anchor.CanTouch=false
	anchor.CanQuery=false
	anchor.CastShadow=false
	anchor.Massless=true
	anchor.Anchored=false
	anchor.CFrame=CFrame.new(root.Position+Vector3.new(radius,1.2,0))
	anchor.Parent=folder

	local weld=Instance.new("WeldConstraint")
	weld.Part0=root
	weld.Part1=anchor
	weld.Parent=anchor

	local bb=Instance.new("BillboardGui")
	bb.Name="RangeLabel"
	bb.Size=UDim2.fromOffset(104,24)
	bb.AlwaysOnTop=true
	bb.MaxDistance=160
	bb.Adornee=anchor
	bb.Parent=anchor

	local label=Instance.new("TextLabel")
	label.Size=UDim2.fromScale(1,1)
	label.BackgroundTransparency=0.25
	label.BackgroundColor3=Color3.fromRGB(20,20,24)
	label.BorderSizePixel=0
	label.Text=text
	label.TextColor3=color
	label.Font=Enum.Font.GothamBold
	label.TextSize=11
	label.Parent=bb
	corner(label,6)

	table.insert(MovementRangeVisual.Parts,{
		Part=anchor,
		Label=bb,
		EnabledFn=enabledFn
	})
end

local function buildMovementRangeVisual()
	local c=LP.Character
	local root=c and c:FindFirstChild("HumanoidRootPart")
	if not root then
		clearMovementRangeVisual()
		return
	end

	if MovementRangeVisual.Character==c
		and MovementRangeVisual.Folder
		and MovementRangeVisual.Folder.Parent then
		return
	end

	clearMovementRangeVisual()

	local folder=Instance.new("Folder")
	folder.Name="UniversalTPSMovementRanges"
	folder.Parent=Workspace

	MovementRangeVisual.Character=c
	MovementRangeVisual.Folder=folder

	createRangeRing(
		root,COUNTER_STRAFE_DISTANCE,RANGE_RING_SEGMENTS_OUTER,
		Color3.fromRGB(255,205,55),"CounterRange",
		function() return COUNTER_STRAFE end
	)
	createRangeLabel(
		root,COUNTER_STRAFE_DISTANCE,
		"반대 "..tostring(COUNTER_STRAFE_DISTANCE),
		Color3.fromRGB(255,205,55),
		function() return COUNTER_STRAFE end
	)

	createRangeRing(
		root,CIRCLE_STRAFE_MAX_DISTANCE,RANGE_RING_SEGMENTS_MID,
		Color3.fromRGB(70,210,255),"CircleRange",
		function() return CIRCLE_STRAFE end
	)
	createRangeLabel(
		root,CIRCLE_STRAFE_MAX_DISTANCE,
		"원형 "..tostring(CIRCLE_STRAFE_MAX_DISTANCE),
		Color3.fromRGB(70,210,255),
		function() return CIRCLE_STRAFE end
	)

	createRangeRing(
		root,SCRAMBLE_MAX_DISTANCE,RANGE_RING_SEGMENTS_INNER,
		Color3.fromRGB(255,75,80),"ScrambleRange",
		function() return CIRCLE_STRAFE end
	)
	createRangeLabel(
		root,SCRAMBLE_MAX_DISTANCE,
		"난전 "..tostring(SCRAMBLE_MAX_DISTANCE),
		Color3.fromRGB(255,75,80),
		function() return CIRCLE_STRAFE end
	)

	createRangeRing(
		root,SCRAMBLE_JUMP_DISTANCE,RANGE_RING_SEGMENTS_INNER,
		Color3.fromRGB(195,95,255),"JumpOverRange",
		function() return CIRCLE_STRAFE end
	)
	createRangeLabel(
		root,SCRAMBLE_JUMP_DISTANCE,
		"점프 "..tostring(SCRAMBLE_JUMP_DISTANCE),
		Color3.fromRGB(195,95,255),
		function() return CIRCLE_STRAFE end
	)
end

local function updateMovementRangeVisual()
	if not MOVEMENT_RANGE_VISIBLE then
		if MovementRangeVisual.Folder then
			MovementRangeVisual.Folder.Parent=nil
		end
		return
	end

	if MovementRangeVisual.Folder and not MovementRangeVisual.Folder.Parent then
		MovementRangeVisual.Folder.Parent=Workspace
	end

	buildMovementRangeVisual()

	for _,e in ipairs(MovementRangeVisual.Parts) do
		local enabled=true
		if e.EnabledFn then
			enabled=e.EnabledFn()
		end

		if e.Label then
			e.Label.Enabled=enabled
		elseif e.Part and e.Part.Parent then
			e.Part.Transparency=enabled and RANGE_RING_TRANSPARENCY or 1
		end
	end
end

local function resetShoulderState(restore)
	local oldHumanoid=ShoulderState.Humanoid
	if restore and oldHumanoid and oldHumanoid.Parent then
		pcall(function()
			oldHumanoid.CameraOffset=ShoulderState.BaseOffset
		end)
	end

	ShoulderState.Humanoid=nil
	ShoulderState.BaseOffset=Vector3.zero
	ShoulderState.CurrentX=0
	ShoulderState.VelocityX=0
	ShoulderState.Side=SHOULDER_DEFAULT_SIDE
	ShoulderState.LastSwitch=0
end

local function ensureShoulderHumanoid()
	local c=LP.Character
	local h=c and c:FindFirstChildOfClass("Humanoid")
	if h~=ShoulderState.Humanoid then
		resetShoulderState(true)
		if h then
			ShoulderState.Humanoid=h
			ShoulderState.BaseOffset=h.CameraOffset
			ShoulderState.CurrentX=0
			ShoulderState.VelocityX=0
			ShoulderState.Side=SHOULDER_DEFAULT_SIDE
		end
	end
	return h
end

local function sideClearance(anchor,direction,maxDistance)
	local c=LP.Character
	if not c then return maxDistance end

	local rp=RaycastParams.new()
	rp.FilterType=Enum.RaycastFilterType.Exclude
	rp.IgnoreWater=true
	rp.FilterDescendantsInstances={c}

	local hit=Workspace:Raycast(anchor,direction.Unit*maxDistance,rp)
	if not hit then return maxDistance end
	return (hit.Position-anchor).Magnitude
end

local function smoothDamp1D(current,target,velocity,smoothTime,dt)
	smoothTime=math.max(0.0001,smoothTime)
	local omega=2/smoothTime
	local x=omega*dt
	local exp=1/(1+x+0.48*x*x+0.235*x*x*x)

	local change=current-target
	local temp=(velocity+omega*change)*dt
	local newVelocity=(velocity-omega*temp)*exp
	local output=target+(change+temp)*exp

	return output,newVelocity
end

local function updateAutoShoulder(dt)
	local h=ensureShoulderHumanoid()
	local c=LP.Character
	local root=c and c:FindFirstChild("HumanoidRootPart")
	local head=c and c:FindFirstChild("Head")

	if not h or not root or not Camera then return end

	if not AUTO_SHOULDER then
		ShoulderState.CurrentX,ShoulderState.VelocityX=smoothDamp1D(
			ShoulderState.CurrentX,
			0,
			ShoulderState.VelocityX,
			SHOULDER_SMOOTH_TIME,
			dt
		)
		h.CameraOffset=ShoulderState.BaseOffset+Vector3.new(ShoulderState.CurrentX,0,0)
		return
	end

	local cameraDistance=(Camera.CFrame.Position-root.Position).Magnitude
	if cameraDistance<SHOULDER_MIN_CAMERA_DISTANCE then
		ShoulderState.CurrentX,ShoulderState.VelocityX=smoothDamp1D(
			ShoulderState.CurrentX,
			0,
			ShoulderState.VelocityX,
			SHOULDER_SMOOTH_TIME,
			dt
		)
		h.CameraOffset=ShoulderState.BaseOffset+Vector3.new(ShoulderState.CurrentX,0,0)
		return
	end

	local anchor=head and head.Position or (root.Position+Vector3.new(0,1.8,0))
	local right=root.CFrame.RightVector
	local leftClear=sideClearance(anchor,-right,SHOULDER_WALL_CHECK)
	local rightClear=sideClearance(anchor,right,SHOULDER_WALL_CHECK)

	local desired=ShoulderState.Side
	local now=os.clock()

	if rightClear+SHOULDER_SWITCH_MARGIN<leftClear then
		desired=-1
	elseif leftClear+SHOULDER_SWITCH_MARGIN<rightClear then
		desired=1
	elseif leftClear>=SHOULDER_WALL_CHECK*0.95 and rightClear>=SHOULDER_WALL_CHECK*0.95 then
		desired=SHOULDER_DEFAULT_SIDE
	end

	if desired~=ShoulderState.Side
		and now-ShoulderState.LastSwitch>=SHOULDER_SWITCH_COOLDOWN then
		ShoulderState.Side=desired
		ShoulderState.LastSwitch=now
	end

	local targetX=SHOULDER_OFFSET*ShoulderState.Side
	ShoulderState.CurrentX,ShoulderState.VelocityX=smoothDamp1D(
		ShoulderState.CurrentX,
		targetX,
		ShoulderState.VelocityX,
		SHOULDER_SMOOTH_TIME,
		dt
	)

	h.CameraOffset=ShoulderState.BaseOffset+Vector3.new(ShoulderState.CurrentX,0,0)
end

local function counterStrafeClearance(direction)
	local c=LP.Character
	local root=c and c:FindFirstChild("HumanoidRootPart")
	if not root or direction.Magnitude<0.01 then return 0 end

	local rp=RaycastParams.new()
	rp.FilterType=Enum.RaycastFilterType.Exclude
	rp.IgnoreWater=true
	rp.FilterDescendantsInstances={c}

	local hit=Workspace:Raycast(
		root.Position+Vector3.new(0,1,0),
		direction.Unit*COUNTER_STRAFE_WALL_CHECK,
		rp
	)

	if not hit then return COUNTER_STRAFE_WALL_CHECK end
	return (hit.Position-(root.Position+Vector3.new(0,1,0))).Magnitude
end

local function releaseCounterStrafe(dt)
	CounterStrafeState.Strength=CounterStrafeState.Strength+
		(0-CounterStrafeState.Strength)*math.clamp(dt*COUNTER_STRAFE_RELEASE,0,1)

	if math.abs(CounterStrafeState.Strength)<0.02 then
		CounterStrafeState.Strength=0
		CounterStrafeState.Direction=0
	end
end

local function updateCounterStrafe(dt,targetData)
	if not COUNTER_STRAFE then
		releaseCounterStrafe(dt)
		return
	end

	local c=LP.Character
	local h=c and c:FindFirstChildOfClass("Humanoid")
	local root=c and c:FindFirstChild("HumanoidRootPart")
	if not h or not root or not Camera then
		releaseCounterStrafe(dt)
		return
	end

	if not targetData
		or not targetData.Visible
		or not targetData.Player
		or targetData.Distance>COUNTER_STRAFE_DISTANCE
		or Engagement.State~="ENGAGED"
		or Motion.Player~=targetData.Player then
		releaseCounterStrafe(dt)
		return
	end

	local vx=Motion.Velocity.X
	if math.abs(vx)<COUNTER_STRAFE_SCREEN_THRESHOLD then
		releaseCounterStrafe(dt)
		return
	end

	-- 상대가 화면 오른쪽으로 가면 왼쪽, 왼쪽으로 가면 오른쪽.
	local desiredDir=(vx>0) and -1 or 1

	local camRight=Camera.CFrame.RightVector
	local flatRight=Vector3.new(camRight.X,0,camRight.Z)
	if flatRight.Magnitude<0.01 then
		releaseCounterStrafe(dt)
		return
	end
	flatRight=flatRight.Unit

	local worldDir=flatRight*desiredDir
	local clearance=counterStrafeClearance(worldDir)

	-- 벽 쪽이면 자동 이동하지 않음.
	if clearance<COUNTER_STRAFE_WALL_CHECK*0.55 then
		releaseCounterStrafe(dt)
		return
	end

	local speedT=math.clamp(
		(math.abs(vx)-COUNTER_STRAFE_SCREEN_THRESHOLD)/
		math.max(1,COUNTER_STRAFE_FULL_SPEED-COUNTER_STRAFE_SCREEN_THRESHOLD),
		0,
		1
	)

	local desiredStrength=
		COUNTER_STRAFE_MIN_STRENGTH+
		(COUNTER_STRAFE_MAX_STRENGTH-COUNTER_STRAFE_MIN_STRENGTH)*speedT

	CounterStrafeState.Direction=desiredDir
	CounterStrafeState.Strength=CounterStrafeState.Strength+
		(desiredStrength-CounterStrafeState.Strength)*math.clamp(dt*COUNTER_STRAFE_SMOOTH,0,1)

	h:Move(worldDir*CounterStrafeState.Strength,false)
end

local function resetScramble()
	ScrambleState.Player=nil
	ScrambleState.Side=(math.random()<0.5) and -1 or 1
	ScrambleState.JumpUntil=0
	ScrambleState.NextJump=0
	ScrambleState.NextSideSwitch=0
end

local function scrambleClearance(originPos,direction,distance,ignoreTarget)
	local c=LP.Character
	if not c or direction.Magnitude<0.01 then return 0 end

	local ignore={c}
	if ignoreTarget and ignoreTarget.Character then
		table.insert(ignore,ignoreTarget.Character)
	end

	local rp=RaycastParams.new()
	rp.FilterType=Enum.RaycastFilterType.Exclude
	rp.IgnoreWater=true
	rp.FilterDescendantsInstances=ignore

	local hit=Workspace:Raycast(originPos,direction.Unit*distance,rp)
	if not hit then return distance end
	return (hit.Position-originPos).Magnitude
end

local function scrambleCeilingClear(targetData)
	local c=LP.Character
	local root=c and c:FindFirstChild("HumanoidRootPart")
	if not root then return false end

	local ignore={c}
	if targetData and targetData.Character then
		table.insert(ignore,targetData.Character)
	end

	local rp=RaycastParams.new()
	rp.FilterType=Enum.RaycastFilterType.Exclude
	rp.IgnoreWater=true
	rp.FilterDescendantsInstances=ignore

	local hit=Workspace:Raycast(
		root.Position,
		Vector3.new(0,SCRAMBLE_CEILING_CHECK,0),
		rp
	)

	return hit==nil
end

local function updateCloseScramble(dt,targetData)
	local c=LP.Character
	local h=c and c:FindFirstChildOfClass("Humanoid")
	local root=c and c:FindFirstChild("HumanoidRootPart")

	if not CIRCLE_STRAFE
		or not h
		or not root
		or not targetData
		or not targetData.Visible
		or not targetData.Player
		or not targetData.Character
		or Engagement.State~="ENGAGED"
		or targetData.Distance>SCRAMBLE_MAX_DISTANCE then

		resetScramble()
		return false
	end

	local targetRoot=targetData.Character:FindFirstChild("HumanoidRootPart")
		or targetData.Part
	if not targetRoot then
		resetScramble()
		return false
	end

	local now=os.clock()

	if ScrambleState.Player~=targetData.Player then
		resetScramble()
		ScrambleState.Player=targetData.Player
		ScrambleState.Side=(math.random()<0.5) and -1 or 1
		ScrambleState.NextJump=now
		ScrambleState.NextSideSwitch=now+
			SCRAMBLE_SIDE_SWITCH_MIN+
			math.random()*(SCRAMBLE_SIDE_SWITCH_MAX-SCRAMBLE_SIDE_SWITCH_MIN)
	end

	if now>=ScrambleState.NextSideSwitch then
		ScrambleState.Side=-ScrambleState.Side
		ScrambleState.NextSideSwitch=now+
			SCRAMBLE_SIDE_SWITCH_MIN+
			math.random()*(SCRAMBLE_SIDE_SWITCH_MAX-SCRAMBLE_SIDE_SWITCH_MIN)
	end

	local toTarget=targetRoot.Position-root.Position
	local flatToTarget=Vector3.new(toTarget.X,0,toTarget.Z)
	if flatToTarget.Magnitude<0.05 then return false end
	flatToTarget=flatToTarget.Unit

	local tangent=Vector3.new(-flatToTarget.Z,0,flatToTarget.X)*ScrambleState.Side
	local start=root.Position+Vector3.new(0,1,0)

	-- 붙었고 바닥에 있으며 위가 열려 있으면 상대 쪽으로 뛰어넘기.
	if targetData.Distance<=SCRAMBLE_JUMP_DISTANCE
		and now>=ScrambleState.NextJump
		and h.FloorMaterial~=Enum.Material.Air
		and scrambleCeilingClear(targetData) then

		h.Jump=true
		ScrambleState.JumpUntil=now+SCRAMBLE_JUMP_MOVE_TIME
		ScrambleState.NextJump=now+
			SCRAMBLE_JUMP_COOLDOWN_MIN+
			math.random()*(SCRAMBLE_JUMP_COOLDOWN_MAX-SCRAMBLE_JUMP_COOLDOWN_MIN)

		-- 매번 같은 방향으로 넘지 않음.
		if math.random()<0.5 then
			ScrambleState.Side=-ScrambleState.Side
			tangent=-tangent
		end
	end

	local desired

	if now<=ScrambleState.JumpUntil then
		-- 상대를 가로질러 넘어가면서 옆으로 비틀어 착지 위치를 읽기 어렵게 만듦.
		desired=flatToTarget*SCRAMBLE_FORWARD_BIAS+
			tangent*SCRAMBLE_TANGENT_BIAS
	else
		-- 바닥에서는 아주 근접 원호를 빠르게 끊어 탐.
		local radialOut=Vector3.new(
			root.Position.X-targetRoot.Position.X,
			0,
			root.Position.Z-targetRoot.Position.Z
		)

		if radialOut.Magnitude>0.05 then
			radialOut=radialOut.Unit
			desired=tangent+radialOut*0.15
		else
			desired=tangent
		end
	end

	if desired.Magnitude<0.05 then return false end
	desired=desired.Unit

	-- 벽으로 박힐 것 같으면 반대 회전 방향.
	local clear=scrambleClearance(start,desired,SCRAMBLE_WALL_CHECK,targetData)
	if clear<SCRAMBLE_WALL_CHECK*0.5 then
		ScrambleState.Side=-ScrambleState.Side
		tangent=-tangent

		if now<=ScrambleState.JumpUntil then
			desired=(flatToTarget*SCRAMBLE_FORWARD_BIAS+
				tangent*SCRAMBLE_TANGENT_BIAS).Unit
		else
			desired=tangent
		end

		clear=scrambleClearance(start,desired,SCRAMBLE_WALL_CHECK,targetData)
	end

	if clear<SCRAMBLE_WALL_CHECK*0.35 then
		return false
	end

	h:Move(desired*SCRAMBLE_MOVE_STRENGTH,false)
	return true
end

local function releaseCircleStrafe(dt)
	CircleStrafeState.Strength=CircleStrafeState.Strength+
		(0-CircleStrafeState.Strength)*math.clamp(dt*CIRCLE_STRAFE_RELEASE,0,1)

	if math.abs(CircleStrafeState.Strength)<0.02 then
		CircleStrafeState.Strength=0
		CircleStrafeState.Player=nil
		CircleStrafeState.NextSwitch=0
	end
end

local function circleClearance(direction)
	local c=LP.Character
	local root=c and c:FindFirstChild("HumanoidRootPart")
	if not root or direction.Magnitude<0.01 then return 0 end

	local start=root.Position+Vector3.new(0,1,0)

	local rp=RaycastParams.new()
	rp.FilterType=Enum.RaycastFilterType.Exclude
	rp.IgnoreWater=true
	rp.FilterDescendantsInstances={c}

	local hit=Workspace:Raycast(
		start,
		direction.Unit*CIRCLE_STRAFE_WALL_CHECK,
		rp
	)

	if not hit then return CIRCLE_STRAFE_WALL_CHECK end
	return (hit.Position-start).Magnitude
end

local function updateCircleStrafe(dt,targetData)
	if not CIRCLE_STRAFE then
		releaseCircleStrafe(dt)
		return false
	end

	local c=LP.Character
	local h=c and c:FindFirstChildOfClass("Humanoid")
	local root=c and c:FindFirstChild("HumanoidRootPart")

	if not h or not root
		or not targetData
		or not targetData.Visible
		or not targetData.Player
		or not targetData.Character
		or Engagement.State~="ENGAGED"
		or targetData.Distance>CIRCLE_STRAFE_MAX_DISTANCE then
		releaseCircleStrafe(dt)
		return false
	end

	local targetRoot=targetData.Character:FindFirstChild("HumanoidRootPart")
		or targetData.Part
	if not targetRoot then
		releaseCircleStrafe(dt)
		return false
	end

	local now=os.clock()

	if CircleStrafeState.Player~=targetData.Player then
		CircleStrafeState.Player=targetData.Player
		CircleStrafeState.Side=(math.random()<0.5) and -1 or 1
		CircleStrafeState.LastSwitch=now
		CircleStrafeState.NextSwitch=now+
			CIRCLE_STRAFE_RANDOM_SWITCH_MIN+
			math.random()*(CIRCLE_STRAFE_RANDOM_SWITCH_MAX-CIRCLE_STRAFE_RANDOM_SWITCH_MIN)
	elseif CircleStrafeState.NextSwitch==0 then
		CircleStrafeState.NextSwitch=now+
			CIRCLE_STRAFE_RANDOM_SWITCH_MIN+
			math.random()*(CIRCLE_STRAFE_RANDOM_SWITCH_MAX-CIRCLE_STRAFE_RANDOM_SWITCH_MIN)
	elseif now>=CircleStrafeState.NextSwitch
		and now-CircleStrafeState.LastSwitch>=CIRCLE_STRAFE_SWITCH_COOLDOWN then

		CircleStrafeState.Side=-CircleStrafeState.Side
		CircleStrafeState.LastSwitch=now
		CircleStrafeState.NextSwitch=now+
			CIRCLE_STRAFE_RANDOM_SWITCH_MIN+
			math.random()*(CIRCLE_STRAFE_RANDOM_SWITCH_MAX-CIRCLE_STRAFE_RANDOM_SWITCH_MIN)
	end

	local delta=root.Position-targetRoot.Position
	local flat=Vector3.new(delta.X,0,delta.Z)
	local dist=flat.Magnitude
	if dist<0.1 then
		releaseCircleStrafe(dt)
		return false
	end

	local radial=flat.Unit

	-- 타겟을 중심으로 도는 접선 방향.
	local tangent=Vector3.new(-radial.Z,0,radial.X)*CircleStrafeState.Side

	-- 너무 가까우면 바깥쪽, 너무 멀면 안쪽으로 살짝 보정.
	local radialError=dist-CIRCLE_STRAFE_IDEAL_DISTANCE
	local radialCorrection=math.clamp(
		radialError*CIRCLE_STRAFE_RADIAL_GAIN,
		-0.55,
		0.55
	)

	local desired=(tangent-radial*radialCorrection)
	if desired.Magnitude<0.01 then
		releaseCircleStrafe(dt)
		return false
	end
	desired=desired.Unit

	-- 벽이면 반대 회전 방향으로 바꿔서 막힌 쪽에 계속 박지 않음.
	local clearance=circleClearance(desired)
	if clearance<CIRCLE_STRAFE_WALL_CHECK*0.55 then
		if now-CircleStrafeState.LastSwitch>=CIRCLE_STRAFE_SWITCH_COOLDOWN then
			CircleStrafeState.Side=-CircleStrafeState.Side
			CircleStrafeState.LastSwitch=now
			CircleStrafeState.NextSwitch=now+
				CIRCLE_STRAFE_RANDOM_SWITCH_MIN+
				math.random()*(CIRCLE_STRAFE_RANDOM_SWITCH_MAX-CIRCLE_STRAFE_RANDOM_SWITCH_MIN)
			tangent=Vector3.new(-radial.Z,0,radial.X)*CircleStrafeState.Side
			desired=(tangent-radial*radialCorrection)
			if desired.Magnitude>0.01 then desired=desired.Unit end
			clearance=circleClearance(desired)
		end
	end

	if clearance<CIRCLE_STRAFE_WALL_CHECK*0.45 then
		releaseCircleStrafe(dt)
		return false
	end

	-- 아주 근접하면 회전보다 거리 벌리기를 더 우선.
	if dist<CIRCLE_STRAFE_MIN_DISTANCE then
		desired=(desired+radial*0.85)
		if desired.Magnitude>0.01 then desired=desired.Unit end
	end

	local proximity=1-math.clamp(
		(dist-CIRCLE_STRAFE_MIN_DISTANCE)/
		math.max(0.1,CIRCLE_STRAFE_MAX_DISTANCE-CIRCLE_STRAFE_MIN_DISTANCE),
		0,
		1
	)

	local targetStrength=
		CIRCLE_STRAFE_MIN_STRENGTH+
		(CIRCLE_STRAFE_MAX_STRENGTH-CIRCLE_STRAFE_MIN_STRENGTH)*proximity

	CircleStrafeState.Strength=CircleStrafeState.Strength+
		(targetStrength-CircleStrafeState.Strength)*
		math.clamp(dt*CIRCLE_STRAFE_SMOOTH,0,1)

	h:Move(desired*CircleStrafeState.Strength,false)
	return true
end

local function chooseMovementState(targetData)
	if not targetData
		or not targetData.Visible
		or not targetData.Player
		or Engagement.State~="ENGAGED" then
		return "NONE"
	end

	local d=targetData.Distance

	if CIRCLE_STRAFE and d<=SCRAMBLE_JUMP_DISTANCE then
		return "JUMP_OVER"
	elseif CIRCLE_STRAFE and d<=SCRAMBLE_MAX_DISTANCE then
		return "SCRAMBLE"
	elseif CIRCLE_STRAFE and d<=CIRCLE_STRAFE_MAX_DISTANCE then
		return "CIRCLE"
	elseif COUNTER_STRAFE and d<=COUNTER_STRAFE_DISTANCE then
		return "COUNTER"
	end

	return "NONE"
end

local function updateMovementFSM(dt,targetData)
	local state=chooseMovementState(targetData)
	MovementFSM.State=state

	if state=="JUMP_OVER" or state=="SCRAMBLE" then
		local moved=updateCloseScramble(dt,targetData)
		releaseCircleStrafe(dt)
		releaseCounterStrafe(dt)
		return moved
	elseif state=="CIRCLE" then
		resetScramble()
		local moved=updateCircleStrafe(dt,targetData)
		releaseCounterStrafe(dt)
		return moved
	elseif state=="COUNTER" then
		resetScramble()
		releaseCircleStrafe(dt)
		updateCounterStrafe(dt,targetData)
		return true
	end

	resetScramble()
	releaseCircleStrafe(dt)
	releaseCounterStrafe(dt)
	return false
end

local function resetMotion()
	Motion.Player=nil
	Motion.Pos=nil
	Motion.Time=nil
	Motion.Velocity=Vector2.zero
	JumpTrack.Player=nil
	JumpTrack.Airborne=false
	JumpTrack.LandedAt=0
	JumpTrack.State="GROUND"
end

local function alive(p)
	local c=p and p.Character
	local h=c and c:FindFirstChildOfClass("Humanoid")
	return h and h.Health>0
end

local function transparent(p)
	local c=p and p.Character
	if not c then return true end

	local total=0
	local inv=0

	for _,v in ipairs(c:GetChildren()) do
		if v:IsA("BasePart") and v.Name~="HumanoidRootPart" then
			total+=1
			local t=1-(1-math.clamp(v.Transparency,0,1))*(1-math.clamp(v.LocalTransparencyModifier,0,1))
			if t>=TRANSPARENCY_LIMIT then inv+=1 end
		end
	end

	return total>0 and inv/total>=TRANSPARENT_RATIO
end

local function eligible(p)
	if not p or p==LP then return false end
	if Whitelist[p.Name] then return false end
	if TEAM_CHECK and LP.Team~=nil and p.Team==LP.Team then return false end
	if not alive(p) then return false end
	if transparent(p) then return false end
	return true
end

local function aimPart(c)
	return c and (
		c:FindFirstChild("UpperTorso")
		or c:FindFirstChild("Torso")
		or c:FindFirstChild("HumanoidRootPart")
		or c:FindFirstChild("Head")
	)
end

local function origin()
	local c=LP.Character
	local r=c and c:FindFirstChild("HumanoidRootPart")
	return r and r.Position or nil
end

local function viewport(world)
	Camera=Workspace.CurrentCamera
	if not Camera then return nil,false end
	local p,v=Camera:WorldToViewportPoint(world)
	if p.Z<=0 then return nil,false end
	return Vector2.new(p.X,p.Y),v
end

local function screen(world)
	Camera=Workspace.CurrentCamera
	if not Camera then return nil,false end
	local p,v=Camera:WorldToScreenPoint(world)
	if p.Z<=0 then return nil,false end
	return Vector2.new(p.X,p.Y),v
end

local function onScreen(world)
	Camera=Workspace.CurrentCamera
	if not Camera then return false end
	local p,v=Camera:WorldToViewportPoint(world)
	return v and p.Z>0 and p.X>=0 and p.Y>=0 and p.X<=Camera.ViewportSize.X and p.Y<=Camera.ViewportSize.Y
end

local function actualLos(player,part)
	Camera=Workspace.CurrentCamera
	if not Camera or not player or not player.Character or not part then return false end

	local dir=part.Position-Camera.CFrame.Position
	if dir.Magnitude<0.01 then return true end

	local rp=RaycastParams.new()
	rp.FilterType=Enum.RaycastFilterType.Exclude
	rp.IgnoreWater=true
	rp.FilterDescendantsInstances=LP.Character and {LP.Character} or {}

	local hit=Workspace:Raycast(Camera.CFrame.Position,dir,rp)
	return not hit or (hit.Instance and hit.Instance:IsDescendantOf(player.Character))
end

local function los(player,part)
	if not WALL_CHECK then return true end
	return actualLos(player,part)
end

local function originLos(sampleOrigin,player,part,ignoreList)
	if not player or not player.Character or not part then return false end

	local dir=part.Position-sampleOrigin
	if dir.Magnitude<0.01 then return true end

	local rp=RaycastParams.new()
	rp.FilterType=Enum.RaycastFilterType.Exclude
	rp.IgnoreWater=true
	rp.FilterDescendantsInstances=ignoreList or (LP.Character and {LP.Character} or {})

	local hit=Workspace:Raycast(sampleOrigin,dir,rp)
	return not hit or (hit.Instance and hit.Instance:IsDescendantOf(player.Character))
end

local function visible(player,part)
	return eligible(player) and part and onScreen(part.Position) and los(player,part)
end

local PEEK_PART_NAMES={
	"Head",
	"UpperTorso",
	"Torso",
	"LowerTorso",
	"LeftUpperArm",
	"RightUpperArm",
	"Left Arm",
	"Right Arm",
	"HumanoidRootPart"
}

local function resolvedVisiblePart(player)
	if not eligible(player) then return nil end
	local c=player.Character
	if not c then return nil end

	local primary=aimPart(c)
	if primary and onScreen(primary.Position) and los(player,primary) then
		return primary
	end

	Camera=Workspace.CurrentCamera
	if not Camera then return nil end
	local center=Camera.ViewportSize*0.5
	local best=nil
	local bestScore=math.huge

	for _,name in ipairs(PEEK_PART_NAMES) do
		local part=c:FindFirstChild(name)
		if part and part:IsA("BasePart") and part~=primary and onScreen(part.Position) and los(player,part) then
			local vp=viewport(part.Position)
			if vp then
				local score=(vp-center).Magnitude
				if score<bestScore then
					bestScore=score
					best=part
				end
			end
		end
	end

	return best
end


local SEEN_PART_NAMES={
	"UpperTorso",
	"Torso",
	"Head",
	"HumanoidRootPart"
}

local function actuallySeen(player)
	if not eligible(player) then return false end
	local c=player.Character
	if not c then return false end

	local checked={}
	local primary=aimPart(c)
	if primary then
		checked[primary]=true
		if onScreen(primary.Position) and actualLos(player,primary) then
			return true
		end
	end

	for _,name in ipairs(SEEN_PART_NAMES) do
		local part=c:FindFirstChild(name)
		if part and part:IsA("BasePart") and not checked[part] then
			checked[part]=true
			if onScreen(part.Position) and actualLos(player,part) then
				return true
			end
		end
	end

	return false
end

local function removeSeenHighlight(player)
	local e=SeenHighlights[player]
	if not e then return end
	if e.Highlight then
		e.Highlight:Destroy()
	end
	SeenHighlights[player]=nil
end

local function markSeen(player)
	local c=player and player.Character
	if not c then return end

	local e=SeenHighlights[player]
	if e and e.Character~=c then
		removeSeenHighlight(player)
		e=nil
	end

	if not e then
		local h=Instance.new("Highlight")
		h.Name="Seen_"..player.Name
		h.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop
		h.FillColor=Color3.fromRGB(35,220,85)
		h.OutlineColor=Color3.fromRGB(220,255,230)
		h.FillTransparency=0.30
		h.OutlineTransparency=0.05
		h.Enabled=true
		h.Adornee=c
		h.Parent=SeenFolder

		e={
			Highlight=h,
			Character=c,
			Until=0
		}
		SeenHighlights[player]=e
	end

	e.Until=os.clock()+SEEN_HIGHLIGHT_TIME
	e.Highlight.Adornee=c
	e.Highlight.Enabled=true
end

local function updateSeenHighlights(dt)
	SeenScanAccum+=dt

	if SeenScanAccum>=SEEN_SCAN_INTERVAL then
		SeenScanAccum=SeenScanAccum%SEEN_SCAN_INTERVAL

		for _,p in ipairs(Players:GetPlayers()) do
			if p~=LP and actuallySeen(p) then
				markSeen(p)
			end
		end
	end

	local now=os.clock()
	for p,e in pairs(SeenHighlights) do
		if now>e.Until
			or not eligible(p)
			or p.Character~=e.Character
			or not e.Character
			or not e.Character.Parent then
			removeSeenHighlight(p)
		else
			e.Highlight.Enabled=true
			e.Highlight.Adornee=e.Character
		end
	end
end

local function removePinkHighlight(player)
	local e=PinkHighlights[player]
	if not e then return end
	if e.Highlight then
		e.Highlight:Destroy()
	end
	PinkHighlights[player]=nil
end

local function getCameraEquivalentOrigins(targetPos)
	local c=LP.Character
	local root=c and c:FindFirstChild("HumanoidRootPart")
	local head=c and c:FindFirstChild("Head")
	if not root then return nil,nil end

	local anchor=head and head.Position or (root.Position+Vector3.new(0,2,0))
	local flatForward=Vector3.new(root.CFrame.LookVector.X,0,root.CFrame.LookVector.Z)
	if flatForward.Magnitude<0.001 then
		flatForward=Vector3.new(0,0,-1)
	else
		flatForward=flatForward.Unit
	end

	local flatToTarget=Vector3.new(targetPos.X-anchor.X,0,targetPos.Z-anchor.Z)
	if flatToTarget.Magnitude<0.001 then
		flatToTarget=flatForward
	else
		flatToTarget=flatToTarget.Unit
	end

	local right=Vector3.new(flatToTarget.Z,0,-flatToTarget.X)
	if right.Magnitude<0.001 then
		right=Vector3.new(flatForward.Z,0,-flatForward.X)
	end
	right=right.Unit

	local up=Vector3.new(0,1,0)
	local origins={
		anchor-flatToTarget*CAMERA_EQ_RADIUS+up*CAMERA_EQ_HEIGHT,
		anchor+flatToTarget*CAMERA_EQ_RADIUS+up*CAMERA_EQ_HEIGHT,
		anchor+right*CAMERA_EQ_SIDE_RADIUS+up*CAMERA_EQ_HEIGHT,
		anchor-right*CAMERA_EQ_SIDE_RADIUS+up*CAMERA_EQ_HEIGHT,
		anchor+(-flatToTarget+right).Unit*CAMERA_EQ_RADIUS+up*CAMERA_EQ_HEIGHT,
		anchor+(-flatToTarget-right).Unit*CAMERA_EQ_RADIUS+up*CAMERA_EQ_HEIGHT,
		anchor+(flatToTarget+right).Unit*CAMERA_EQ_RADIUS+up*CAMERA_EQ_HEIGHT,
		anchor+(flatToTarget-right).Unit*CAMERA_EQ_RADIUS+up*CAMERA_EQ_HEIGHT,
		anchor+up*CAMERA_EQ_EXTRA_HEIGHT
	}

	return origins,anchor
end

local function sampleCameraReachable(sampleOrigin,anchor,player)
	if not sampleOrigin or not anchor then return false end

	local ignore={}
	if LP.Character then table.insert(ignore,LP.Character) end
	if player and player.Character then table.insert(ignore,player.Character) end

	local dir=sampleOrigin-anchor
	if dir.Magnitude<0.05 then return true end

	local rp=RaycastParams.new()
	rp.FilterType=Enum.RaycastFilterType.Exclude
	rp.IgnoreWater=true
	rp.FilterDescendantsInstances=ignore

	local hit=Workspace:Raycast(anchor,dir,rp)
	return not hit
end

local function cameraEquivalentSeen(player)
	if not eligible(player) then return false end
	local c=player.Character
	if not c then return false end

	local primary=aimPart(c)
	local targetPos=primary and primary.Position
	if not targetPos then return false end

	local origins,anchor=getCameraEquivalentOrigins(targetPos)
	if not origins then return false end

	local checked={}
	local parts={}

	if primary then
		table.insert(parts,primary)
		checked[primary]=true
	end

	for _,name in ipairs(SEEN_PART_NAMES) do
		local part=c:FindFirstChild(name)
		if part and part:IsA("BasePart") and not checked[part] then
			checked[part]=true
			table.insert(parts,part)
		end
	end

	local maxSamples=math.min(#origins,CAMERA_EQ_SAMPLE_COUNT)
	for i=1,maxSamples do
		local sampleOrigin=origins[i]
		if sampleCameraReachable(sampleOrigin,anchor,player) then
			for _,part in ipairs(parts) do
				if originLos(sampleOrigin,player,part,LP.Character and {LP.Character} or {}) then
					return true
				end
			end
		end
	end

	return false
end

local function markPink(player)
	local c=player and player.Character
	if not c then return end

	local e=PinkHighlights[player]
	if e and e.Character~=c then
		removePinkHighlight(player)
		e=nil
	end

	if not e then
		local h=Instance.new("Highlight")
		h.Name="Pink_"..player.Name
		h.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop
		h.FillColor=Color3.fromRGB(255,80,190)
		h.OutlineColor=Color3.fromRGB(255,215,240)
		h.FillTransparency=0.35
		h.OutlineTransparency=0.03
		h.Enabled=true
		h.Adornee=c
		h.Parent=PinkFolder

		e={
			Highlight=h,
			Character=c,
			Until=0
		}
		PinkHighlights[player]=e
	end

	e.Until=os.clock()+CAMERA_EQ_HIGHLIGHT_TIME
	e.Highlight.Adornee=c
	e.Highlight.Enabled=true
end

local function updatePinkHighlights(dt)
	PinkScanAccum+=dt

	if PinkScanAccum>=CAMERA_EQ_SCAN_INTERVAL then
		PinkScanAccum=PinkScanAccum%CAMERA_EQ_SCAN_INTERVAL

		for _,p in ipairs(Players:GetPlayers()) do
			if p~=LP and eligible(p) then
				if actuallySeen(p) then
					removePinkHighlight(p)
				elseif cameraEquivalentSeen(p) then
					markPink(p)
				end
			end
		end
	end

	local now=os.clock()
	for p,e in pairs(PinkHighlights) do
		if now>e.Until
			or not eligible(p)
			or p.Character~=e.Character
			or not e.Character
			or not e.Character.Parent
			or actuallySeen(p) then
			removePinkHighlight(p)
		else
			e.Highlight.Enabled=true
			e.Highlight.Adornee=e.Character
		end
	end
end

local function peekState(player)
	local s=PeekStates[player]
	if s then return s end

	s={
		HiddenAt=0,
		WaitUntil=0,
		ReacquireUntil=0,
		LastVisible=nil,
		EdgePosition=nil,
		Samples={}
	}
	PeekStates[player]=s
	return s
end

local function addPeekSample(s,pos)
	if not s or not pos then return end
	table.insert(s.Samples,pos)
	while #s.Samples>PEEK_SAMPLE_LIMIT do
		table.remove(s.Samples,1)
	end

	local sum=Vector3.zero
	for _,v in ipairs(s.Samples) do
		sum+=v
	end
	if #s.Samples>0 then
		s.EdgePosition=sum/#s.Samples
	end
end

local function registerPeekHide(player,pos)
	if not player or not pos then return end
	local s=peekState(player)

	-- 다른 모서리로 크게 이동했으면 이전 피킹 위치 평균을 섞지 않음.
	if s.EdgePosition and (pos-s.EdgePosition).Magnitude>12 then
		s.Samples={}
		s.EdgePosition=nil
	end

	local now=os.clock()
	s.HiddenAt=now
	s.WaitUntil=now+PEEK_WAIT_TIME
	s.ReacquireUntil=0
	s.LastVisible=pos
	ActivePeekPlayer=player
end

local function cleanupPeek()
	local now=os.clock()
	for p,s in pairs(PeekStates) do
		if not eligible(p) or (
			s.HiddenAt>0
			and now-s.HiddenAt>MEMORY_TIME
			and s.ReacquireUntil<=now
		) then
			PeekStates[p]=nil
			if ActivePeekPlayer==p then
				ActivePeekPlayer=nil
			end
		end
	end
end

local function remember(player,pos)
	if not player or not pos or not eligible(player) then return end
	MemorySerial+=1
	Memories[player]={Position=pos,Expires=os.clock()+MEMORY_TIME,Serial=MemorySerial}
end

local function clearManual()
	ManualPlayer=nil
	LockBtn.BackgroundColor3=Color3.fromRGB(60,60,70)
end

local function cleanupMemory()
	cleanupPeek()
	local now=os.clock()
	for p,m in pairs(Memories) do
		if not eligible(p) or m.Expires<=now then
			Memories[p]=nil
			if Reacquire.Player==p then
				Reacquire.Player=nil
				Reacquire.Until=0
			end
		end
	end
	if ManualPlayer and not eligible(ManualPlayer) then clearManual() end
end

local function data(player,part,org,pos,mode,vis)
	return {
		Player=player,
		Character=player.Character,
		Part=part,
		Distance=(pos-org).Magnitude,
		Position=pos,
		Mode=mode,
		Visible=vis
	}
end

local function clearTargetHysteresis()
	TargetHysteresis.Player=nil
	TargetHysteresis.LastPosition=nil
	TargetHysteresis.LostAt=0
	TargetHysteresis.HoldUntil=0
	TargetHysteresis.ReturnUntil=0
end

local function startTargetHysteresis(player,pos)
	if not player or not pos or not eligible(player) then
		clearTargetHysteresis()
		return
	end

	local now=os.clock()
	TargetHysteresis.Player=player
	TargetHysteresis.LastPosition=pos
	TargetHysteresis.LostAt=now
	TargetHysteresis.HoldUntil=now+HYSTERESIS_HOLD_TIME
	TargetHysteresis.ReturnUntil=now+HYSTERESIS_RETURN_WINDOW
end

local function hysteresisTarget(org)
	local p=TargetHysteresis.Player
	if not p then return nil end

	local now=os.clock()
	if now>TargetHysteresis.ReturnUntil or not eligible(p) then
		clearTargetHysteresis()
		return nil
	end

	local part=resolvedVisiblePart(p)
	if part and (part.Position-org).Magnitude<=MAX_DISTANCE then
		local d=data(p,part,org,part.Position,"HYST_REACQUIRE",true)
		clearTargetHysteresis()
		return d
	end

	local pos=TargetHysteresis.LastPosition
	if now<=TargetHysteresis.HoldUntil
		and pos
		and (pos-org).Magnitude<=MAX_DISTANCE then
		return data(p,aimPart(p.Character),org,pos,"HYST_WAIT",false)
	end

	return nil
end

local function updateLastAuto()
	if not LastAutoPlayer then return end
	local p=LastAutoPlayer
	if not eligible(p) then
		LastAutoPlayer=nil
		LastAutoPosition=nil
		return
	end

	local primary=aimPart(p.Character)
	if not primary then
		LastAutoPlayer=nil
		LastAutoPosition=nil
		return
	end

	local part=resolvedVisiblePart(p)
	if part then
		LastAutoPosition=part.Position
	else
		if LastAutoPosition then
			remember(p,LastAutoPosition)
			startTargetHysteresis(p,LastAutoPosition)

			-- 피킹으로 볼 수 있는 경우는 화면 안에 남아 있는데 벽/엄폐물로 LOS가 끊긴 경우만.
			if onScreen(primary.Position) and not los(p,primary) then
				registerPeekHide(p,LastAutoPosition)
			end
		end
		LastAutoPlayer=nil
		LastAutoPosition=nil
	end
end

local function bestVisible(org)
	Camera=Workspace.CurrentCamera
	if not Camera then return nil end
	local center=Camera.ViewportSize*0.5
	local normal,black=nil,nil
	local ns,bs=math.huge,math.huge

	for _,p in ipairs(Players:GetPlayers()) do
		if eligible(p) then
			local part=resolvedVisiblePart(p)
			if part then
				local dist=(part.Position-org).Magnitude
				if dist<=MAX_DISTANCE then
					local vp=viewport(part.Position)
					if vp then
						local score=(vp-center).Magnitude
						local d=data(p,part,org,part.Position,"NORMAL",true)
						if Blacklist[p.Name] then
							if score<bs then bs=score black=d end
						elseif score<ns then
							ns=score normal=d
						end
					end
				end
			end
		end
	end

	return black or normal
end

local function reacquired(org)
	if not Reacquire.Player then return nil end
	if os.clock()>Reacquire.Until then
		Reacquire.Player=nil
		return nil
	end

	local p=Reacquire.Player
	if not eligible(p) then Reacquire.Player=nil return nil end
	local part=resolvedVisiblePart(p)
	if not part or (part.Position-org).Magnitude>MAX_DISTANCE then
		Reacquire.Player=nil
		return nil
	end
	return data(p,part,org,part.Position,"REACQUIRE",true)
end

local function reappeared(org)
	cleanupMemory()
	local best=nil
	local serial=-1

	for p,m in pairs(Memories) do
		if eligible(p) then
			local part=resolvedVisiblePart(p)
			if part and (part.Position-org).Magnitude<=MAX_DISTANCE and m.Serial>serial then
				best=data(p,part,org,part.Position,"REAPPEAR",true)
				serial=m.Serial
			end
		end
	end

	if best then
		Memories[best.Player]=nil
		Reacquire.Player=best.Player
		Reacquire.Until=os.clock()+REACQUIRE_HOLD
	end

	return best
end

local function peekReacquired(org)
	local p=ActivePeekPlayer
	if not p then return nil end
	local s=PeekStates[p]
	if not s or s.ReacquireUntil<=0 then return nil end

	if os.clock()>s.ReacquireUntil then
		s.ReacquireUntil=0
		return nil
	end

	if not eligible(p) then
		s.ReacquireUntil=0
		return nil
	end

	local part=resolvedVisiblePart(p)
	if not part or (part.Position-org).Magnitude>MAX_DISTANCE then
		s.ReacquireUntil=0
		return nil
	end

	return data(p,part,org,part.Position,"PEEK_REACQUIRE",true)
end

local function peekReappeared(org)
	local p=ActivePeekPlayer
	if not p then return nil end
	local s=PeekStates[p]
	if not s or s.HiddenAt<=0 then return nil end

	local now=os.clock()
	if now-s.HiddenAt>PEEK_WINDOW then
		return nil
	end

	if not eligible(p) then return nil end
	local part=resolvedVisiblePart(p)
	if not part or (part.Position-org).Magnitude>MAX_DISTANCE then return nil end

	addPeekSample(s,part.Position)
	s.HiddenAt=0
	s.WaitUntil=0
	s.ReacquireUntil=now+PEEK_REACQUIRE_HOLD
	s.LastVisible=part.Position
	Memories[p]=nil

	-- 벽 뒤에서 유지된 화면 속도를 재사용하지 않고 재등장 프레임부터 다시 측정.
	resetMotion()

	return data(p,part,org,part.Position,"PEEK_REACQUIRE",true)
end

local function peekWait(org)
	local p=ActivePeekPlayer
	if not p or not eligible(p) then return nil end
	local s=PeekStates[p]
	if not s or s.HiddenAt<=0 then return nil end

	local now=os.clock()
	if now>s.WaitUntil or now-s.HiddenAt>PEEK_WINDOW then return nil end

	local pos=s.EdgePosition or s.LastVisible
	if not pos or (pos-org).Magnitude>MAX_DISTANCE then return nil end

	return data(p,aimPart(p.Character),org,pos,"PEEK_WAIT",false)
end

local function latestMemory(org)
	local bp,bm=nil,nil
	local serial=-1
	for p,m in pairs(Memories) do
		if eligible(p) and m.Serial>serial and (m.Position-org).Magnitude<=MAX_DISTANCE then
			bp,bm,serial=p,m,m.Serial
		end
	end
	if not bp then return nil end
	local part=aimPart(bp.Character)
	return part and data(bp,part,org,bm.Position,"LAST",false) or nil
end

local function manualTarget(org)
	if not ManualPlayer then return nil end
	local p=ManualPlayer
	local part=eligible(p) and resolvedVisiblePart(p) or nil
	if not part or (part.Position-org).Magnitude>MAX_DISTANCE then
		clearManual()
		return nil
	end
	return data(p,part,org,part.Position,"MANUAL",true)
end

local function setEngagement(state,player,pos)
	Engagement.State=state or "SEARCH"
	Engagement.Player=player
	Engagement.LastPosition=pos
end

local function clearCombatLock(nextState)
	CombatLockPlayer=nil
	CombatLockLastPosition=nil
	CombatLockLostAt=0

	if nextState then
		setEngagement(nextState,nil,nil)
	elseif Engagement.State~="KILL_DELAY" then
		setEngagement("SEARCH",nil,nil)
	end
end

local function trackCandidate(player,pos)
	if Engagement.State=="SEARCH" or Engagement.State=="TRACK" then
		setEngagement("TRACK",player,pos)
	end
end

local function lockCombatTarget(player,pos)
	if not player then return end
	CombatLockPlayer=player
	CombatLockLastPosition=pos
	CombatLockLostAt=0
	setEngagement("ENGAGED",player,pos)
end

local function combatLockedTarget(org)
	local p=CombatLockPlayer
	if not p then return nil end

	if not eligible(p) then
		clearCombatLock()
		return nil
	end

	local part=resolvedVisiblePart(p)
	if part and (part.Position-org).Magnitude<=MAX_DISTANCE then
		CombatLockLastPosition=part.Position
		CombatLockLostAt=0
		setEngagement("ENGAGED",p,part.Position)
		return data(p,part,org,part.Position,"COMBAT_LOCK",true)
	end

	local pos=CombatLockLastPosition
	if not pos or (pos-org).Magnitude>MAX_DISTANCE then
		clearCombatLock()
		return nil
	end

	local now=os.clock()
	if CombatLockLostAt==0 then
		CombatLockLostAt=now
	end

	if now-CombatLockLostAt<=COMBAT_LOCK_LOST_GRACE then
		setEngagement("LOST",p,pos)
		return data(p,aimPart(p.Character),org,pos,"COMBAT_LOCK_WAIT",false)
	end

	clearCombatLock()
	return nil
end

local function currentTarget(org)
	if ManualPlayer then
		local m=manualTarget(org)
		if m then return m end
	end

	if CombatLockPlayer then
		local c=combatLockedTarget(org)
		if c then
			LastAutoPlayer=c.Player
			if c.Visible then
				LastAutoPosition=c.Position
			end
			return c
		end
	end

	updateLastAuto()
	cleanupMemory()

	local hy=hysteresisTarget(org)
	if hy then
		if hy.Visible then
			LastAutoPlayer=hy.Player
			LastAutoPosition=hy.Position
			trackCandidate(hy.Player,hy.Position)
		end
		return hy
	end

	local ph=peekReacquired(org)
	if ph then
		LastAutoPlayer=ph.Player
		LastAutoPosition=ph.Position
		trackCandidate(ph.Player,ph.Position)
		return ph
	end

	local pr=peekReappeared(org)
	if pr then
		LastAutoPlayer=pr.Player
		LastAutoPosition=pr.Position
		trackCandidate(pr.Player,pr.Position)
		return pr
	end

	local r=reacquired(org)
	if r then
		LastAutoPlayer=r.Player
		LastAutoPosition=r.Position
		trackCandidate(r.Player,r.Position)
		return r
	end

	local rr=reappeared(org)
	if rr then
		LastAutoPlayer=rr.Player
		LastAutoPosition=rr.Position
		trackCandidate(rr.Player,rr.Position)
		return rr
	end

	local n=bestVisible(org)
	if n then
		LastAutoPlayer=n.Player
		LastAutoPosition=n.Position
		trackCandidate(n.Player,n.Position)
		return n
	end

	LastAutoPlayer=nil
	LastAutoPosition=nil
	if Engagement.State=="TRACK" then
		setEngagement("SEARCH",nil,nil)
	end

	-- 다른 실제 가시 타겟이 없을 때만 피킹 모서리에서 대기.
	local pw=peekWait(org)
	if pw then return pw end

	return latestMemory(org)
end

local function updateHighlight(d)
	if not d or not d.Character or transparent(d.Player) then
		Highlight.Enabled=false
		Highlight.Adornee=nil
		return
	end

	Highlight.Enabled=true
	Highlight.Adornee=d.Character

	if d.Mode=="MANUAL" then
		Highlight.FillColor=Color3.fromRGB(255,40,40)
		Highlight.OutlineColor=Color3.fromRGB(255,220,220)
	elseif d.Mode=="COMBAT_LOCK" then
		Highlight.FillColor=Color3.fromRGB(40,255,100)
		Highlight.OutlineColor=Color3.fromRGB(225,255,235)
	elseif d.Mode=="COMBAT_LOCK_WAIT" then
		Highlight.FillColor=Color3.fromRGB(90,185,110)
		Highlight.OutlineColor=Color3.fromRGB(205,235,210)
	elseif d.Mode=="LAST" then
		Highlight.FillColor=Color3.fromRGB(255,170,35)
		Highlight.OutlineColor=Color3.fromRGB(255,220,130)
	elseif d.Mode=="PEEK_WAIT" then
		Highlight.FillColor=Color3.fromRGB(190,80,255)
		Highlight.OutlineColor=Color3.fromRGB(235,210,255)
	elseif d.Mode=="PEEK_REACQUIRE" then
		Highlight.FillColor=Color3.fromRGB(0,220,255)
		Highlight.OutlineColor=Color3.fromRGB(210,250,255)
	elseif d.Mode=="REAPPEAR" or d.Mode=="REACQUIRE" then
		Highlight.FillColor=Color3.fromRGB(50,180,255)
		Highlight.OutlineColor=Color3.fromRGB(210,240,255)
	else
		Highlight.FillColor=Color3.fromRGB(40,255,100)
		Highlight.OutlineColor=Color3.new(1,1,1)
	end
end

local function updateVelocity(p,pos)
	local now=os.clock()
	if Motion.Player~=p then
		Motion.Player=p
		Motion.Pos=pos
		Motion.Time=now
		Motion.Velocity=Vector2.zero
		return
	end
	if Motion.Pos and Motion.Time then
		local dt=now-Motion.Time
		if dt>0.001 and dt<0.1 then
			local v=(pos-Motion.Pos)/dt
			if v.Magnitude>4500 then v=v.Unit*4500 end
			Motion.Velocity=Motion.Velocity:Lerp(v,VELOCITY_SMOOTH)
		end
	end
	Motion.Pos=pos
	Motion.Time=now
end

local function jumpState(player)
	local c=player and player.Character
	local h=c and c:FindFirstChildOfClass("Humanoid")
	local root=c and c:FindFirstChild("HumanoidRootPart")

	if not h or not root then
		JumpTrack.State="GROUND"
		return "GROUND"
	end

	if JumpTrack.Player~=player then
		JumpTrack.Player=player
		JumpTrack.Airborne=false
		JumpTrack.LandedAt=0
		JumpTrack.State="GROUND"
	end

	local now=os.clock()
	local hs=h:GetState()
	local worldY=root.AssemblyLinearVelocity.Y

	local airborne=
		h.FloorMaterial==Enum.Material.Air
		or hs==Enum.HumanoidStateType.Jumping
		or hs==Enum.HumanoidStateType.Freefall
		or math.abs(Motion.Velocity.Y)>=JUMP_SCREEN_Y_THRESHOLD

	local landingSoon=false
	if airborne and worldY<0 then
		local rp=RaycastParams.new()
		rp.FilterType=Enum.RaycastFilterType.Exclude
		rp.IgnoreWater=true
		rp.FilterDescendantsInstances={c}

		local castDistance=math.max(3.5,h.HipHeight+LANDING_CHECK_EXTRA)
		local hit=Workspace:Raycast(
			root.Position,
			Vector3.new(0,-castDistance,0),
			rp
		)
		landingSoon=hit~=nil
	end

	if JumpTrack.Airborne and not airborne then
		JumpTrack.LandedAt=now
	end
	JumpTrack.Airborne=airborne

	if landingSoon then
		JumpTrack.State="LANDING"
	elseif airborne then
		JumpTrack.State="AIR"
	elseif now-JumpTrack.LandedAt<=LANDING_DAMP_TIME then
		JumpTrack.State="LANDING"
	else
		JumpTrack.State="GROUND"
	end

	return JumpTrack.State
end

local function lead(player)
	local l=Motion.Velocity*LEAD_TIME
	local state=jumpState(player)

	if state=="AIR" then
		l=Vector2.new(
			l.X,
			math.clamp(
				l.Y*JUMP_VERTICAL_LEAD_SCALE,
				-JUMP_MAX_VERTICAL_LEAD_PX,
				JUMP_MAX_VERTICAL_LEAD_PX
			)
		)
	elseif state=="LANDING" then
		l=Vector2.new(
			l.X,
			math.clamp(
				l.Y*LANDING_VERTICAL_LEAD_SCALE,
				-JUMP_MAX_VERTICAL_LEAD_PX*0.5,
				JUMP_MAX_VERTICAL_LEAD_PX*0.5
			)
		)
	end

	if l.Magnitude>MAX_LEAD_PX then
		l=l.Unit*MAX_LEAD_PX
	end

	return l
end

local function gaussian()
	local u1=math.max(math.random(),0.000001)
	local u2=math.random()
	return math.sqrt(-2*math.log(u1))*math.cos(2*math.pi*u2)
end

local function screenRadius(character)
	Camera=Workspace.CurrentCamera
	if not Camera or not character then return 4 end
	local ok,cf,size=pcall(function()
		local a,b=character:GetBoundingBox()
		return a,b
	end)
	if not ok then return 4 end

	local c=Camera:WorldToScreenPoint(cf.Position)
	if c.Z<=0 then return 4 end

	local hp=Camera:WorldToScreenPoint(cf.Position+Camera.CFrame.RightVector*math.max(size.X,size.Z)*0.5)
	local vp=Camera:WorldToScreenPoint(cf.Position+Camera.CFrame.UpVector*size.Y*0.5)

	return math.max(1.5,math.min(math.abs(hp.X-c.X),math.abs(vp.Y-c.Y)))
end

local function spread(character,distance)
	if SPREAD_MULTIPLIER<=0 then return 0 end

	local ratio
	if distance<=MID_DISTANCE then
		local t=math.clamp((distance-NEAR_DISTANCE)/math.max(1,MID_DISTANCE-NEAR_DISTANCE),0,1)^0.8
		ratio=NEAR_RATIO+(MID_RATIO-NEAR_RATIO)*t
	else
		local t=math.clamp((distance-MID_DISTANCE)/math.max(1,FAR_DISTANCE-MID_DISTANCE),0,1)^0.8
		ratio=MID_RATIO+(FAR_RATIO-MID_RATIO)*t
	end

	local sigma=screenRadius(character)*ratio

	local closeT=1-math.clamp(distance/CLOSE_SPREAD_END,0,1)
	sigma=sigma*(1+CLOSE_SPREAD_BONUS*closeT)

	local ft=math.clamp((distance-FAR_FORCE_START)/math.max(1,FAR_FORCE_END-FAR_FORCE_START),0,1)
	local forced=FAR_MIN_START+(FAR_MIN_END-FAR_MIN_START)*ft
	sigma=math.max(sigma,forced)

	sigma=sigma*SPREAD_MULTIPLIER

	return math.clamp(
		sigma,
		MIN_SPREAD_PX*SPREAD_MULTIPLIER,
		MAX_SPREAD_PX*SPREAD_MULTIPLIER
	)
end

local CoordinateState={
	ScreenOffset=Vector2.zero,
	ViewportOffset=Vector2.zero
}

local function refreshCoordinateOffsets()
	local screenOffset=nil
	local viewportOffset=nil

	local okNone,noneRect=pcall(function()
		return GuiService:GetInsetArea(Enum.ScreenInsets.None)
	end)

	if okNone and typeof(noneRect)=="Rect" then
		screenOffset=Vector2.new(
			-noneRect.Min.X,
			-noneRect.Min.Y
		)

		local okDevice,deviceRect=pcall(function()
			return GuiService:GetInsetArea(Enum.ScreenInsets.DeviceSafeInsets)
		end)

		if okDevice and typeof(deviceRect)=="Rect" then
			viewportOffset=Vector2.new(
				deviceRect.Min.X-noneRect.Min.X,
				deviceRect.Min.Y-noneRect.Min.Y
			)
		end
	end

	if not screenOffset then
		local fallback=Vector2.zero

		pcall(function()
			local tl=select(1,GuiService:GetGuiInset())
			if typeof(tl)=="Vector2" then
				fallback=tl
			end
		end)

		screenOffset=fallback
	end

	if not viewportOffset then
		viewportOffset=screenOffset
	end

	CoordinateState.ScreenOffset=screenOffset
	CoordinateState.ViewportOffset=viewportOffset
end

local function screenToFull(p)
	local o=CoordinateState.ScreenOffset
	return Vector2.new(
		p.X+o.X,
		p.Y+o.Y
	)
end

local function viewportToFull(p)
	local o=CoordinateState.ViewportOffset
	return Vector2.new(
		p.X+o.X,
		p.Y+o.Y
	)
end

local function toVIM(p)
	return screenToFull(p)
end

local function viewportToVIM(p)
	return viewportToFull(p)
end

local function randomKillSwitchDelay()
	return KILL_SWITCH_DELAY_MIN+
		(KILL_SWITCH_DELAY_MAX-KILL_SWITCH_DELAY_MIN)*math.random()
end

local function clearFireTargetWatch()
	if WatchedDiedConnection then
		WatchedDiedConnection:Disconnect()
		WatchedDiedConnection=nil
	end
	WatchedFirePlayer=nil
	WatchedHumanoid=nil
end

local function watchFiredTarget(player)
	if WatchedFirePlayer==player and WatchedHumanoid and WatchedHumanoid.Parent then
		return
	end

	clearFireTargetWatch()

	local c=player and player.Character
	local h=c and c:FindFirstChildOfClass("Humanoid")
	if not h then return end

	WatchedFirePlayer=player
	WatchedHumanoid=h

	WatchedDiedConnection=h.Died:Connect(function()
		if WatchedFirePlayer~=player or WatchedHumanoid~=h then return end

		KillSwitchDelayUntil=math.max(
			KillSwitchDelayUntil,
			os.clock()+randomKillSwitchDelay()
		)

		setEngagement("KILL_DELAY",player,CombatLockLastPosition)

		if CombatLockPlayer==player then
			CombatLockPlayer=nil
			CombatLockLastPosition=nil
			CombatLockLostAt=0
		end

		clearFireTargetWatch()
	end)
end

local function fireAt(point,character,distance)
	local s=spread(character,distance)
	local p=Vector2.new(point.X+gaussian()*s,point.Y+gaussian()*s)
	touchId+=1
	if touchId>2000000000 then touchId=5000 end
	local x=math.floor(p.X+0.5)
	local y=math.floor(p.Y+0.5)
	local id=touchId

	local ok=pcall(function()
		VIM:SendTouchEvent(id,Enum.UserInputState.Begin.Value,x,y)
		task.delay(0.018,function()
			pcall(function()
				VIM:SendTouchEvent(id,Enum.UserInputState.End.Value,x,y)
			end)
		end)
	end)
	return ok
end

local function rotateTo(world,dt)
	Camera=Workspace.CurrentCamera
	if not Camera then return end

	local pos=Camera.CFrame.Position
	local delta=world-pos
	if delta.Magnitude<0.001 then return end

	local a=Camera.CFrame.LookVector.Unit
	local b=delta.Unit
	local angle=math.acos(math.clamp(a:Dot(b),-1,1))
	if angle<0.0001 then return end

	local step=math.min(angle,math.rad(PULL_MAX_STEP_DEG),PULL_SPEED*math.max(dt,0))
	local look=a:Lerp(b,math.clamp(step/angle,0,1))
	if look.Magnitude<0.001 then return end

	Camera.CFrame=CFrame.lookAt(pos,pos+look.Unit,Vector3.yAxis)
end

local function playerFromText(t)
	t=string.lower(t or "")
	if t=="" then return nil end
	for _,p in ipairs(Players:GetPlayers()) do
		if string.lower(p.Name):sub(1,#t)==t or string.lower(p.DisplayName):sub(1,#t)==t then
			return p
		end
	end
end

local function refreshList()
	local w,b="화이트\n","블랙\n"
	local wc,bc=0,0
	for n in pairs(Whitelist) do w..=n.."\n" wc+=1 end
	for n in pairs(Blacklist) do b..=n.."\n" bc+=1 end
	if wc==0 then w..="없음\n" end
	if bc==0 then b..="없음\n" end
	ListText.Text=w.."\n"..b
end
refreshList()

WhiteBtn.MouseButton1Click:Connect(function()
	local p=playerFromText(NameBox.Text)
	if not p then return end
	Whitelist[p.Name]=true
	Blacklist[p.Name]=nil
	Memories[p]=nil
	if ManualPlayer==p then clearManual() end
	NameBox.Text=""
	refreshList()
end)

BlackBtn.MouseButton1Click:Connect(function()
	local p=playerFromText(NameBox.Text)
	if not p then return end
	Blacklist[p.Name]=true
	Whitelist[p.Name]=nil
	NameBox.Text=""
	refreshList()
end)

RemoveBtn.MouseButton1Click:Connect(function()
	local p=playerFromText(NameBox.Text)
	if not p then return end
	Whitelist[p.Name]=nil
	Blacklist[p.Name]=nil
	NameBox.Text=""
	refreshList()
end)

AutoBtn.MouseButton1Click:Connect(function()
	AUTO_FIRE=not AUTO_FIRE
	AutoBtn.Text=AUTO_FIRE and "자동사격: ON" or "자동사격: OFF"
end)

TeamBtn.MouseButton1Click:Connect(function()
	TEAM_CHECK=not TEAM_CHECK
	TeamBtn.Text=TEAM_CHECK and "팀: ON" or "팀: OFF"
end)

WallBtn.MouseButton1Click:Connect(function()
	WALL_CHECK=not WALL_CHECK
	WallBtn.Text=WALL_CHECK and "월: ON" or "월: OFF"
end)

DragBtn.MouseButton1Click:Connect(function()
	DRAG_MODE=not DRAG_MODE
	if DRAG_MODE then HOLD_FIRE=false end
	DragBtn.Text=DRAG_MODE and "드래그: ON" or "드래그: OFF"
end)

PullBtn.MouseButton1Click:Connect(function()
	PULL_AIM=not PULL_AIM
	PullBtn.Text=PULL_AIM and "끌어치기: ON" or "끌어치기: OFF"
	Center.Visible=PULL_AIM
	resetMotion()
end)

ShoulderBtn.MouseButton1Click:Connect(function()
	AUTO_SHOULDER=not AUTO_SHOULDER
	ShoulderBtn.Text=AUTO_SHOULDER and "숄더: ON" or "숄더: OFF"
	if not AUTO_SHOULDER then
		ShoulderState.Side=SHOULDER_DEFAULT_SIDE
	end
end)

CounterBtn.MouseButton1Click:Connect(function()
	COUNTER_STRAFE=not COUNTER_STRAFE
	CounterBtn.Text=COUNTER_STRAFE and "반대 스트레이프: ON" or "반대 스트레이프: OFF"
	if not COUNTER_STRAFE then
		CounterStrafeState.Strength=0
		CounterStrafeState.Direction=0
	end
	updateMovementRangeVisual()
end)

CircleBtn.MouseButton1Click:Connect(function()
	CIRCLE_STRAFE=not CIRCLE_STRAFE
	CircleBtn.Text=CIRCLE_STRAFE and "원형: ON" or "원형: OFF"
	if not CIRCLE_STRAFE then
		CircleStrafeState.Strength=0
		CircleStrafeState.Player=nil
		CircleStrafeState.NextSwitch=0
	end
	updateMovementRangeVisual()
end)

RangeBtn.MouseButton1Click:Connect(function()
	MOVEMENT_RANGE_VISIBLE=not MOVEMENT_RANGE_VISIBLE
	RangeBtn.Text=MOVEMENT_RANGE_VISIBLE and "무빙 범위: ON" or "무빙 범위: OFF"
	updateMovementRangeVisual()
end)

LockBtn.MouseButton1Click:Connect(function()
	if DRAG_MODE then return end
	if ManualPlayer then
		clearManual()
		return
	end
	if CurrentPlayer and CurrentPart and visible(CurrentPlayer,CurrentPart) then
		ManualPlayer=CurrentPlayer
		Reacquire.Player=nil
		clearTargetHysteresis()
		LastAutoPlayer=nil
		LastAutoPosition=nil
		LockBtn.BackgroundColor3=Color3.fromRGB(215,45,45)
	end
end)

DelayBox.FocusLost:Connect(function()
	FIRE_DELAY=math.max(0.01,tonumber(DelayBox.Text) or FIRE_DELAY)
	DelayBox.Text=tostring(FIRE_DELAY)
end)

DistanceBox.FocusLost:Connect(function()
	MAX_DISTANCE=math.max(1,tonumber(DistanceBox.Text) or MAX_DISTANCE)
	DistanceBox.Text=tostring(MAX_DISTANCE)
end)

SpreadBox.FocusLost:Connect(function()
	SPREAD_MULTIPLIER=math.clamp(tonumber(SpreadBox.Text) or SPREAD_MULTIPLIER,0,3)
	SpreadBox.Text=tostring(SPREAD_MULTIPLIER)
end)

FireBtn.InputBegan:Connect(function(i)
	if DRAG_MODE then return end
	if i.UserInputType==Enum.UserInputType.Touch or i.UserInputType==Enum.UserInputType.MouseButton1 then
		HOLD_FIRE=true
	end
end)

FireBtn.InputEnded:Connect(function(i)
	if i.UserInputType==Enum.UserInputType.Touch or i.UserInputType==Enum.UserInputType.MouseButton1 then
		HOLD_FIRE=false
	end
end)

Close.MouseButton1Click:Connect(function()
	AUTO_FIRE=false
	HOLD_FIRE=false
	pcall(function() RunService:UnbindFromRenderStep(RENDER_NAME) end)
	resetShoulderState(true)
	clearMovementRangeVisual()
	MovementFSM.State="NONE"
	CounterStrafeState.Strength=0
	CounterStrafeState.Direction=0
	CircleStrafeState.Strength=0
	CircleStrafeState.Player=nil
	CircleStrafeState.NextSwitch=0
	resetScramble()
	clearTargetHysteresis()
	clearCombatLock()
	clearFireTargetWatch()
	for p in pairs(SeenHighlights) do
		removeSeenHighlight(p)
	end
	for p in pairs(PinkHighlights) do
		removePinkHighlight(p)
	end
	Highlight:Destroy()
	if SeenFolder then SeenFolder:Destroy() end
	if PinkFolder then PinkFolder:Destroy() end
	Overlay:Destroy()
	Gui:Destroy()
end)

RunService:BindToRenderStep(RENDER_NAME,Enum.RenderPriority.Camera.Value+2,function(dt)
	Camera=Workspace.CurrentCamera
	if not Camera or not Gui.Parent then return end

	cleanupMemory()
	refreshCoordinateOffsets()
	updateAutoShoulder(dt)
	updateMovementRangeVisual()
	updateSeenHighlights(dt)
	updatePinkHighlights(dt)

	if Engagement.State=="KILL_DELAY" and os.clock()>=KillSwitchDelayUntil then
		setEngagement("SEARCH",nil,nil)
	end

	local center=Camera.ViewportSize*0.5
	local centerFull=viewportToFull(center)
	Center.Position=UDim2.fromOffset(centerFull.X,centerFull.Y)
	Center.Visible=PULL_AIM

	if not (AUTO_FIRE or HOLD_FIRE) and CombatLockPlayer then
		clearCombatLock()
	elseif not (AUTO_FIRE or HOLD_FIRE) and Engagement.State~="KILL_DELAY" then
		setEngagement("SEARCH",nil,nil)
	end

	local org=origin()
	if not org then
		Highlight.Enabled=false
		Aim.Visible=false
		releaseCircleStrafe(dt)
		resetScramble()
		MovementFSM.State="NONE"
		MovementFSM.State="NONE"
		resetScramble()
		releaseCircleStrafe(dt)
		releaseCounterStrafe(dt)
		resetMotion()
		return
	end

	local d=currentTarget(org)
	if not d then
		CurrentPlayer=nil
		CurrentPart=nil
		CurrentWorld=nil
		CurrentMode=nil
		Highlight.Enabled=false
		Aim.Visible=false
		Status.Text="화면 안 타겟 없음\n교전: "..Engagement.State
		releaseCounterStrafe(dt)
		resetMotion()
		return
	end

	CurrentPlayer=d.Player
	CurrentPart=d.Part
	CurrentDistance=d.Distance
	CurrentWorld=d.Position
	CurrentMode=d.Mode

	updateHighlight(d)

	local sp,on=screen(CurrentWorld)
	if sp and on then
		local overlayPoint=screenToFull(sp)
		Aim.Visible=true
		Aim.Position=UDim2.fromOffset(overlayPoint.X,overlayPoint.Y)
	else
		Aim.Visible=false
	end

	if d.Visible and sp then updateVelocity(CurrentPlayer,sp) else resetMotion() end

	updateMovementFSM(dt,d)

	if PULL_AIM then
		rotateTo(CurrentWorld,dt)
	end

	local mode=CurrentMode
	if mode=="NORMAL" then mode="중앙 최근접"
	elseif mode=="MANUAL" then mode="🎯 수동고정"
	elseif mode=="COMBAT_LOCK" then mode="사격 타겟 고정"
	elseif mode=="COMBAT_LOCK_WAIT" then mode="사격 타겟 잠깐 대기"
	elseif mode=="LAST" then mode="마지막 위치"
	elseif mode=="PEEK_WAIT" then mode="피킹 모서리 대기"
	elseif mode=="PEEK_REACQUIRE" then mode="피킹 즉시 재포착"
	elseif mode=="REAPPEAR" or mode=="REACQUIRE" then mode="재등장 우선"
	elseif mode=="HYST_WAIT" then mode="재포착 대기"
	elseif mode=="HYST_REACQUIRE" then mode="히스테리시스 재포착"
	end

	local jumpText="GROUND"
	if d.Visible and sp then
		jumpText=jumpState(CurrentPlayer)
	end

	Status.Text=string.format(
		"타겟: %s | %.1f\n모드: %s\n교전: %s | 이동: %s | 무빙: %s\n월체크: %s | 실제보임: %s\n퍼짐: %.2fpx | 배율 %.2f\n숄더: %s | 반대: %s | 원형: %s\n투명 관전자 제외: ON\n끌어치기: %s",
		CurrentPlayer.Name,
		CurrentDistance,
		mode,
		Engagement.State,
		jumpText,
		MovementFSM.State,
		WALL_CHECK and "ON" or "OFF",
		d.Visible and "YES" or "NO",
		spread(CurrentPlayer.Character,CurrentDistance),
		SPREAD_MULTIPLIER,
		AUTO_SHOULDER and (ShoulderState.Side<0 and "LEFT" or "RIGHT") or "OFF",
		COUNTER_STRAFE and (CounterStrafeState.Direction<0 and "LEFT" or CounterStrafeState.Direction>0 and "RIGHT" or "WAIT") or "OFF",
		CIRCLE_STRAFE and (CircleStrafeState.Side<0 and "LEFT" or "RIGHT") or "OFF",
		PULL_AIM and "ON" or "OFF"
	)

	if not (AUTO_FIRE or HOLD_FIRE) then
		MovementFSM.State="NONE"
		resetScramble()
		releaseCircleStrafe(dt)
		releaseCounterStrafe(dt)
		return
	end
	if not d.Visible then return end
	if transparent(CurrentPlayer) then return end
	if os.clock()<KillSwitchDelayUntil then return end
	if os.clock()-lastFire<FIRE_DELAY then return end

	local final,ons=screen(CurrentWorld)
	if not final or not ons then return end

	local point
	if PULL_AIM then
		local vp=viewport(CurrentWorld)
		if not vp or (vp-center).Magnitude>PULL_FIRE_RADIUS then return end
		point=viewportToVIM(center)
	else
		local predicted=final
		if d.Visible then predicted+=lead(CurrentPlayer) end
		point=toVIM(predicted)
	end

	if fireAt(point,CurrentPlayer.Character,CurrentDistance) then
		lastFire=os.clock()
		lockCombatTarget(CurrentPlayer,CurrentWorld)
		watchFiredTarget(CurrentPlayer)
	end
end)
