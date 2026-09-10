local Config={
	AUTO_FIRE=false,
	HOLD_FIRE=false,
	TEAM_CHECK=true,
	WALL_CHECK=true,
	DRAG_MODE=false,
	PULL_AIM=false,
	AUTO_SHOULDER=true,
	COUNTER_STRAFE=true,
	CIRCLE_STRAFE=true,
	MOVEMENT_RANGE_VISIBLE=true,
	FIRE_DELAY=0.15,
	KILL_SWITCH_DELAY_MIN=0.12,
	KILL_SWITCH_DELAY_MAX=0.30,
	COMBAT_LOCK_LOST_GRACE=0.35,
	SEEN_HIGHLIGHT_TIME=1.50,
	SEEN_SCAN_INTERVAL=0.05,
	MAX_DISTANCE=500,
	SPREAD_MULTIPLIER=0.45,
	MEMORY_TIME=10,
	REACQUIRE_HOLD=0.30,
	HYSTERESIS_HOLD_TIME=0.16,
	HYSTERESIS_RETURN_WINDOW=0.55,
	PEEK_WINDOW=0.55,
	PEEK_REACQUIRE_HOLD=0.12,
	PEEK_WAIT_TIME=0.25,
	PEEK_SAMPLE_LIMIT=5,
	TRANSPARENCY_LIMIT=0.90,
	TRANSPARENT_RATIO=0.75,
	NEAR_DISTANCE=15,
	MID_DISTANCE=75,
	FAR_DISTANCE=200,
	NEAR_RATIO=1.50,
	MID_RATIO=1.55,
	FAR_RATIO=1.15,
	MIN_SPREAD_PX=0.8,
	MAX_SPREAD_PX=30,
	CLOSE_SPREAD_END=40,
	CLOSE_SPREAD_BONUS=0.30,
	FAR_FORCE_START=60,
	FAR_FORCE_END=220,
	FAR_MIN_START=1.2,
	FAR_MIN_END=7.5,
	LEAD_TIME=0.020,
	VELOCITY_SMOOTH=0.35,
	MAX_LEAD_PX=22,
	MOTION_FULL=700,
	JUMP_SCREEN_Y_THRESHOLD=90,
	JUMP_VERTICAL_LEAD_SCALE=0.55,
	JUMP_MAX_VERTICAL_LEAD_PX=10,
	LANDING_VERTICAL_LEAD_SCALE=0.15,
	LANDING_CHECK_EXTRA=3.5,
	LANDING_DAMP_TIME=0.12,
	CAMERA_EQ_HIGHLIGHT_TIME=1.50,
	CAMERA_EQ_SCAN_INTERVAL=0.07,
	CAMERA_EQ_RADIUS=12,
	CAMERA_EQ_SIDE_RADIUS=10,
	CAMERA_EQ_HEIGHT=4.5,
	CAMERA_EQ_EXTRA_HEIGHT=7,
	CAMERA_EQ_SAMPLE_COUNT=8,
	SHOULDER_OFFSET=1.55,
	SHOULDER_WALL_CHECK=4.5,
	SHOULDER_SWITCH_MARGIN=0.65,
	SHOULDER_SWITCH_COOLDOWN=0.20,
	SHOULDER_SMOOTH_TIME=0.22,
	SHOULDER_MIN_CAMERA_DISTANCE=2.5,
	SHOULDER_DEFAULT_SIDE=1,
	COUNTER_STRAFE_SCREEN_THRESHOLD=85,
	COUNTER_STRAFE_FULL_SPEED=420,
	COUNTER_STRAFE_MIN_STRENGTH=0.28,
	COUNTER_STRAFE_MAX_STRENGTH=0.78,
	COUNTER_STRAFE_WALL_CHECK=3.2,
	COUNTER_STRAFE_DISTANCE=120,
	COUNTER_STRAFE_SMOOTH=10,
	COUNTER_STRAFE_RELEASE=14,
	CIRCLE_STRAFE_MAX_DISTANCE=14,
	CIRCLE_STRAFE_IDEAL_DISTANCE=8,
	CIRCLE_STRAFE_MIN_DISTANCE=5,
	CIRCLE_STRAFE_MIN_STRENGTH=0.62,
	CIRCLE_STRAFE_MAX_STRENGTH=0.90,
	CIRCLE_STRAFE_RADIAL_GAIN=0.075,
	CIRCLE_STRAFE_WALL_CHECK=3.6,
	CIRCLE_STRAFE_SWITCH_COOLDOWN=0.24,
	CIRCLE_STRAFE_RANDOM_SWITCH_MIN=0.34,
	CIRCLE_STRAFE_RANDOM_SWITCH_MAX=0.72,
	CIRCLE_STRAFE_SMOOTH=11,
	CIRCLE_STRAFE_RELEASE=15,
	SCRAMBLE_MAX_DISTANCE=6.5,
	SCRAMBLE_JUMP_DISTANCE=5.3,
	SCRAMBLE_JUMP_MOVE_TIME=0.52,
	SCRAMBLE_JUMP_COOLDOWN_MIN=0.72,
	SCRAMBLE_JUMP_COOLDOWN_MAX=1.15,
	SCRAMBLE_TANGENT_BIAS=0.72,
	SCRAMBLE_FORWARD_BIAS=1.00,
	SCRAMBLE_MOVE_STRENGTH=1.00,
	SCRAMBLE_WALL_CHECK=3.2,
	SCRAMBLE_CEILING_CHECK=5.2,
	SCRAMBLE_SIDE_SWITCH_MIN=0.18,
	SCRAMBLE_SIDE_SWITCH_MAX=0.38,
	RANGE_RING_HEIGHT_OFFSET=-2.65,
	RANGE_RING_THICKNESS=0.16,
	RANGE_RING_SEGMENTS_OUTER=40,
	RANGE_RING_SEGMENTS_MID=32,
	RANGE_RING_SEGMENTS_INNER=28,
	RANGE_RING_TRANSPARENCY=0.34,
	PULL_SPEED=16,
	PULL_MAX_STEP_DEG=7,
	PULL_FIRE_RADIUS=15,
	RENDER_NAME="UniversalTPS",
}

local Players=game:GetService("Players")
local RunService=game:GetService("RunService")
local UIS=game:GetService("UserInputService")
local VIM=game:GetService("VirtualInputManager")
local GuiService=game:GetService("GuiService")
local Workspace=game:GetService("Workspace")

local LP=Players.LocalPlayer
local PG=LP:WaitForChild("PlayerGui")
local Camera=Workspace.CurrentCamera

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
local PostLossFire={
	Player=nil,
	Character=nil,
	Position=nil,
	Until=0,
	Reason=nil
}
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
	Side=Config.SHOULDER_DEFAULT_SIDE,
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
local Tactics={
    Enabled=true,Sense=true,Adaptive=true,Cover=true,Disengage=true,Flank=true,Jumps=true,ManualPriority=false,Reverse=false,
    Interval=0.09,MaxDrop=4,Side=1,Connections={},BlockcastAvailable=true,Closed=false
}

function Tactics.connect(event,callback)
    local connection=event:Connect(callback)
    Tactics.Connections[#Tactics.Connections+1]=connection
    return connection
end

function Tactics.release(brake)
    if Tactics.OwnsMove and brake and Tactics.MovingHumanoid and Tactics.MovingHumanoid.Parent then
        pcall(function() Tactics.MovingHumanoid:Move(Vector3.zero,false) end)
    end
    Tactics.OwnsMove=false
    Tactics.MovingHumanoid=nil
    MovementFSM.State="NONE"
end

local touchId=5000

pcall(function() RunService:UnbindFromRenderStep(Config.RENDER_NAME) end)
for _,n in ipairs({"UniversalTPSUI","UniversalTPSOverlay"}) do
	local o=PG:FindFirstChild(n)
	if o then
        local cleanup=o:FindFirstChild("Cleanup")
        if cleanup and cleanup:IsA("BindableEvent") then cleanup:Fire() end
        o:Destroy()
    end
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

local Main=Instance.new("ScrollingFrame")
Main.CanvasSize=UDim2.fromOffset(0,494)
Main.ScrollBarThickness=4
Main.ScrollingDirection=Enum.ScrollingDirection.Y
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
Title.Text="Universal TPS V29"
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

local DelayBox=inputRow("발사 간격",234,Config.FIRE_DELAY)
local DistanceBox=inputRow("최대 거리",266,Config.MAX_DISTANCE)
local SpreadBox=inputRow("퍼짐 배율",298,Config.SPREAD_MULTIPLIER)

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

local ReverseBtn=button(Gui,"리버스: OFF",UDim2.new(0.80,-43,0.66,-82),UDim2.fromOffset(86,36))
ReverseBtn.Name="ReverseShiftLockBtn"
ReverseBtn.TextSize=12
ReverseBtn.ZIndex=10
stroke(ReverseBtn,2)

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

	Tactics.connect(handle.InputBegan,function(i)
		if i.UserInputType~=Enum.UserInputType.Touch and i.UserInputType~=Enum.UserInputType.MouseButton1 then return end
		if (frame==FireBtn or frame==LockBtn) and not Config.DRAG_MODE then return end
		dragging=true
		active=i
		startInput=Vector2.new(i.Position.X,i.Position.Y)
		startPos=frame.Position
	end)

	Tactics.connect(UIS.InputChanged,function(i)
		if not dragging then return end
		if i~=active and i.UserInputType~=Enum.UserInputType.Touch and i.UserInputType~=Enum.UserInputType.MouseMovement then return end
		local p=Vector2.new(i.Position.X,i.Position.Y)
		local d=p-startInput
		frame.Position=UDim2.new(startPos.X.Scale,startPos.X.Offset+d.X,startPos.Y.Scale,startPos.Y.Offset+d.Y)
	end)

	Tactics.connect(UIS.InputEnded,function(i)
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
draggable(ReverseBtn)

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
			Vector3.new(math.cos(a)*radius,Config.RANGE_RING_HEIGHT_OFFSET,math.sin(a)*radius)

		local p=Instance.new("Part")
		p.Name=name
		p.Size=Vector3.new(segmentLength,Config.RANGE_RING_THICKNESS,Config.RANGE_RING_THICKNESS)
		p.Material=Enum.Material.Neon
		p.Color=color
		p.Transparency=Config.RANGE_RING_TRANSPARENCY
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
		root,Config.COUNTER_STRAFE_DISTANCE,Config.RANGE_RING_SEGMENTS_OUTER,
		Color3.fromRGB(255,205,55),"CounterRange",
		function() return Config.COUNTER_STRAFE end
	)
	createRangeLabel(
		root,Config.COUNTER_STRAFE_DISTANCE,
		"반대 "..tostring(Config.COUNTER_STRAFE_DISTANCE),
		Color3.fromRGB(255,205,55),
		function() return Config.COUNTER_STRAFE end
	)

	createRangeRing(
		root,Config.CIRCLE_STRAFE_MAX_DISTANCE,Config.RANGE_RING_SEGMENTS_MID,
		Color3.fromRGB(70,210,255),"CircleRange",
		function() return Config.CIRCLE_STRAFE end
	)
	createRangeLabel(
		root,Config.CIRCLE_STRAFE_MAX_DISTANCE,
		"원형 "..tostring(Config.CIRCLE_STRAFE_MAX_DISTANCE),
		Color3.fromRGB(70,210,255),
		function() return Config.CIRCLE_STRAFE end
	)

	createRangeRing(
		root,Config.SCRAMBLE_MAX_DISTANCE,Config.RANGE_RING_SEGMENTS_INNER,
		Color3.fromRGB(255,75,80),"ScrambleRange",
		function() return Config.CIRCLE_STRAFE end
	)
	createRangeLabel(
		root,Config.SCRAMBLE_MAX_DISTANCE,
		"난전 "..tostring(Config.SCRAMBLE_MAX_DISTANCE),
		Color3.fromRGB(255,75,80),
		function() return Config.CIRCLE_STRAFE end
	)

	createRangeRing(
		root,Config.SCRAMBLE_JUMP_DISTANCE,Config.RANGE_RING_SEGMENTS_INNER,
		Color3.fromRGB(195,95,255),"JumpOverRange",
		function() return Config.CIRCLE_STRAFE end
	)
	createRangeLabel(
		root,Config.SCRAMBLE_JUMP_DISTANCE,
		"점프 "..tostring(Config.SCRAMBLE_JUMP_DISTANCE),
		Color3.fromRGB(195,95,255),
		function() return Config.CIRCLE_STRAFE end
	)
end

local function updateMovementRangeVisual()
	if not Config.MOVEMENT_RANGE_VISIBLE then
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
			e.Part.Transparency=enabled and Config.RANGE_RING_TRANSPARENCY or 1
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
	ShoulderState.Side=Config.SHOULDER_DEFAULT_SIDE
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
			ShoulderState.Side=Config.SHOULDER_DEFAULT_SIDE
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

	if not Config.AUTO_SHOULDER then
		ShoulderState.CurrentX,ShoulderState.VelocityX=smoothDamp1D(
			ShoulderState.CurrentX,
			0,
			ShoulderState.VelocityX,
			Config.SHOULDER_SMOOTH_TIME,
			dt
		)
		h.CameraOffset=ShoulderState.BaseOffset+Vector3.new(ShoulderState.CurrentX,0,0)
		return
	end

	local cameraDistance=(Camera.CFrame.Position-root.Position).Magnitude
	if cameraDistance<Config.SHOULDER_MIN_CAMERA_DISTANCE then
		ShoulderState.CurrentX,ShoulderState.VelocityX=smoothDamp1D(
			ShoulderState.CurrentX,
			0,
			ShoulderState.VelocityX,
			Config.SHOULDER_SMOOTH_TIME,
			dt
		)
		h.CameraOffset=ShoulderState.BaseOffset+Vector3.new(ShoulderState.CurrentX,0,0)
		return
	end

	local anchor=head and head.Position or (root.Position+Vector3.new(0,1.8,0))
	local right=root.CFrame.RightVector
	local leftClear=sideClearance(anchor,-right,Config.SHOULDER_WALL_CHECK)
	local rightClear=sideClearance(anchor,right,Config.SHOULDER_WALL_CHECK)

	local desired=ShoulderState.Side
	local now=os.clock()

	if rightClear+Config.SHOULDER_SWITCH_MARGIN<leftClear then
		desired=-1
	elseif leftClear+Config.SHOULDER_SWITCH_MARGIN<rightClear then
		desired=1
	elseif leftClear>=Config.SHOULDER_WALL_CHECK*0.95 and rightClear>=Config.SHOULDER_WALL_CHECK*0.95 then
		desired=Config.SHOULDER_DEFAULT_SIDE
	end

	if desired~=ShoulderState.Side
		and now-ShoulderState.LastSwitch>=Config.SHOULDER_SWITCH_COOLDOWN then
		ShoulderState.Side=desired
		ShoulderState.LastSwitch=now
	end

	local targetX=Config.SHOULDER_OFFSET*ShoulderState.Side
	ShoulderState.CurrentX,ShoulderState.VelocityX=smoothDamp1D(
		ShoulderState.CurrentX,
		targetX,
		ShoulderState.VelocityX,
		Config.SHOULDER_SMOOTH_TIME,
		dt
	)

	h.CameraOffset=ShoulderState.BaseOffset+Vector3.new(ShoulderState.CurrentX,0,0)
end

function MovementFSM.counterStrafeClearance(direction)
	local c=LP.Character
	local root=c and c:FindFirstChild("HumanoidRootPart")
	if not root or direction.Magnitude<0.01 then return 0 end

	local rp=RaycastParams.new()
	rp.FilterType=Enum.RaycastFilterType.Exclude
	rp.IgnoreWater=true
	rp.FilterDescendantsInstances={c}

	local hit=Workspace:Raycast(
		root.Position+Vector3.new(0,1,0),
		direction.Unit*Config.COUNTER_STRAFE_WALL_CHECK,
		rp
	)

	if not hit then return Config.COUNTER_STRAFE_WALL_CHECK end
	return (hit.Position-(root.Position+Vector3.new(0,1,0))).Magnitude
end

function MovementFSM.releaseCounterStrafe(dt)
	CounterStrafeState.Strength=CounterStrafeState.Strength+
		(0-CounterStrafeState.Strength)*math.clamp(dt*Config.COUNTER_STRAFE_RELEASE,0,1)

	if math.abs(CounterStrafeState.Strength)<0.02 then
		CounterStrafeState.Strength=0
		CounterStrafeState.Direction=0
	end
end

function MovementFSM.updateCounterStrafe(dt,targetData)
	if not Config.COUNTER_STRAFE then
		MovementFSM.releaseCounterStrafe(dt)
		return
	end

	local c=LP.Character
	local h=c and c:FindFirstChildOfClass("Humanoid")
	local root=c and c:FindFirstChild("HumanoidRootPart")
	if not h or not root or not Camera then
		MovementFSM.releaseCounterStrafe(dt)
		return
	end

	if not targetData
		or not targetData.Visible
		or not targetData.Player
		or targetData.Distance>Config.COUNTER_STRAFE_DISTANCE
		or Engagement.State~="ENGAGED"
		or Motion.Player~=targetData.Player then
		MovementFSM.releaseCounterStrafe(dt)
		return
	end

	local vx=Motion.Velocity.X
	if math.abs(vx)<Config.COUNTER_STRAFE_SCREEN_THRESHOLD then
		MovementFSM.releaseCounterStrafe(dt)
		return
	end

	local desiredDir=(vx>0) and -1 or 1

	local camRight=Camera.CFrame.RightVector
	local flatRight=Vector3.new(camRight.X,0,camRight.Z)
	if flatRight.Magnitude<0.01 then
		MovementFSM.releaseCounterStrafe(dt)
		return
	end
	flatRight=flatRight.Unit

	local worldDir=flatRight*desiredDir
	local clearance=MovementFSM.counterStrafeClearance(worldDir)

	if clearance<Config.COUNTER_STRAFE_WALL_CHECK*0.55 then
		MovementFSM.releaseCounterStrafe(dt)
		return
	end

	local speedT=math.clamp(
		(math.abs(vx)-Config.COUNTER_STRAFE_SCREEN_THRESHOLD)/
		math.max(1,Config.COUNTER_STRAFE_FULL_SPEED-Config.COUNTER_STRAFE_SCREEN_THRESHOLD),
		0,
		1
	)

	local desiredStrength=
		Config.COUNTER_STRAFE_MIN_STRENGTH+
		(Config.COUNTER_STRAFE_MAX_STRENGTH-Config.COUNTER_STRAFE_MIN_STRENGTH)*speedT

	CounterStrafeState.Direction=desiredDir
	CounterStrafeState.Strength=CounterStrafeState.Strength+
		(desiredStrength-CounterStrafeState.Strength)*math.clamp(dt*Config.COUNTER_STRAFE_SMOOTH,0,1)

	h:Move(worldDir*CounterStrafeState.Strength,false)
end

function MovementFSM.resetScramble()
	ScrambleState.Player=nil
	ScrambleState.Side=(math.random()<0.5) and -1 or 1
	ScrambleState.JumpUntil=0
	ScrambleState.NextJump=0
	ScrambleState.NextSideSwitch=0
end

function MovementFSM.scrambleClearance(originPos,direction,distance,ignoreTarget)
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

function MovementFSM.scrambleCeilingClear(targetData)
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
		Vector3.new(0,Config.SCRAMBLE_CEILING_CHECK,0),
		rp
	)

	return hit==nil
end

function MovementFSM.updateCloseScramble(dt,targetData)
	local c=LP.Character
	local h=c and c:FindFirstChildOfClass("Humanoid")
	local root=c and c:FindFirstChild("HumanoidRootPart")

	if not Config.CIRCLE_STRAFE
		or not h
		or not root
		or not targetData
		or not targetData.Visible
		or not targetData.Player
		or not targetData.Character
		or Engagement.State~="ENGAGED"
		or targetData.Distance>Config.SCRAMBLE_MAX_DISTANCE then

		MovementFSM.resetScramble()
		return false
	end

	local targetRoot=targetData.Character:FindFirstChild("HumanoidRootPart")
		or targetData.Part
	if not targetRoot then
		MovementFSM.resetScramble()
		return false
	end

	local now=os.clock()

	if ScrambleState.Player~=targetData.Player then
		MovementFSM.resetScramble()
		ScrambleState.Player=targetData.Player
		ScrambleState.Side=(math.random()<0.5) and -1 or 1
		ScrambleState.NextJump=now
		ScrambleState.NextSideSwitch=now+
			Config.SCRAMBLE_SIDE_SWITCH_MIN+
			math.random()*(Config.SCRAMBLE_SIDE_SWITCH_MAX-Config.SCRAMBLE_SIDE_SWITCH_MIN)
	end

	if now>=ScrambleState.NextSideSwitch then
		ScrambleState.Side=-ScrambleState.Side
		ScrambleState.NextSideSwitch=now+
			Config.SCRAMBLE_SIDE_SWITCH_MIN+
			math.random()*(Config.SCRAMBLE_SIDE_SWITCH_MAX-Config.SCRAMBLE_SIDE_SWITCH_MIN)
	end

	local toTarget=targetRoot.Position-root.Position
	local flatToTarget=Vector3.new(toTarget.X,0,toTarget.Z)
	if flatToTarget.Magnitude<0.05 then return false end
	flatToTarget=flatToTarget.Unit

	local tangent=Vector3.new(-flatToTarget.Z,0,flatToTarget.X)*ScrambleState.Side
	local start=root.Position+Vector3.new(0,1,0)

	if targetData.Distance<=Config.SCRAMBLE_JUMP_DISTANCE
		and now>=ScrambleState.NextJump
		and h.FloorMaterial~=Enum.Material.Air
		and MovementFSM.scrambleCeilingClear(targetData) then

		h.Jump=true
		ScrambleState.JumpUntil=now+Config.SCRAMBLE_JUMP_MOVE_TIME
		ScrambleState.NextJump=now+
			Config.SCRAMBLE_JUMP_COOLDOWN_MIN+
			math.random()*(Config.SCRAMBLE_JUMP_COOLDOWN_MAX-Config.SCRAMBLE_JUMP_COOLDOWN_MIN)

		if math.random()<0.5 then
			ScrambleState.Side=-ScrambleState.Side
			tangent=-tangent
		end
	end

	local desired

	if now<=ScrambleState.JumpUntil then

		desired=flatToTarget*Config.SCRAMBLE_FORWARD_BIAS+
			tangent*Config.SCRAMBLE_TANGENT_BIAS
	else

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

	local clear=MovementFSM.scrambleClearance(start,desired,Config.SCRAMBLE_WALL_CHECK,targetData)
	if clear<Config.SCRAMBLE_WALL_CHECK*0.5 then
		ScrambleState.Side=-ScrambleState.Side
		tangent=-tangent

		if now<=ScrambleState.JumpUntil then
			desired=(flatToTarget*Config.SCRAMBLE_FORWARD_BIAS+
				tangent*Config.SCRAMBLE_TANGENT_BIAS).Unit
		else
			desired=tangent
		end

		clear=MovementFSM.scrambleClearance(start,desired,Config.SCRAMBLE_WALL_CHECK,targetData)
	end

	if clear<Config.SCRAMBLE_WALL_CHECK*0.35 then
		return false
	end

	h:Move(desired*Config.SCRAMBLE_MOVE_STRENGTH,false)
	return true
end

function MovementFSM.releaseCircleStrafe(dt)
	CircleStrafeState.Strength=CircleStrafeState.Strength+
		(0-CircleStrafeState.Strength)*math.clamp(dt*Config.CIRCLE_STRAFE_RELEASE,0,1)

	if math.abs(CircleStrafeState.Strength)<0.02 then
		CircleStrafeState.Strength=0
		CircleStrafeState.Player=nil
		CircleStrafeState.NextSwitch=0
	end
end

function MovementFSM.circleClearance(direction)
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
		direction.Unit*Config.CIRCLE_STRAFE_WALL_CHECK,
		rp
	)

	if not hit then return Config.CIRCLE_STRAFE_WALL_CHECK end
	return (hit.Position-start).Magnitude
end

function MovementFSM.updateCircleStrafe(dt,targetData)
	if not Config.CIRCLE_STRAFE then
		MovementFSM.releaseCircleStrafe(dt)
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
		or targetData.Distance>Config.CIRCLE_STRAFE_MAX_DISTANCE then
		MovementFSM.releaseCircleStrafe(dt)
		return false
	end

	local targetRoot=targetData.Character:FindFirstChild("HumanoidRootPart")
		or targetData.Part
	if not targetRoot then
		MovementFSM.releaseCircleStrafe(dt)
		return false
	end

	local now=os.clock()

	if CircleStrafeState.Player~=targetData.Player then
		CircleStrafeState.Player=targetData.Player
		CircleStrafeState.Side=(math.random()<0.5) and -1 or 1
		CircleStrafeState.LastSwitch=now
		CircleStrafeState.NextSwitch=now+
			Config.CIRCLE_STRAFE_RANDOM_SWITCH_MIN+
			math.random()*(Config.CIRCLE_STRAFE_RANDOM_SWITCH_MAX-Config.CIRCLE_STRAFE_RANDOM_SWITCH_MIN)
	elseif CircleStrafeState.NextSwitch==0 then
		CircleStrafeState.NextSwitch=now+
			Config.CIRCLE_STRAFE_RANDOM_SWITCH_MIN+
			math.random()*(Config.CIRCLE_STRAFE_RANDOM_SWITCH_MAX-Config.CIRCLE_STRAFE_RANDOM_SWITCH_MIN)
	elseif now>=CircleStrafeState.NextSwitch
		and now-CircleStrafeState.LastSwitch>=Config.CIRCLE_STRAFE_SWITCH_COOLDOWN then

		CircleStrafeState.Side=-CircleStrafeState.Side
		CircleStrafeState.LastSwitch=now
		CircleStrafeState.NextSwitch=now+
			Config.CIRCLE_STRAFE_RANDOM_SWITCH_MIN+
			math.random()*(Config.CIRCLE_STRAFE_RANDOM_SWITCH_MAX-Config.CIRCLE_STRAFE_RANDOM_SWITCH_MIN)
	end

	local delta=root.Position-targetRoot.Position
	local flat=Vector3.new(delta.X,0,delta.Z)
	local dist=flat.Magnitude
	if dist<0.1 then
		MovementFSM.releaseCircleStrafe(dt)
		return false
	end

	local radial=flat.Unit

	local tangent=Vector3.new(-radial.Z,0,radial.X)*CircleStrafeState.Side

	local radialError=dist-Config.CIRCLE_STRAFE_IDEAL_DISTANCE
	local radialCorrection=math.clamp(
		radialError*Config.CIRCLE_STRAFE_RADIAL_GAIN,
		-0.55,
		0.55
	)

	local desired=(tangent-radial*radialCorrection)
	if desired.Magnitude<0.01 then
		MovementFSM.releaseCircleStrafe(dt)
		return false
	end
	desired=desired.Unit

	local clearance=MovementFSM.circleClearance(desired)
	if clearance<Config.CIRCLE_STRAFE_WALL_CHECK*0.55 then
		if now-CircleStrafeState.LastSwitch>=Config.CIRCLE_STRAFE_SWITCH_COOLDOWN then
			CircleStrafeState.Side=-CircleStrafeState.Side
			CircleStrafeState.LastSwitch=now
			CircleStrafeState.NextSwitch=now+
				Config.CIRCLE_STRAFE_RANDOM_SWITCH_MIN+
				math.random()*(Config.CIRCLE_STRAFE_RANDOM_SWITCH_MAX-Config.CIRCLE_STRAFE_RANDOM_SWITCH_MIN)
			tangent=Vector3.new(-radial.Z,0,radial.X)*CircleStrafeState.Side
			desired=(tangent-radial*radialCorrection)
			if desired.Magnitude>0.01 then desired=desired.Unit end
			clearance=MovementFSM.circleClearance(desired)
		end
	end

	if clearance<Config.CIRCLE_STRAFE_WALL_CHECK*0.45 then
		MovementFSM.releaseCircleStrafe(dt)
		return false
	end

	if dist<Config.CIRCLE_STRAFE_MIN_DISTANCE then
		desired=(desired+radial*0.85)
		if desired.Magnitude>0.01 then desired=desired.Unit end
	end

	local proximity=1-math.clamp(
		(dist-Config.CIRCLE_STRAFE_MIN_DISTANCE)/
		math.max(0.1,Config.CIRCLE_STRAFE_MAX_DISTANCE-Config.CIRCLE_STRAFE_MIN_DISTANCE),
		0,
		1
	)

	local targetStrength=
		Config.CIRCLE_STRAFE_MIN_STRENGTH+
		(Config.CIRCLE_STRAFE_MAX_STRENGTH-Config.CIRCLE_STRAFE_MIN_STRENGTH)*proximity

	CircleStrafeState.Strength=CircleStrafeState.Strength+
		(targetStrength-CircleStrafeState.Strength)*
		math.clamp(dt*Config.CIRCLE_STRAFE_SMOOTH,0,1)

	h:Move(desired*CircleStrafeState.Strength,false)
	return true
end

function MovementFSM.chooseMovementState(targetData)
	if not targetData
		or not targetData.Visible
		or not targetData.Player
		or Engagement.State~="ENGAGED" then
		return "NONE"
	end

	local d=targetData.Distance

	if Config.CIRCLE_STRAFE and d<=Config.SCRAMBLE_JUMP_DISTANCE then
		return "JUMP_OVER"
	elseif Config.CIRCLE_STRAFE and d<=Config.SCRAMBLE_MAX_DISTANCE then
		return "SCRAMBLE"
	elseif Config.CIRCLE_STRAFE and d<=Config.CIRCLE_STRAFE_MAX_DISTANCE then
		return "CIRCLE"
	elseif Config.COUNTER_STRAFE and d<=Config.COUNTER_STRAFE_DISTANCE then
		return "COUNTER"
	end

	return "NONE"
end

function MovementFSM.updateMovementFSM(dt,targetData)
    if Tactics.Enabled and Tactics.update then
        MovementFSM.resetScramble()
        MovementFSM.releaseCircleStrafe(dt)
        MovementFSM.releaseCounterStrafe(dt)
        return Tactics.update(dt,targetData)
    end
    Tactics.release(true)
	local state=MovementFSM.chooseMovementState(targetData)
	MovementFSM.State=state

	if state=="JUMP_OVER" or state=="SCRAMBLE" then
		local moved=MovementFSM.updateCloseScramble(dt,targetData)
		MovementFSM.releaseCircleStrafe(dt)
		MovementFSM.releaseCounterStrafe(dt)
		return moved
	elseif state=="CIRCLE" then
		MovementFSM.resetScramble()
		local moved=MovementFSM.updateCircleStrafe(dt,targetData)
		MovementFSM.releaseCounterStrafe(dt)
		return moved
	elseif state=="COUNTER" then
		MovementFSM.resetScramble()
		MovementFSM.releaseCircleStrafe(dt)
		MovementFSM.updateCounterStrafe(dt,targetData)
		return true
	end

	MovementFSM.resetScramble()
	MovementFSM.releaseCircleStrafe(dt)
	MovementFSM.releaseCounterStrafe(dt)
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
			total=total+1
			local t=1-(1-math.clamp(v.Transparency,0,1))*(1-math.clamp(v.LocalTransparencyModifier,0,1))
			if t>=Config.TRANSPARENCY_LIMIT then inv=inv+1 end
		end
	end

	return total>0 and inv/total>=Config.TRANSPARENT_RATIO
end

local function eligible(p)
	if not p or p==LP then return false end
	if Whitelist[p.Name] then return false end
	if Config.TEAM_CHECK and LP.Team~=nil and p.Team==LP.Team then return false end
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
	if not Config.WALL_CHECK then return true end
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

	e.Until=os.clock()+Config.SEEN_HIGHLIGHT_TIME
	e.Highlight.Adornee=c
	e.Highlight.Enabled=true
end

local function updateSeenHighlights(dt)
	SeenScanAccum=SeenScanAccum+dt

	if SeenScanAccum>=Config.SEEN_SCAN_INTERVAL then
		SeenScanAccum=SeenScanAccum%Config.SEEN_SCAN_INTERVAL

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
		anchor-flatToTarget*Config.CAMERA_EQ_RADIUS+up*Config.CAMERA_EQ_HEIGHT,
		anchor+flatToTarget*Config.CAMERA_EQ_RADIUS+up*Config.CAMERA_EQ_HEIGHT,
		anchor+right*Config.CAMERA_EQ_SIDE_RADIUS+up*Config.CAMERA_EQ_HEIGHT,
		anchor-right*Config.CAMERA_EQ_SIDE_RADIUS+up*Config.CAMERA_EQ_HEIGHT,
		anchor+(-flatToTarget+right).Unit*Config.CAMERA_EQ_RADIUS+up*Config.CAMERA_EQ_HEIGHT,
		anchor+(-flatToTarget-right).Unit*Config.CAMERA_EQ_RADIUS+up*Config.CAMERA_EQ_HEIGHT,
		anchor+(flatToTarget+right).Unit*Config.CAMERA_EQ_RADIUS+up*Config.CAMERA_EQ_HEIGHT,
		anchor+(flatToTarget-right).Unit*Config.CAMERA_EQ_RADIUS+up*Config.CAMERA_EQ_HEIGHT,
		anchor+up*Config.CAMERA_EQ_EXTRA_HEIGHT
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

	local maxSamples=math.min(#origins,Config.CAMERA_EQ_SAMPLE_COUNT)
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

	e.Until=os.clock()+Config.CAMERA_EQ_HIGHLIGHT_TIME
	e.Highlight.Adornee=c
	e.Highlight.Enabled=true
end

local function updatePinkHighlights(dt)
	PinkScanAccum=PinkScanAccum+dt

	if PinkScanAccum>=Config.CAMERA_EQ_SCAN_INTERVAL then
		PinkScanAccum=PinkScanAccum%Config.CAMERA_EQ_SCAN_INTERVAL

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
	while #s.Samples>Config.PEEK_SAMPLE_LIMIT do
		table.remove(s.Samples,1)
	end

	local sum=Vector3.zero
	for _,v in ipairs(s.Samples) do
		sum=sum+v
	end
	if #s.Samples>0 then
		s.EdgePosition=sum/#s.Samples
	end
end

local function registerPeekHide(player,pos)
	if not player or not pos then return end
	local s=peekState(player)

	if s.EdgePosition and (pos-s.EdgePosition).Magnitude>12 then
		s.Samples={}
		s.EdgePosition=nil
	end

	local now=os.clock()
	s.HiddenAt=now
	s.WaitUntil=now+Config.PEEK_WAIT_TIME
	s.ReacquireUntil=0
	s.LastVisible=pos
	ActivePeekPlayer=player
end

local function cleanupPeek()
	local now=os.clock()
	for p,s in pairs(PeekStates) do
		if not eligible(p) or (
			s.HiddenAt>0
			and now-s.HiddenAt>Config.MEMORY_TIME
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
	MemorySerial=MemorySerial+1
	Memories[player]={Position=pos,Expires=os.clock()+Config.MEMORY_TIME,Serial=MemorySerial}
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
	TargetHysteresis.HoldUntil=now+Config.HYSTERESIS_HOLD_TIME
	TargetHysteresis.ReturnUntil=now+Config.HYSTERESIS_RETURN_WINDOW
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
	if part and (part.Position-org).Magnitude<=Config.MAX_DISTANCE then
		local d=data(p,part,org,part.Position,"HYST_REACQUIRE",true)
		clearTargetHysteresis()
		return d
	end

	local pos=TargetHysteresis.LastPosition
	if now<=TargetHysteresis.HoldUntil
		and pos
		and (pos-org).Magnitude<=Config.MAX_DISTANCE then
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
				if dist<=Config.MAX_DISTANCE then
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
	if not part or (part.Position-org).Magnitude>Config.MAX_DISTANCE then
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
			if part and (part.Position-org).Magnitude<=Config.MAX_DISTANCE and m.Serial>serial then
				best=data(p,part,org,part.Position,"REAPPEAR",true)
				serial=m.Serial
			end
		end
	end

	if best then
		Memories[best.Player]=nil
		Reacquire.Player=best.Player
		Reacquire.Until=os.clock()+Config.REACQUIRE_HOLD
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
	if not part or (part.Position-org).Magnitude>Config.MAX_DISTANCE then
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
	if now-s.HiddenAt>Config.PEEK_WINDOW then
		return nil
	end

	if not eligible(p) then return nil end
	local part=resolvedVisiblePart(p)
	if not part or (part.Position-org).Magnitude>Config.MAX_DISTANCE then return nil end

	addPeekSample(s,part.Position)
	s.HiddenAt=0
	s.WaitUntil=0
	s.ReacquireUntil=now+Config.PEEK_REACQUIRE_HOLD
	s.LastVisible=part.Position
	Memories[p]=nil

	resetMotion()

	return data(p,part,org,part.Position,"PEEK_REACQUIRE",true)
end

local function peekWait(org)
	local p=ActivePeekPlayer
	if not p or not eligible(p) then return nil end
	local s=PeekStates[p]
	if not s or s.HiddenAt<=0 then return nil end

	local now=os.clock()
	if now>s.WaitUntil or now-s.HiddenAt>Config.PEEK_WINDOW then return nil end

	local pos=s.EdgePosition or s.LastVisible
	if not pos or (pos-org).Magnitude>Config.MAX_DISTANCE then return nil end

	return data(p,aimPart(p.Character),org,pos,"PEEK_WAIT",false)
end

local function latestMemory(org)
	local bp,bm=nil,nil
	local serial=-1
	for p,m in pairs(Memories) do
		if eligible(p) and m.Serial>serial and (m.Position-org).Magnitude<=Config.MAX_DISTANCE then
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
	if not part or (part.Position-org).Magnitude>Config.MAX_DISTANCE then
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

local function clearPostLossFire()
	PostLossFire.Player=nil
	PostLossFire.Character=nil
	PostLossFire.Position=nil
	PostLossFire.Until=0
	PostLossFire.Reason=nil
end

local function postLossActive()
	if not PostLossFire.Position then return false end
	if os.clock()>=PostLossFire.Until then
		clearPostLossFire()
		return false
	end
	return true
end

local function beginPostLossFire(player,pos,reason)
	if not pos then return end

	local now=os.clock()

	if PostLossFire.Player==player
		and PostLossFire.Position
		and now<PostLossFire.Until then
		return
	end

	local duration=
		Config.KILL_SWITCH_DELAY_MIN+
		(Config.KILL_SWITCH_DELAY_MAX-Config.KILL_SWITCH_DELAY_MIN)*math.random()

	PostLossFire.Player=player
	PostLossFire.Character=player and player.Character or nil
	PostLossFire.Position=pos
	PostLossFire.Until=now+duration
	PostLossFire.Reason=reason

	KillSwitchDelayUntil=PostLossFire.Until
	setEngagement("KILL_DELAY",player,pos)
end

local function combatLockedTarget(org)
	local p=CombatLockPlayer
	if not p then return nil end

	if not eligible(p) then
		clearCombatLock()
		return nil
	end

	local part=resolvedVisiblePart(p)
	if part and (part.Position-org).Magnitude<=Config.MAX_DISTANCE then
		CombatLockLastPosition=part.Position
		CombatLockLostAt=0
		setEngagement("ENGAGED",p,part.Position)
		return data(p,part,org,part.Position,"COMBAT_LOCK",true)
	end

	local pos=CombatLockLastPosition
	if not pos or (pos-org).Magnitude>Config.MAX_DISTANCE then
		clearCombatLock()
		return nil
	end

	local now=os.clock()
	if CombatLockLostAt==0 then
		CombatLockLostAt=now
		beginPostLossFire(p,pos,"LOST")
	end

	if now-CombatLockLostAt<=Config.COMBAT_LOCK_LOST_GRACE then
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
			Motion.Velocity=Motion.Velocity:Lerp(v,Config.VELOCITY_SMOOTH)
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
		or math.abs(Motion.Velocity.Y)>=Config.JUMP_SCREEN_Y_THRESHOLD

	local landingSoon=false
	if airborne and worldY<0 then
		local rp=RaycastParams.new()
		rp.FilterType=Enum.RaycastFilterType.Exclude
		rp.IgnoreWater=true
		rp.FilterDescendantsInstances={c}

		local castDistance=math.max(3.5,h.HipHeight+Config.LANDING_CHECK_EXTRA)
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
	elseif now-JumpTrack.LandedAt<=Config.LANDING_DAMP_TIME then
		JumpTrack.State="LANDING"
	else
		JumpTrack.State="GROUND"
	end

	return JumpTrack.State
end

local function lead(player)
    if Tactics.lead then
        local offset=Tactics.lead(player)
        if offset then return offset end
    end
	local l=Motion.Velocity*Config.LEAD_TIME
	local state=jumpState(player)

	if state=="AIR" then
		l=Vector2.new(
			l.X,
			math.clamp(
				l.Y*Config.JUMP_VERTICAL_LEAD_SCALE,
				-Config.JUMP_MAX_VERTICAL_LEAD_PX,
				Config.JUMP_MAX_VERTICAL_LEAD_PX
			)
		)
	elseif state=="LANDING" then
		l=Vector2.new(
			l.X,
			math.clamp(
				l.Y*Config.LANDING_VERTICAL_LEAD_SCALE,
				-Config.JUMP_MAX_VERTICAL_LEAD_PX*0.5,
				Config.JUMP_MAX_VERTICAL_LEAD_PX*0.5
			)
		)
	end

	if l.Magnitude>Config.MAX_LEAD_PX then
		l=l.Unit*Config.MAX_LEAD_PX
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
	if Config.SPREAD_MULTIPLIER<=0 then return 0 end

	local ratio
	if distance<=Config.MID_DISTANCE then
		local t=math.clamp((distance-Config.NEAR_DISTANCE)/math.max(1,Config.MID_DISTANCE-Config.NEAR_DISTANCE),0,1)^0.8
		ratio=Config.NEAR_RATIO+(Config.MID_RATIO-Config.NEAR_RATIO)*t
	else
		local t=math.clamp((distance-Config.MID_DISTANCE)/math.max(1,Config.FAR_DISTANCE-Config.MID_DISTANCE),0,1)^0.8
		ratio=Config.MID_RATIO+(Config.FAR_RATIO-Config.MID_RATIO)*t
	end

	local sigma=screenRadius(character)*ratio

	local closeT=1-math.clamp(distance/Config.CLOSE_SPREAD_END,0,1)
	sigma=sigma*(1+Config.CLOSE_SPREAD_BONUS*closeT)

	local ft=math.clamp((distance-Config.FAR_FORCE_START)/math.max(1,Config.FAR_FORCE_END-Config.FAR_FORCE_START),0,1)
	local forced=Config.FAR_MIN_START+(Config.FAR_MIN_END-Config.FAR_MIN_START)*ft
	sigma=math.max(sigma,forced)

	sigma=sigma*Config.SPREAD_MULTIPLIER

	return math.clamp(
		sigma,
		Config.MIN_SPREAD_PX*Config.SPREAD_MULTIPLIER,
		Config.MAX_SPREAD_PX*Config.SPREAD_MULTIPLIER
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
	return Config.KILL_SWITCH_DELAY_MIN+
		(Config.KILL_SWITCH_DELAY_MAX-Config.KILL_SWITCH_DELAY_MIN)*math.random()
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

		local deathPos=CombatLockLastPosition
		if not deathPos then
			local c=player.Character
			local root=c and c:FindFirstChild("HumanoidRootPart")
			deathPos=root and root.Position or LastAutoPosition
		end

		beginPostLossFire(player,deathPos,"DEAD")

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
	touchId=touchId+1
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

	local step=math.min(angle,math.rad(Config.PULL_MAX_STEP_DEG),Config.PULL_SPEED*math.max(dt,0))
	local look=a:Lerp(b,math.clamp(step/angle,0,1))
	if look.Magnitude<0.001 then return end

	Camera.CFrame=CFrame.lookAt(pos,pos+look.Unit,Vector3.yAxis)
end

function Tactics.flat(v)
	return Vector3.new(v.X,0,v.Z)
end

function Tactics.unit(v,fallback)
	return v.Magnitude>0.001 and v.Unit or (fallback or Vector3.zero)
end

function Tactics.flag(object,names)
	if not object then return false end
	for _,name in ipairs(names) do
		if object:GetAttribute(name)==true then return true end
		local value=object:FindFirstChild(name)
		if value and value:IsA("BoolValue") and value.Value then return true end
	end
	return false
end

function Tactics.reloading(character)
	local tool=character and character:FindFirstChildOfClass("Tool")
	local names={"Reloading","IsReloading","IsReload"}
	return Tactics.flag(character,names) or Tactics.flag(tool,names)
end

function Tactics.rememberHit(position,now,damage)
	Tactics.DangerSpots=Tactics.DangerSpots or {}
	local spots=Tactics.DangerSpots
	local recent=spots[#spots]
	if recent and now-recent.Time<0.3 and (recent.Position-position).Magnitude<2 then
		recent.Weight=math.min(2.5,recent.Weight+damage*5)
		recent.Time=now
	else
		spots[#spots+1]={Position=position,Time=now,Weight=math.clamp(0.7+damage*6,0.7,2.5)}
	end
	while #spots>8 do table.remove(spots,1) end
	if Tactics.CoverPhase=="OUT" and Tactics.PeekGoal then
		Tactics.BadPeek={Position=Tactics.PeekGoal,Time=now}
	end
end

function Tactics.danger(position,now)
	if not Tactics.Sense then return 0 end
	local value=0
	local spots=Tactics.DangerSpots or {}
	for i=#spots,1,-1 do
		local spot=spots[i]
		local age=now-spot.Time
		if age>3.5 then table.remove(spots,i)
		else
			local radius=4.5
			local near=math.max(0,1-Tactics.flat(position-spot.Position).Magnitude/radius)
			value=value+near*near*(1-age/3.5)*spot.Weight
		end
	end
	return math.min(4,value)
end

function Tactics.peekPenalty(position,now)
	if not Tactics.Sense then return 0 end
	local penalty=Tactics.danger(position,now)*2
	for _,entry in ipairs({Tactics.LastPeek or {},Tactics.BadPeek or {}}) do
		if entry.Position then
			local age=now-entry.Time
			if age<3.5 then
				local near=math.max(0,1-Tactics.flat(position-entry.Position).Magnitude/3)
				penalty=penalty+near*(1-age/3.5)*(entry==Tactics.BadPeek and 3 or 0.8)
			end
		end
	end
	return penalty
end

function Tactics.manualInput()
	if UIS:GetFocusedTextBox() or Config.DRAG_MODE then return true end
	if not Tactics.ManualPriority then return false end
	if Tactics.Controls then
		local ok,v=pcall(function() return Tactics.Controls:GetMoveVector() end)
		if ok and v and v.Magnitude>0.12 then return true end
	end
	for _,key in ipairs({Enum.KeyCode.W,Enum.KeyCode.A,Enum.KeyCode.S,Enum.KeyCode.D,Enum.KeyCode.Up,Enum.KeyCode.Down,Enum.KeyCode.Left,Enum.KeyCode.Right}) do
		if UIS:IsKeyDown(key) then return true end
	end
	return false
end

function Tactics.restoreReverse()
	local state=Tactics.ReverseState
	if state and state.Humanoid and state.Humanoid.Parent then
		pcall(function() state.Humanoid.AutoRotate=state.AutoRotate end)
	end
	Tactics.ReverseState=nil
end

function Tactics.refreshReverseButtons()
	local text=Tactics.Reverse and "리버스: ON" or "리버스: OFF"
	local color=Tactics.Reverse and Color3.fromRGB(68,112,205) or Color3.fromRGB(60,60,70)
	for _,b in ipairs({Tactics.ReverseButton,Tactics.ReverseMenuButton}) do
		if b and b.Parent then
			b.Text=text
			b.BackgroundColor3=color
		end
	end
end

function Tactics.setReverse(enabled)
	Tactics.Reverse=enabled==true
	if not Tactics.Reverse then Tactics.restoreReverse() end
	Tactics.refreshReverseButtons()
end

function Tactics.updateReverse()
	local c=LP.Character
	local h=c and c:FindFirstChildOfClass("Humanoid")
	local root=c and c:FindFirstChild("HumanoidRootPart")
	if not Tactics.Reverse or not h or h.Health<=0 or not root or root.Anchored or h.Sit or h.PlatformStand or not Camera then
		Tactics.restoreReverse()
		return false
	end
	local state=Tactics.ReverseState
	if not state or state.Humanoid~=h or state.Character~=c then
		Tactics.restoreReverse()
		state={Humanoid=h,Character=c,AutoRotate=h.AutoRotate}
		Tactics.ReverseState=state
	end
	h.AutoRotate=false
	local look=Tactics.flat(Camera.CFrame.LookVector)
	if look.Magnitude<0.001 then return false end
	local opposite=-look.Unit
	root.CFrame=CFrame.lookAt(root.Position,root.Position+opposite,Vector3.yAxis)
	return true
end

function Tactics.reset(brake)
	Tactics.release(brake)
	Tactics.Snapshot=nil
	Tactics.Threats={}
	Tactics.NextThreatScan=0
	Tactics.Accum=0
	Tactics.Output=Vector3.zero
	Tactics.CoverHome=nil
	Tactics.PeekGoal=nil
	Tactics.CoverPhase=nil
	Tactics.JumpGoal=nil
	Tactics.JumpUntil=0
	Tactics.NextJump=Tactics.NextJump or 0
	Tactics.NextSwitch=0
	Tactics.LastSwitch=0
	Tactics.LastPosition=nil
	Tactics.LastPeek=nil
	Tactics.StuckFor=0
	Tactics.AimVelocity=Vector3.zero
	Tactics.LocalReload=false
	Tactics.Mode="대기"
	Tactics.Reason=""
end

function Tactics.observe(d,root,now,dt)
	local s=Tactics.Snapshot
	if d and d.Visible and d.Part and eligible(d.Player) and actualLos(d.Player,d.Part) then
		local tr=d.Character and d.Character:FindFirstChild("HumanoidRootPart")
		local th=d.Character and d.Character:FindFirstChildOfClass("Humanoid")
		if tr and th then
			local changed=not s or s.Player~=d.Player or s.Character~=d.Character
			local raw=tr.AssemblyLinearVelocity
			if raw.Magnitude>120 then raw=Vector3.zero end
			if changed then
				Tactics.CoverHome=nil
				Tactics.CoverPhase=nil
				Tactics.PeekGoal=nil
				Tactics.JumpGoal=nil
				Tactics.NextSwitch=0
				Tactics.LastLateral=0
				Tactics.NextThreatScan=0
				Tactics.AimVelocity=raw
				s={Player=d.Player,Character=d.Character,Ideal=math.clamp(Tactics.flat(tr.Position-root.Position).Magnitude,16,44)}
			else
				local alpha=1-math.exp(-18*math.max(dt,0.001))
				if raw:Dot(Tactics.AimVelocity)<0 or (raw-Tactics.AimVelocity).Magnitude>28 then alpha=1 end
				Tactics.AimVelocity=Tactics.AimVelocity:Lerp(raw,alpha)
			end
			local observedDt=s.LastSeen and now-s.LastSeen or 0
			local newLook=Tactics.unit(Tactics.flat(tr.CFrame.LookVector))
			local newAir=th.FloorMaterial==Enum.Material.Air
			if observedDt>0.001 and observedDt<0.20 then
				if s.Air and not newAir then s.LandedAt=now end
				local previous=Tactics.flat(s.Velocity)
				local current=Tactics.flat(raw)
				if previous.Magnitude>4 and current.Magnitude>4 and previous:Dot(current)<-0.2*previous.Magnitude*current.Magnitude then
					s.ReversedAt=now
				end
				local angle=math.acos(math.clamp(s.Look:Dot(newLook),-1,1))
				local sign=s.Look:Cross(newLook).Y>=0 and 1 or -1
				local rate=angle<0.9 and math.clamp(angle*sign/observedDt,-6,6) or 0
				s.TurnRate=(s.TurnRate or 0)*0.65+rate*0.35
			else s.TurnRate=0 end
			s.Position=tr.Position
			s.AimPosition=d.Position
			s.HeadPosition=(d.Character:FindFirstChild("Head") or tr).Position
			s.Velocity=raw
			s.Look=newLook
			s.Health=th.Health/math.max(1,th.MaxHealth)
			s.Air=newAir
			s.Reload=Tactics.reloading(d.Character)
			s.LastSeen=now
			Tactics.Snapshot=s
		end
	end
	return Tactics.Snapshot
end

function Tactics.scanThreats(ctx)
	if ctx.Now<Tactics.NextThreatScan then return end
	Tactics.NextThreatScan=ctx.Now+0.35
	local candidates={}
	for _,p in ipairs(Players:GetPlayers()) do
		if p~=ctx.Snapshot.Player and p~=LP and p.Character then
			local head=p.Character:FindFirstChild("Head")
			local r=p.Character:FindFirstChild("HumanoidRootPart")
			if head and r then
				local distance=(r.Position-ctx.Position).Magnitude
				if distance<=math.min(Config.MAX_DISTANCE,100) then
					candidates[#candidates+1]={Player=p,Head=head,Root=r,Distance=distance}
				end
			end
		end
	end
	table.sort(candidates,function(a,b) return a.Distance<b.Distance end)
	Tactics.Threats={}
	for i=1,math.min(8,#candidates) do
		local v=candidates[i]
		if eligible(v.Player) and actualLos(v.Player,v.Head) then
			Tactics.Threats[#Tactics.Threats+1]={Character=v.Player.Character,Position=v.Head.Position,LastSeen=ctx.Now}
			if #Tactics.Threats>=2 then break end
		end
	end
end

function Tactics.context(h,root,s,now)
	local ctx={Humanoid=h,Root=root,Position=root.Position,Snapshot=s,Now=now}
	ctx.Age=now-s.LastSeen
	ctx.Target=s.Position+Tactics.flat(s.Velocity)*math.min(ctx.Age,0.10)
	ctx.To=Tactics.unit(Tactics.flat(ctx.Target-ctx.Position),Tactics.unit(Tactics.flat(root.CFrame.LookVector)))
	ctx.Tangent=Vector3.new(-ctx.To.Z,0,ctx.To.X)
	ctx.Distance=Tactics.flat(ctx.Target-ctx.Position).Magnitude
	ctx.Speed=math.max(0,h.WalkSpeed)
	ctx.Horizon=0.24
	ctx.Travel=math.clamp(ctx.Speed*ctx.Horizon,2.2,6)
	ctx.Facing=s.Look:Dot(-ctx.To)
	ctx.Health=h.Health/math.max(1,h.MaxHealth)
	ctx.Hurt=now-(Tactics.HitAt or -100)<0.65
	ctx.Defensive=Tactics.Disengage and (ctx.Health<0.38 or Tactics.LocalReload or (ctx.Hurt and (Tactics.DamageFraction or 0)>0.09))
	ctx.Close=Config.CIRCLE_STRAFE and ctx.Distance<=Config.CIRCLE_STRAFE_MAX_DISTANCE
	ctx.Ideal=ctx.Close and Config.CIRCLE_STRAFE_IDEAL_DISTANCE or s.Ideal
	ctx.FootHeight=math.max(3,h.HipHeight+root.Size.Y*0.5)
	ctx.SlopeY=math.cos(math.rad(math.min(50,h.MaxSlopeAngle)))
	Tactics.scanThreats(ctx)
	ctx.Threats={{Character=s.Character,Position=s.HeadPosition,LastSeen=s.LastSeen}}
	for _,threat in ipairs(Tactics.Threats) do
		if now-threat.LastSeen<0.55 then ctx.Threats[#ctx.Threats+1]=threat end
	end
	local ignore={LP.Character,MovementRangeVisual.Folder}
	for _,threat in ipairs(ctx.Threats) do ignore[#ignore+1]=threat.Character end
	Tactics.Solid.FilterDescendantsInstances=ignore
	Tactics.Sight.FilterDescendantsInstances=ignore
	Tactics.Solid.CollisionGroup=root.CollisionGroup
	Tactics.Sight.CollisionGroup=root.CollisionGroup
	local floor=Workspace:Raycast(ctx.Position+Vector3.new(0,0.5,0),Vector3.new(0,-ctx.FootHeight-3,0),Tactics.Solid)
	ctx.FloorY=floor and floor.Position.Y or (ctx.Position.Y-ctx.FootHeight)
	ctx.Grounded=h.FloorMaterial~=Enum.Material.Air
	ctx.Landing=Tactics.Sense and ctx.Age<0.15 and now-(s.LandedAt or -100)<0.22
	if Tactics.Sense and ctx.Age<0.15 and s.Air and s.Velocity.Y< -2 then
		local hit=Workspace:Raycast(s.Position,Vector3.new(0,-6,0),Tactics.Solid)
		if hit then
			local gap=math.max(0,hit.Distance-3)
			ctx.Landing=gap/math.max(2,-s.Velocity.Y)<0.18
		end
	end
	return ctx
end

function Tactics.sweep(position,delta,ctx)
	if delta.Magnitude<0.001 then return nil end
	local dir=delta.Unit
	if Tactics.BlockcastAvailable then
		local ok,hit=pcall(function()
			return Workspace:Blockcast(CFrame.lookAt(position+Vector3.new(0,0.6,0),position+Vector3.new(0,0.6,0)+dir),Vector3.new(math.clamp(ctx.Root.Size.X+0.4,1.8,3),3.5,1.4),delta,Tactics.Solid)
		end)
		if ok then return hit end
		Tactics.BlockcastAvailable=false
	end
	local side=Tactics.unit(Vector3.new(-dir.Z,0,dir.X))*1.05
	local nearest=nil
	for _,offset in ipairs({Vector3.zero,side,-side,Vector3.new(0,1.7,0)}) do
		local hit=Workspace:Raycast(position+offset+Vector3.new(0,0.5,0),delta,Tactics.Solid)
		if hit and (not nearest or hit.Distance<nearest.Distance) then nearest=hit end
	end
	return nearest
end

function Tactics.floorSafe(position,ctx)
	local start=Vector3.new(position.X,ctx.FloorY+ctx.FootHeight+1.8,position.Z)
	local hit=Workspace:Raycast(start,Vector3.new(0,-ctx.FootHeight-1.8-Tactics.MaxDrop,0),Tactics.Solid)
	return hit and hit.Normal.Y>=ctx.SlopeY and hit.Position.Y>=ctx.FloorY-Tactics.MaxDrop and hit.Position.Y<=ctx.FloorY+1.65,hit
end

function Tactics.path(position,delta,ctx)
	local hit=Tactics.sweep(position,delta,ctx)
	local length=delta.Magnitude
	if hit and hit.Distance<length+0.1 then return false end
	if not Tactics.floorSafe(position+delta*0.5,ctx) or not Tactics.floorSafe(position+delta,ctx) then return false end
	local rel=Tactics.flat(ctx.Target-position)
	local dv=Tactics.flat(ctx.Snapshot.Velocity)*ctx.Horizon-delta
	local den=dv:Dot(dv)
	local t=den>0.001 and math.clamp(-rel:Dot(dv)/den,0,1) or 0
	local separation=(rel+dv*t).Magnitude
	if separation<2.5 and separation<rel.Magnitude-0.1 then return false end
	return true
end

function Tactics.exposure(position,ctx)
	local exposed=0
	local canShoot=false
	local openDirections={}
	for i,threat in ipairs(ctx.Threats) do
		local dest=position+Vector3.new(0,1.45,0)
		local hit=Workspace:Raycast(threat.Position,dest-threat.Position,Tactics.Sight)
		if not hit then
			exposed=exposed+(i==1 and 0.5 or 0.8)
			if i==1 then canShoot=true end
			openDirections[#openDirections+1]=Tactics.unit(Tactics.flat(threat.Position-position))
		end
		if i==1 then
			local torso=position+Vector3.new(0,0.15,0)
			if not Workspace:Raycast(threat.Position,torso-threat.Position,Tactics.Sight) then exposed=exposed+0.5 end
		end
	end
	local spread=0
	for i=1,#openDirections do
		for j=i+1,#openDirections do
			spread=math.max(spread,1-openDirections[i]:Dot(openDirections[j]))
		end
	end
	return exposed,canShoot,#openDirections,spread
end

function Tactics.chooseGoal(ctx)
	local now=ctx.Now
	local lateral=Tactics.flat(ctx.Snapshot.Velocity):Dot(ctx.Tangent)
	local reversed=math.abs(lateral)>3 and math.abs(Tactics.LastLateral or 0)>3 and lateral*(Tactics.LastLateral or 0)<0
	local threatened=ctx.Facing>0.6 or ctx.Hurt or #ctx.Threats>1
	if now>=Tactics.NextSwitch or (reversed and now-Tactics.LastSwitch>0.24) then
		if Tactics.Adaptive and math.abs(lateral)>3 then
			Tactics.Side=(lateral>0 and 1 or -1)*(threatened and -1 or 1)
		elseif Tactics.NextSwitch>0 then
			Tactics.Side=-Tactics.Side
		end
		Tactics.Rhythm=(Tactics.Rhythm or 0)+1
		local span=Tactics.Rhythm%3==0 and (0.65+math.random()*0.35) or (0.28+math.random()*0.24)
		Tactics.NextSwitch=now+span
		Tactics.LastSwitch=now
	end
	Tactics.LastLateral=lateral
	local tangent=ctx.Tangent*Tactics.Side
	local radial=math.clamp((ctx.Distance-ctx.Ideal)*0.065,-0.7,0.45)
	local mode=threatened and "엇박자 역무빙" or "방향 맞추기"
	local goal=tangent+ctx.To*radial
	if ctx.Close and Tactics.Flank then
		local look=ctx.Snapshot.Look
		if Tactics.Sense and ctx.Age<0.15 then
			local angle=math.clamp((ctx.Snapshot.TurnRate or 0)*0.12,-0.5,0.5)
			look=Vector3.new(look.X*math.cos(angle)+look.Z*math.sin(angle),0,-look.X*math.sin(angle)+look.Z*math.cos(angle))
		end
		local behind=ctx.Target-look*4.3+tangent*2.8
		goal=Tactics.unit(Tactics.flat(behind-ctx.Position))*0.8+tangent*0.65
		if ctx.Distance<3.4 then goal=goal-ctx.To*1.2 end
		mode="측면·뒤잡기"
	end
	if ctx.Defensive then
		goal=tangent*0.72-ctx.To*0.95
		mode=Tactics.LocalReload and "재장전 엄폐" or "피격 이탈"
	elseif Tactics.Adaptive and ctx.Hurt then
		goal=tangent-ctx.To*0.42
		mode="피격각 바꾸기"
	elseif Tactics.Adaptive and ctx.Age<0.15 and (ctx.Snapshot.Health<0.25 or ctx.Snapshot.Reload) and ctx.Health>0.55 and #ctx.Threats==1 and ctx.Distance>12 then
		goal=tangent*0.8+ctx.To*0.42
		mode="빈틈 압박"
	end
	if Tactics.Sense and not ctx.Defensive then
		if ctx.Age>0.18 then
			goal=tangent-ctx.To*0.12
			mode="모서리 확인"
		elseif #ctx.Threats>1 then
			goal=tangent-ctx.To*0.38
			mode="교차사격 끊기"
		elseif ctx.Landing and ctx.Distance>6 then
			goal=tangent+ctx.To*math.clamp((ctx.Distance-ctx.Ideal)*0.025,-0.15,0.15)
			mode="착지 타이밍 압박"
		elseif ctx.Now-(ctx.Snapshot.ReversedAt or -100)<0.20 and math.abs(lateral)>3 then
			goal=ctx.Tangent*(lateral>0 and -1 or 1)+ctx.To*radial
			mode="방향 전환 끊기"
		end
	end
	if Tactics.StuckFor>0.40 then
		goal=-ctx.To*0.8+tangent
		mode="막힘 탈출"
	end
	return Tactics.unit(goal,tangent),mode
end

function Tactics.samples(ctx,goal)
	local candidates={}
	local directions={goal}
	for _,dir in ipairs(Tactics.Directions) do directions[#directions+1]=dir end
	if Tactics.Output.Magnitude>0.1 then directions[#directions+1]=Tactics.Output.Unit end
	for _,dir in ipairs(directions) do
		local delta=dir*ctx.Travel
		if Tactics.path(ctx.Position,delta,ctx) then
			local pos=ctx.Position+delta
			local exposure,shot,open,spread=Tactics.exposure(pos,ctx)
			candidates[#candidates+1]={Direction=dir,Position=pos,Exposure=exposure,Shot=shot,Open=open,Spread=spread,Scale=1}
		end
	end
	if Tactics.Sense then
		for _,dir in ipairs({goal,ctx.Tangent,-ctx.Tangent}) do
			local delta=dir*ctx.Travel*0.48
			if Tactics.path(ctx.Position,delta,ctx) then
				local pos=ctx.Position+delta
				local exposure,shot,open,spread=Tactics.exposure(pos,ctx)
				candidates[#candidates+1]={Direction=dir,Position=pos,Exposure=exposure,Shot=shot,Open=open,Spread=spread,Scale=0.48}
			end
		end
	end
	return candidates
end

function Tactics.coverGoal(ctx,candidates,currentExposure,currentShot)
	if not Tactics.Cover or ctx.Close then
		Tactics.CoverHome=nil
		Tactics.CoverPhase=nil
		Tactics.PeekGoal=nil
		return nil
	end
	local now=ctx.Now
	if Tactics.CoverHome and (Tactics.flat(Tactics.CoverHome-ctx.Position).Magnitude>10 or now-(Tactics.CoverStarted or now)>5) then
		Tactics.CoverHome=nil
		Tactics.CoverPhase=nil
	end
	if Tactics.CoverPhase=="OUT" then
		if Tactics.LocalReload or (Tactics.HitAt or -100)>Tactics.PeekStarted or Tactics.PeekShots>=(Tactics.PeekBudget or 2) or now-Tactics.PeekStarted>(Tactics.PeekLimit or 0.60) then
			Tactics.CoverPhase="RETURN"
			Tactics.NextPeek=now+(ctx.Defensive and 0.85 or 0.30)+math.random()*0.20
			Tactics.LastPeek={Position=Tactics.PeekGoal,Time=now}
		end
	end
	if Tactics.CoverPhase=="RETURN" then
		if Tactics.flat(Tactics.CoverHome-ctx.Position).Magnitude<0.85 then
			Tactics.CoverPhase="HOLD"
		else
			return Tactics.CoverHome,"엄폐 복귀"
		end
	end
	if Tactics.CoverPhase=="OUT" then
		if currentShot and Tactics.flat(Tactics.PeekGoal-ctx.Position).Magnitude<0.7 then
			return ctx.Position,"짧게 쏘기"
		end
		return Tactics.PeekGoal,"짧은 피킹"
	end
	if not currentShot and currentExposure<0.2 then
		local best=nil
		local score=-math.huge
		for _,v in ipairs(candidates) do
			if v.Shot then
				local rank=-v.Exposure+(v.Direction:Dot(ctx.Tangent)*(Tactics.PeekSide or Tactics.Side))*0.22
				if Tactics.Sense then
					rank=rank-Tactics.peekPenalty(v.Position,now)-Tactics.crossfire(v)
					local distance=Tactics.flat(v.Position-ctx.Position).Magnitude
					rank=rank-distance*0.035
				end
				if rank>score then score=rank best=v end
			end
		end
		if best then
			if not Tactics.CoverHome then
				Tactics.CoverHome=ctx.Position
				Tactics.CoverStarted=now
				Tactics.CoverPhase="HOLD"
				Tactics.NextPeek=now+0.20
			end
			if now<(Tactics.NextPeek or 0) or Tactics.LocalReload or ctx.Age>0.85 then
				return ctx.Position,"엄폐 대기"
			end
			Tactics.PeekGoal=best.Position
			Tactics.CoverPhase="OUT"
			Tactics.PeekStarted=now
			Tactics.PeekShots=0
			Tactics.PeekBudget=Tactics.Sense and (ctx.Facing>0.85 or ctx.Hurt or (best.Open or 1)>1) and 1 or 2
			Tactics.PeekLimit=Tactics.Sense and math.clamp(Tactics.flat(best.Position-ctx.Position).Magnitude/math.max(1,ctx.Speed)+Config.FIRE_DELAY*Tactics.PeekBudget+0.12,0.30,0.85) or 0.60
			Tactics.PeekSide=-(best.Direction:Dot(ctx.Tangent)>=0 and 1 or -1)
			return best.Position,"짧은 피킹"
		end
		if Tactics.CoverPhase=="HOLD" then return ctx.Position,"엄폐 대기" end
	elseif Tactics.CoverPhase=="HOLD" then
		Tactics.CoverHome=nil
		Tactics.CoverPhase=nil
	end
	return nil
end

function Tactics.tryJump(ctx,goal)
	if Tactics.Sense and (ctx.Landing or #ctx.Threats>1 or Tactics.danger(ctx.Position,ctx.Now)>0.7) then return false end
	if not Tactics.Jumps or not ctx.Close or not ctx.Grounded or ctx.Defensive or ctx.Hurt or ctx.Age>0.15 or ctx.Distance>Config.SCRAMBLE_JUMP_DISTANCE or ctx.Facing<0.35 or ctx.Snapshot.Air or ctx.Now<Tactics.NextJump then return false end
	local h=ctx.Humanoid
	if not h:GetStateEnabled(Enum.HumanoidStateType.Jumping) then return false end
	local gravity=math.max(1,Workspace.Gravity)
	local speed=h.UseJumpPower and h.JumpPower or math.sqrt(2*gravity*h.JumpHeight)
	local flight=2*speed/gravity
	if flight<0.25 or flight>1.2 or ctx.Speed<1 then return false end
	local landing=ctx.Target+Tactics.flat(ctx.Snapshot.Velocity)*flight*0.4+ctx.To*2.8+ctx.Tangent*Tactics.Side*2.8
	local delta=Tactics.flat(landing-ctx.Position)
	if delta.Magnitude>ctx.Speed*flight*0.95 or delta.Magnitude<3 then return false end
	local safe,floor=Tactics.floorSafe(landing,ctx)
	if not safe or math.abs(floor.Position.Y-ctx.FloorY)>1.1 then return false end
	if Tactics.flat(landing-ctx.Target-Tactics.flat(ctx.Snapshot.Velocity)*flight).Magnitude<2.8 then return false end
	local previous=ctx.Position
	for i=1,4 do
		local t=flight*i/4
		local p=ctx.Position+delta*(i/4)+Vector3.new(0,speed*t-0.5*gravity*t*t,0)
		if Tactics.sweep(previous,p-previous,ctx) then return false end
		previous=p
	end
	local apex=speed*speed/(2*gravity)
	if Workspace:Raycast(ctx.Position+Vector3.new(0,1.7,0),Vector3.new(0,apex+0.6,0),Tactics.Solid) then return false end
	Tactics.JumpGoal=landing
	Tactics.JumpUntil=ctx.Now+flight+0.2
	Tactics.JumpStarted=ctx.Now
	Tactics.NextJump=ctx.Now+1.1+math.random()*0.6
	h.Jump=true
	return true
end

function Tactics.crossfire(candidate)
	if not Tactics.Sense then return 0 end
	return math.max(0,(candidate.Open or 0)-1)*1.35+(candidate.Spread or 0)*0.75
end

function Tactics.rank(candidate,ctx,goal)
	local distance=Tactics.flat(ctx.Target-candidate.Position).Magnitude
	local rank=candidate.Direction:Dot(goal)*2.5
	rank=rank-(1-(candidate.Scale or 1))*0.45
	rank=rank-math.abs(distance-ctx.Ideal)*(ctx.Defensive and 0.005 or 0.025)
	if Tactics.Cover then
		rank=rank-candidate.Exposure*(ctx.Defensive and 4.8 or ctx.Hurt and 2.4 or 0.85)
		if candidate.Shot and not ctx.Defensive then rank=rank+0.7 end
	end
	if Tactics.Sense then
		rank=rank-Tactics.crossfire(candidate)-Tactics.danger(candidate.Position,ctx.Now)*2.2
		if ctx.Age>0.18 and candidate.Direction:Dot(ctx.To)>0.25 then rank=rank-2 end
		if ctx.Hurt and (candidate.Scale or 1)<0.9 then rank=rank-0.25 end
	end
	if ctx.Defensive then rank=rank+math.clamp(distance-ctx.Distance,-6,6)*0.2 end
	if Tactics.Output.Magnitude>0.01 then rank=rank+candidate.Direction:Dot(Tactics.Output.Unit)*0.25 end
	return rank
end

function Tactics.exitCount(candidate,ctx)
	local dir=candidate.Direction
	local side=Vector3.new(-dir.Z,0,dir.X)
	local count=0
	for _,heading in ipairs({dir,side,-side}) do
		local delta=heading*math.min(2.2,ctx.Travel)
		if Tactics.path(candidate.Position,delta,ctx) then count=count+1 end
	end
	return count
end

function Tactics.plan(ctx)
	if Tactics.LastPosition then
		local moved=Tactics.flat(ctx.Position-Tactics.LastPosition).Magnitude
		if Tactics.Output.Magnitude>0.5 and moved<ctx.Speed*0.018 and ctx.Grounded then
			Tactics.StuckFor=Tactics.StuckFor+Tactics.Interval
		else Tactics.StuckFor=math.max(0,Tactics.StuckFor-Tactics.Interval*2) end
	end
	Tactics.LastPosition=ctx.Position
	local goal,mode=Tactics.chooseGoal(ctx)
	if Tactics.JumpGoal then
		if ctx.Now>Tactics.JumpUntil or (ctx.Grounded and ctx.Now-Tactics.JumpStarted>0.20) then
			Tactics.JumpGoal=nil
			Tactics.NextSwitch=ctx.Now+0.18
		else
			local dir=Tactics.unit(Tactics.flat(Tactics.JumpGoal-ctx.Position))
			if not Tactics.sweep(ctx.Position,dir*math.min(2,ctx.Travel),ctx) then return dir,"점프 후 측면 착지" end
			Tactics.JumpGoal=nil
		end
	end
	local exposure,shot=Tactics.exposure(ctx.Position,ctx)
	local candidates=Tactics.samples(ctx,goal)
	local destination,coverMode=Tactics.coverGoal(ctx,candidates,exposure,shot)
	if destination then
		local delta=Tactics.flat(destination-ctx.Position)
		if delta.Magnitude<0.55 then return Vector3.zero,coverMode end
		local stride=delta.Unit*math.min(ctx.Travel,delta.Magnitude)
		if Tactics.path(ctx.Position,stride,ctx) then
			return delta.Unit*math.clamp(delta.Magnitude/math.max(ctx.Travel,0.1),0.28,1),coverMode
		end
		Tactics.CoverHome=nil
		Tactics.CoverPhase=nil
		Tactics.PeekGoal=nil
	end
	if Tactics.tryJump(ctx,goal) then return Tactics.unit(Tactics.flat(Tactics.JumpGoal-ctx.Position)),"선택 점프" end
	for _,v in ipairs(candidates) do
		v.Score=Tactics.rank(v,ctx,goal)
	end
	table.sort(candidates,function(a,b) return a.Score>b.Score end)
	local best=nil
	local bestScore=-math.huge
	for i=1,math.min(Tactics.Sense and 3 or 1,#candidates) do
		local v=candidates[i]
		local exits=Tactics.Sense and Tactics.exitCount(v,ctx) or 3
		local rank=v.Score-(exits==0 and 2.0 or exits==1 and 0.65 or 0)
		if rank>bestScore then best=v bestScore=rank end
	end
	if not best then return Vector3.zero,"벽·낭떠러지 정지" end
	Tactics.Reason=string.format("노출 %.1f | 위협 %d",best.Exposure,#ctx.Threats)
	return best.Direction*(best.Scale or 1),mode
end

function Tactics.update(dt,d)
	local c=LP.Character
	local h=c and c:FindFirstChildOfClass("Humanoid")
	local root=c and c:FindFirstChild("HumanoidRootPart")
	if not Tactics.Enabled or not (Config.AUTO_FIRE or Config.HOLD_FIRE) or not h or h.Health<=0 or not root or h.Sit or h.PlatformStand or root.Anchored then
		Tactics.reset(true)
		return false
	end
	if Tactics.Humanoid~=h then
		Tactics.reset(true)
		Tactics.Humanoid=h
		Tactics.Health=h.Health
		Tactics.HitAt=-100
		Tactics.DangerSpots={}
		Tactics.BadPeek=nil
	end
	if Tactics.manualInput() then
		Tactics.reset(false)
		Tactics.Mode="수동 이동 우선"
		MovementFSM.State=Tactics.Mode
		return false
	end
	local now=os.clock()
	if h.Health<(Tactics.Health or h.Health)-0.01 then
		Tactics.HitAt=now
		Tactics.DamageFraction=((Tactics.Health or h.Health)-h.Health)/math.max(1,h.MaxHealth)
		Tactics.rememberHit(root.Position,now,Tactics.DamageFraction)
		if now-Tactics.LastSwitch>0.22 then Tactics.Side=-Tactics.Side Tactics.NextSwitch=now+0.38 Tactics.LastSwitch=now end
	end
	Tactics.Health=h.Health
	Tactics.LocalReload=Tactics.reloading(c)
	local s=Tactics.observe(d,root,now,dt)
	if not s or not alive(s.Player) or not eligible(s.Player) or s.Player.Character~=s.Character or now-s.LastSeen>1.2 then
		Tactics.reset(true)
		return false
	end
	local distance=Tactics.flat(s.Position-root.Position).Magnitude
	if distance>math.min(Config.MAX_DISTANCE,Config.COUNTER_STRAFE_DISTANCE) or (not Config.COUNTER_STRAFE and not (Config.CIRCLE_STRAFE and distance<=Config.CIRCLE_STRAFE_MAX_DISTANCE)) then
		Tactics.reset(true)
		return false
	end
	Tactics.Accum=Tactics.Accum+math.min(dt,0.2)
	if Tactics.Accum>=math.max(Tactics.Interval,dt*1.5) or not Tactics.OwnsMove then
		Tactics.Accum=0
		local ctx=Tactics.context(h,root,s,now)
		Tactics.Output,Tactics.Mode=Tactics.plan(ctx)
		Tactics.LastContext=ctx
	end
	local move=Tactics.Output
	if move.Magnitude>0.01 and Tactics.LastContext then
		local stride=move*Tactics.LastContext.Speed*math.clamp(dt*2,0.035,0.12)
		if Tactics.sweep(root.Position,stride,Tactics.LastContext) then move=Vector3.zero Tactics.Accum=Tactics.Interval end
	end
	h:Move(move,false)
	Tactics.OwnsMove=true
	Tactics.MovingHumanoid=h
	MovementFSM.State=Tactics.Mode
	return true
end

function Tactics.allowFire()
	if not Tactics.Enabled then return true end
	return not Tactics.LocalReload and Tactics.CoverPhase~="RETURN" and Tactics.CoverPhase~="HOLD"
end

function Tactics.recordShot()
	if Tactics.Enabled and Tactics.CoverPhase=="OUT" then Tactics.PeekShots=Tactics.PeekShots+1 end
end

function Tactics.lead(player)
	local s=Tactics.Snapshot
	if not Tactics.Enabled or not s or s.Player~=player or os.clock()-s.LastSeen>0.15 then return nil end
	local v=Tactics.AimVelocity
	if Tactics.Sense and os.clock()-(s.ReversedAt or -100)<0.16 then v=s.Velocity end
	if not s.Air then v=Vector3.new(v.X,0,v.Z) end
	if Tactics.Sense and Tactics.LastContext and Tactics.LastContext.Landing then v=Vector3.new(v.X,v.Y*0.2,v.Z) end
	local a=viewport(s.AimPosition)
	local b=viewport(s.AimPosition+v*Config.LEAD_TIME)
	if not a or not b then return Vector2.zero end
	local offset=b-a
	if offset.Magnitude>Config.MAX_LEAD_PX then offset=offset.Unit*Config.MAX_LEAD_PX end
	return offset
end

function Tactics.status()
	if not Tactics.Enabled then return "고급 교전: OFF" end
	return "고급: "..Tactics.Mode.." | "..Tactics.Reason
end

do
	Tactics.Solid=RaycastParams.new()
	Tactics.Solid.FilterType=Enum.RaycastFilterType.Exclude
	Tactics.Solid.IgnoreWater=true
	Tactics.Solid.RespectCanCollide=true
	Tactics.Sight=RaycastParams.new()
	Tactics.Sight.FilterType=Enum.RaycastFilterType.Exclude
	Tactics.Sight.IgnoreWater=true
	Tactics.Sight.RespectCanCollide=true
	Tactics.Directions={}
	for i=0,11 do
		local angle=i*math.pi/6
		Tactics.Directions[#Tactics.Directions+1]=Vector3.new(math.cos(angle),0,math.sin(angle))
	end
	Tactics.reset(false)
	task.spawn(function()
		local scripts=LP:WaitForChild("PlayerScripts",5)
		local module=scripts and scripts:WaitForChild("PlayerModule",5)
		if module and not Tactics.Closed then
			local ok,controls=pcall(function() return require(module):GetControls() end)
			if ok then Tactics.Controls=controls end
		end
	end)
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
	for n in pairs(Whitelist) do w=w..n.."\n" wc=wc+1 end
	for n in pairs(Blacklist) do b=b..n.."\n" bc=bc+1 end
	if wc==0 then w=w.."없음\n" end
	if bc==0 then b=b.."없음\n" end
	ListText.Text=w.."\n"..b
end
refreshList()

Tactics.connect(WhiteBtn.MouseButton1Click,function()
	local p=playerFromText(NameBox.Text)
	if not p then return end
	Whitelist[p.Name]=true
	Blacklist[p.Name]=nil
	Memories[p]=nil
	if ManualPlayer==p then clearManual() end
	NameBox.Text=""
	refreshList()
end)

Tactics.connect(BlackBtn.MouseButton1Click,function()
	local p=playerFromText(NameBox.Text)
	if not p then return end
	Blacklist[p.Name]=true
	Whitelist[p.Name]=nil
	NameBox.Text=""
	refreshList()
end)

Tactics.connect(RemoveBtn.MouseButton1Click,function()
	local p=playerFromText(NameBox.Text)
	if not p then return end
	Whitelist[p.Name]=nil
	Blacklist[p.Name]=nil
	NameBox.Text=""
	refreshList()
end)

Tactics.connect(AutoBtn.MouseButton1Click,function()
	Config.AUTO_FIRE=not Config.AUTO_FIRE
	AutoBtn.Text=Config.AUTO_FIRE and "자동사격: ON" or "자동사격: OFF"
end)

Tactics.connect(TeamBtn.MouseButton1Click,function()
	Config.TEAM_CHECK=not Config.TEAM_CHECK
	TeamBtn.Text=Config.TEAM_CHECK and "팀: ON" or "팀: OFF"
end)

Tactics.connect(WallBtn.MouseButton1Click,function()
	Config.WALL_CHECK=not Config.WALL_CHECK
	WallBtn.Text=Config.WALL_CHECK and "월: ON" or "월: OFF"
end)

Tactics.connect(DragBtn.MouseButton1Click,function()
	Config.DRAG_MODE=not Config.DRAG_MODE
	if Config.DRAG_MODE then Config.HOLD_FIRE=false end
	DragBtn.Text=Config.DRAG_MODE and "드래그: ON" or "드래그: OFF"
end)

Tactics.connect(PullBtn.MouseButton1Click,function()
	Config.PULL_AIM=not Config.PULL_AIM
	PullBtn.Text=Config.PULL_AIM and "끌어치기: ON" or "끌어치기: OFF"
	Center.Visible=Config.PULL_AIM
	resetMotion()
end)

Tactics.connect(ShoulderBtn.MouseButton1Click,function()
	Config.AUTO_SHOULDER=not Config.AUTO_SHOULDER
	ShoulderBtn.Text=Config.AUTO_SHOULDER and "숄더: ON" or "숄더: OFF"
	if not Config.AUTO_SHOULDER then
		ShoulderState.Side=Config.SHOULDER_DEFAULT_SIDE
	end
end)

Tactics.connect(CounterBtn.MouseButton1Click,function()
	Config.COUNTER_STRAFE=not Config.COUNTER_STRAFE
	CounterBtn.Text=Config.COUNTER_STRAFE and "반대 스트레이프: ON" or "반대 스트레이프: OFF"
	if not Config.COUNTER_STRAFE then
		CounterStrafeState.Strength=0
		CounterStrafeState.Direction=0
	end
	updateMovementRangeVisual()
end)

Tactics.connect(CircleBtn.MouseButton1Click,function()
	Config.CIRCLE_STRAFE=not Config.CIRCLE_STRAFE
	CircleBtn.Text=Config.CIRCLE_STRAFE and "원형: ON" or "원형: OFF"
	if not Config.CIRCLE_STRAFE then
		CircleStrafeState.Strength=0
		CircleStrafeState.Player=nil
		CircleStrafeState.NextSwitch=0
	end
	updateMovementRangeVisual()
end)

Tactics.connect(RangeBtn.MouseButton1Click,function()
	Config.MOVEMENT_RANGE_VISIBLE=not Config.MOVEMENT_RANGE_VISIBLE
	RangeBtn.Text=Config.MOVEMENT_RANGE_VISIBLE and "무빙 범위: ON" or "무빙 범위: OFF"
	updateMovementRangeVisual()
end)

Tactics.connect(LockBtn.MouseButton1Click,function()
	if Config.DRAG_MODE then return end
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

Tactics.connect(DelayBox.FocusLost,function()
	Config.FIRE_DELAY=math.max(0.01,tonumber(DelayBox.Text) or Config.FIRE_DELAY)
	DelayBox.Text=tostring(Config.FIRE_DELAY)
end)

Tactics.connect(DistanceBox.FocusLost,function()
	Config.MAX_DISTANCE=math.max(1,tonumber(DistanceBox.Text) or Config.MAX_DISTANCE)
	DistanceBox.Text=tostring(Config.MAX_DISTANCE)
end)

Tactics.connect(SpreadBox.FocusLost,function()
	Config.SPREAD_MULTIPLIER=math.clamp(tonumber(SpreadBox.Text) or Config.SPREAD_MULTIPLIER,0,3)
	SpreadBox.Text=tostring(Config.SPREAD_MULTIPLIER)
end)

Tactics.connect(FireBtn.InputBegan,function(i)
	if Config.DRAG_MODE then return end
	if i.UserInputType==Enum.UserInputType.Touch or i.UserInputType==Enum.UserInputType.MouseButton1 then
		Config.HOLD_FIRE=true
	end
end)

Tactics.connect(FireBtn.InputEnded,function(i)
	if i.UserInputType==Enum.UserInputType.Touch or i.UserInputType==Enum.UserInputType.MouseButton1 then
		Config.HOLD_FIRE=false
	end
end)

do
    RangeBtn.Size=UDim2.new(0.5,-15,0,30)
    Tactics.MenuBtn=button(Main,"교전 기술",UDim2.new(0.5,5,0,195),UDim2.new(0.5,-15,0,30))
    local panel=Instance.new("ScrollingFrame")
    panel.Name="CombatSettings"
    panel.Size=UDim2.fromOffset(272,398)
    panel.Position=UDim2.fromOffset(20,20)
    panel.CanvasSize=UDim2.fromOffset(0,398)
    panel.ScrollBarThickness=4
    panel.ScrollingDirection=Enum.ScrollingDirection.Y
    panel.BackgroundColor3=Color3.fromRGB(25,25,32)
    panel.BorderSizePixel=0
    panel.Visible=false
    panel.Active=true
    panel.ZIndex=20
    panel.Parent=Gui
    corner(panel,12)
    local title=Instance.new("TextLabel")
    title.Size=UDim2.new(1,-48,0,34)
    title.Position=UDim2.fromOffset(12,2)
    title.BackgroundTransparency=1
    title.Text="V29 교전 기술"
    title.Font=Enum.Font.GothamBold
    title.TextSize=15
    title.TextColor3=Color3.new(1,1,1)
    title.Active=true
    title.Parent=panel
    draggable(panel,title)
    local close=button(panel,"X",UDim2.new(1,-36,0,4),UDim2.fromOffset(28,28))
    Tactics.connect(close.Activated,function() panel.Visible=false end)
    Tactics.connect(Tactics.MenuBtn.Activated,function() panel.Visible=not panel.Visible end)
    Tactics.ReverseButton=ReverseBtn
    Tactics.connect(ReverseBtn.Activated,function()
        if Config.DRAG_MODE then return end
        Tactics.setReverse(not Tactics.Reverse)
    end)
    local entries={
        {"Enabled","고급 교전"},{"Sense","교전 센스"},{"Adaptive","상대 움직임 대응"},{"Cover","엄폐·짧은 피킹"},
        {"Disengage","피격 시 이탈"},{"Flank","근접 측면·뒤잡기"},{"Jumps","착지 확인 점프"},{"ManualPriority","수동 이동 우선"},
        {"Reverse","리버스 시프트락"}
    }
    for i,entry in ipairs(entries) do
        local key,label=entry[1],entry[2]
        local b=button(panel,label..(Tactics[key] and ": ON" or ": OFF"),UDim2.fromOffset(10,40+(i-1)*34),UDim2.new(1,-20,0,29))
        if key=="Reverse" then Tactics.ReverseMenuButton=b end
        Tactics.connect(b.Activated,function()
            if key=="Reverse" then
                Tactics.setReverse(not Tactics.Reverse)
            else
                Tactics[key]=not Tactics[key]
                b.Text=label..(Tactics[key] and ": ON" or ": OFF")
                b.BackgroundColor3=Tactics[key] and Color3.fromRGB(48,88,75) or Color3.fromRGB(65,55,55)
            end
            Tactics.reset(true)
        end)
        b.BackgroundColor3=Tactics[key] and Color3.fromRGB(48,88,75) or Color3.fromRGB(65,55,55)
    end
    Tactics.refreshReverseButtons()
    local hint=Instance.new("TextLabel")
    hint.Size=UDim2.new(1,-20,0,44)
    hint.Position=UDim2.fromOffset(10,350)
    hint.BackgroundTransparency=1
    hint.Text="자동사격 또는 FIRE 중 작동\n기본값: 자동 무빙이 수동조작보다 우선"
    hint.TextWrapped=true
    hint.Font=Enum.Font.Gotham
    hint.TextSize=11
    hint.TextColor3=Color3.fromRGB(205,205,210)
    hint.Parent=panel
    Tactics.Panel=panel
end

function Tactics.fitUI()
    if not Camera then return end
    local v=Camera.ViewportSize
    if v.X<100 or v.Y<100 then return end
    Main.Size=UDim2.fromOffset(math.min(280,v.X-20),math.min(494,v.Y-52))
    Tactics.Panel.Size=UDim2.fromOffset(math.min(272,v.X-20),math.min(398,v.Y-52))
    local m=Main.Position
    Main.Position=UDim2.fromOffset(math.clamp(m.X.Scale*v.X+m.X.Offset,4,math.max(4,v.X-Main.Size.X.Offset-4)),math.clamp(m.Y.Scale*v.Y+m.Y.Offset,4,math.max(4,v.Y-Main.Size.Y.Offset-44)))
end

Tactics.fitUI()
Tactics.Viewport=Camera and Camera.ViewportSize

function Tactics.destroy()
    if Tactics.Closed then return end
    Tactics.Closed=true
    Tactics.restoreReverse()
    Tactics.reset(true)
	Config.AUTO_FIRE=false
	Config.HOLD_FIRE=false
	pcall(function() RunService:UnbindFromRenderStep(Config.RENDER_NAME) end)
	resetShoulderState(true)
	clearMovementRangeVisual()
	MovementFSM.State="NONE"
	CounterStrafeState.Strength=0
	CounterStrafeState.Direction=0
	CircleStrafeState.Strength=0
	CircleStrafeState.Player=nil
	CircleStrafeState.NextSwitch=0
	MovementFSM.resetScramble()
	clearTargetHysteresis()
	clearCombatLock()
	clearFireTargetWatch()
	clearPostLossFire()
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
    for _,connection in ipairs(Tactics.Connections) do connection:Disconnect() end
    Tactics.Connections={}
    Gui:Destroy()
end

Tactics.connect(Close.Activated,Tactics.destroy)
Tactics.Cleanup=Instance.new("BindableEvent")
Tactics.Cleanup.Name="Cleanup"
Tactics.Cleanup.Parent=Gui
Tactics.connect(Tactics.Cleanup.Event,Tactics.destroy)
Tactics.connect(Gui.Destroying,Tactics.destroy)

RunService:BindToRenderStep(Config.RENDER_NAME,Enum.RenderPriority.Camera.Value+2,function(dt)
	Camera=Workspace.CurrentCamera
	if not Camera or not Gui.Parent then
        Tactics.release(true)
        return
    end
    if Tactics.Viewport~=Camera.ViewportSize then
        Tactics.Viewport=Camera.ViewportSize
        Tactics.fitUI()
    end

	cleanupMemory()
	refreshCoordinateOffsets()
	updateAutoShoulder(dt)
    Tactics.updateReverse()
	updateMovementRangeVisual()
	updateSeenHighlights(dt)
	updatePinkHighlights(dt)

	if Engagement.State=="KILL_DELAY" and os.clock()>=KillSwitchDelayUntil then
		clearPostLossFire()
		setEngagement("SEARCH",nil,nil)
	end

	local center=Camera.ViewportSize*0.5
	local centerFull=viewportToFull(center)
	Center.Position=UDim2.fromOffset(centerFull.X,centerFull.Y)
	Center.Visible=Config.PULL_AIM

	if not (Config.AUTO_FIRE or Config.HOLD_FIRE) and CombatLockPlayer then
		clearCombatLock()
	elseif not (Config.AUTO_FIRE or Config.HOLD_FIRE) and Engagement.State~="KILL_DELAY" then
		setEngagement("SEARCH",nil,nil)
	end

	local org=origin()
	if not org or not alive(LP) then
        Tactics.reset(true)
        Highlight.Enabled=false
		Aim.Visible=false
		MovementFSM.releaseCircleStrafe(dt)
		MovementFSM.resetScramble()
		MovementFSM.State="NONE"
        MovementFSM.resetScramble()
        MovementFSM.releaseCircleStrafe(dt)
        MovementFSM.releaseCounterStrafe(dt)
        resetMotion()
		return
	end

	if postLossActive() then
		local pos=PostLossFire.Position
		local ghostPlayer=PostLossFire.Player
		local ghostCharacter=PostLossFire.Character
		local distance=(pos-org).Magnitude

		CurrentPlayer=ghostPlayer
		CurrentPart=nil
		CurrentDistance=distance
		CurrentWorld=pos
        CurrentMode="POST_LOSS_FIRE"
        if PostLossFire.Reason=="DEAD" then Tactics.reset(true) else Tactics.update(dt,nil) end

		Highlight.Enabled=false
		Highlight.Adornee=nil
        MovementFSM.resetScramble()
        MovementFSM.releaseCircleStrafe(dt)
        MovementFSM.releaseCounterStrafe(dt)
        resetMotion()

		local ghostScreen,ghostOn=screen(pos)
		if ghostScreen and ghostOn then
			local overlayPoint=screenToFull(ghostScreen)
			Aim.Visible=true
			Aim.Position=UDim2.fromOffset(overlayPoint.X,overlayPoint.Y)
		else
			Aim.Visible=false
		end

		if Config.PULL_AIM then
			rotateTo(pos,dt)
		end

		local remain=math.max(0,PostLossFire.Until-os.clock())
		local reason=PostLossFire.Reason=="DEAD" and "사망" or "시야 이탈"
		Status.Text=string.format(
			"마지막 위치 연사 | %s\n남은 시간: %.2fs\n거리: %.1f\n교전: KILL_DELAY",
			reason,
			remain,
            distance
        ).."\n"..Tactics.status()

        if Config.AUTO_FIRE or Config.HOLD_FIRE then
			if os.clock()-lastFire>=Config.FIRE_DELAY then
				local final,ons=screen(pos)
				if final and ons then
					local point
					if Config.PULL_AIM then
						local vp=viewport(pos)
						if vp and (vp-center).Magnitude<=Config.PULL_FIRE_RADIUS then
							point=viewportToVIM(center)
						end
					else
						point=toVIM(final)
					end

					if point and fireAt(point,ghostCharacter,distance) then
						lastFire=os.clock()
					end
				end
			end
		end

		return
	end

	local d=currentTarget(org)
    if not d then
        Tactics.update(dt,nil)
        CurrentPlayer=nil
		CurrentPart=nil
		CurrentWorld=nil
		CurrentMode=nil
		Highlight.Enabled=false
		Aim.Visible=false
		Status.Text="화면 안 타겟 없음\n교전: "..Engagement.State.."\n"..Tactics.status()
		MovementFSM.releaseCounterStrafe(dt)
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

	MovementFSM.updateMovementFSM(dt,d)

	if Config.PULL_AIM then
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
		Config.WALL_CHECK and "ON" or "OFF",
		d.Visible and "YES" or "NO",
		spread(CurrentPlayer.Character,CurrentDistance),
		Config.SPREAD_MULTIPLIER,
		Config.AUTO_SHOULDER and (ShoulderState.Side<0 and "LEFT" or "RIGHT") or "OFF",
		Config.COUNTER_STRAFE and (CounterStrafeState.Direction<0 and "LEFT" or CounterStrafeState.Direction>0 and "RIGHT" or "WAIT") or "OFF",
		Config.CIRCLE_STRAFE and (CircleStrafeState.Side<0 and "LEFT" or "RIGHT") or "OFF",
		Config.PULL_AIM and "ON" or "OFF"
	).."\n"..Tactics.status()

    if not (Config.AUTO_FIRE or Config.HOLD_FIRE) then
        Tactics.reset(true)
        MovementFSM.State="NONE"
		MovementFSM.resetScramble()
		MovementFSM.releaseCircleStrafe(dt)
		MovementFSM.releaseCounterStrafe(dt)
		return
	end
    if not d.Visible then return end
    if not Tactics.allowFire() then return end
    if transparent(CurrentPlayer) then return end
	if os.clock()-lastFire<Config.FIRE_DELAY then return end

	local final,ons=screen(CurrentWorld)
	if not final or not ons then return end

	local point
	if Config.PULL_AIM then
		local vp=viewport(CurrentWorld)
		if not vp or (vp-center).Magnitude>Config.PULL_FIRE_RADIUS then return end
		point=viewportToVIM(center)
	else
		local predicted=final
		if d.Visible then predicted=predicted+lead(CurrentPlayer) end
		point=toVIM(predicted)
	end

    if fireAt(point,CurrentPlayer.Character,CurrentDistance) then
        Tactics.recordShot()
        lastFire=os.clock()
		lockCombatTarget(CurrentPlayer,CurrentWorld)
		watchFiredTarget(CurrentPlayer)
	end
end)
