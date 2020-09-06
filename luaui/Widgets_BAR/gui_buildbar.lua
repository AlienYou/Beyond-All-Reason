-- $Id$

function widget:GetInfo()
	return {
		name = "BuildBar",
		desc = "An extended buildbar to access the BuildOptions of factories\neverywhere on the map without selecting them before",
		author = "jK",
		date = "Jul 11, 2007",
		license = "GNU GPL, v2 or later",
		layer = 0,
		enabled = true  --  loaded by default?
	}
end

local removeWhenSpec = true		-- for debug purpose

local fontFile = "fonts/" .. Spring.GetConfigString("bar_font2", "Exo2-SemiBold.otf")

local vsx, vsy = Spring.GetViewGeometry()

local ui_opacity = tonumber(Spring.GetConfigFloat("ui_opacity", 0.66) or 0.66)
local ui_scale = tonumber(Spring.GetConfigFloat("ui_scale", 1) or 1)
local glossMult = 1 + (2-(ui_opacity*2))

-- saved values
local bar_side = 1     --left:0,top:2,right:1,bottom:3
local bar_horizontal = false --(not saved) if sides==top v bottom -> horizontal:=true  else-> horizontal:=false
local bar_offset = 0     --relative offset side middle (i.e., bar_pos := vsx*0.5+bar_offset)
local bar_align = 1     --aligns icons to bar_pos: center=0; left/top=+1; right/bottom=-1
local bar_openByClick = false --needs a click to open the buildbar or is a hover enough?
local bar_autoclose = true  --autoclose buildbar on mouseleave?

-- list and interface vars
local facs = {}
local unfinished_facs = {}
local menuHovered = false --opened a buildlist by hover? (if true-> close the menu on mouseleave)
local openedMenu = -1
local hoveredFac = -1
local hoveredBOpt = -1
local pressedFac = -1
local pressedBOpt = -1
local waypointFac = -1
local waypointMode = 0   -- 0 = off; 1=lazy; 2=greedy (greedy means: you have to left click once before leaving waypoint mode and you can have units selected)

local dlists = {}

-- factory icon rectangle
local facRect = { -1, -1, -1, -1 }

-- build options rectangle
local boptRect = { -1, -1, -1, -1 }

-- the following vars make it very easy to use the same code to render the menus, whatever side they are
-- cause we simple take topleft_startcorner and add recursivly *_inext to it to access they next icon pos
local fac_inext = { 0, 0 }
local bopt_inext = { 0, 0 }

local myTeamID = 0

local alternativeUnitpics = false
local hasAlternativeUnitpic = {}
local unitBuildPic = {}
local unitName = {}
local unitBuildOptions = {}
for udid, unitDef in pairs(UnitDefs) do
	unitBuildPic[udid] = unitDef.buildpicname
	if VFS.FileExists('unitpics/alternative/' .. string.gsub(unitDef.buildpicname, '(.*/)', '')) then
		hasAlternativeUnitpic[udid] = true
	end
	unitName[udid] = unitDef.name
	if unitDef.isFactory and #unitDef.buildOptions > 0 then
		unitBuildOptions[udid] = unitDef.buildOptions
	end
end

local blured = false

local repeatPic = ":l:LuaUI/Images/repeat.png"

local iconSizeY = 75		-- reset in ViewResize
local iconSizeX = iconSizeY
local repIcoSize = math.floor(iconSizeY * 0.6)   --repeat iconsize
local fontSize = iconSizeY * 0.31
local maxVisibleBuilds = 3

local startTimer = Spring.GetTimer()
local msx = Game.mapX * 512
local msz = Game.mapY * 512

-------------------------------------------------------------------------------
-- Speed Up
-------------------------------------------------------------------------------

local GL_ONE = GL.ONE
local GL_ONE_MINUS_SRC_ALPHA = GL.ONE_MINUS_SRC_ALPHA
local GL_SRC_ALPHA = GL.SRC_ALPHA
local glBlending = gl.Blending

local math_pi = math.pi
local math_tan = math.tan
local math_rad = math.rad
local math_floor = math.floor
local math_max = math.max
local math_min = math.min

local glVertex = gl.Vertex
local glBeginEnd = gl.BeginEnd

local GetUnitDefID = Spring.GetUnitDefID
local GetMouseState = Spring.GetMouseState
local GetUnitHealth = Spring.GetUnitHealth
local GetUnitStates = Spring.GetUnitStates
local DrawUnitCommands = Spring.DrawUnitCommands
local GetSelectedUnits = Spring.GetSelectedUnits
local GetFullBuildQueue = Spring.GetFullBuildQueue
local GetUnitIsBuilding = Spring.GetUnitIsBuilding
local glText = gl.Text
local glRect = gl.Rect
local glShape = gl.Shape
local glColor = gl.Color
local glTexture = gl.Texture
local glTexRect = gl.TexRect
local glLineWidth = gl.LineWidth
local tan = math.tan
local GL_TRIANGLE_FAN = GL.TRIANGLE_FAN

-------------------------------------------------------------------------------
-- SOUNDS
-------------------------------------------------------------------------------

local sound_waypoint = 'LuaUI/Sounds/buildbar_waypoint.wav'
local sound_click = 'LuaUI/Sounds/buildbar_click.wav'
local sound_hover = 'LuaUI/Sounds/buildbar_hover.wav'
local sound_queue_add = 'LuaUI/Sounds/buildbar_add.wav'
local sound_queue_rem = 'LuaUI/Sounds/buildbar_rem.wav'

-------------------------------------------------------------------------------
-- SOME THINGS NEEDED IN DRAWINMINIMAP
-------------------------------------------------------------------------------

local teamColors = {}
local GetTeamColor = Spring.GetTeamColor or function(teamID)
	local color = teamColors[teamID]
	if (color) then
		return unpack(color)
	end
	local _, _, _, _, _, _, r, g, b = Spring.GetTeamInfo(teamID)  ---?
	teamColors[teamID] = { r, g, b }
	return r, g, b
end

local function checkGuishader(force)
	if WG['guishader'] and backgroundRect then
		if force then
			if dlistGuishader then
				dlistGuishader = gl.DeleteList(dlistGuishader)
			end
			if dlistGuishader2 then
				dlistGuishader2 = gl.DeleteList(dlistGuishader2)
			end
		end
		if not dlistGuishader then
			dlistGuishader = gl.CreateList( function()
				RectRound(backgroundRect[1],backgroundRect[2],backgroundRect[3],backgroundRect[4], bgpadding*1.6 * ui_scale)
			end)
		end
		if not dlistGuishader2 then
			dlistGuishader2 = gl.CreateList( function()
				RectRound(backgroundOptionsRect[1],backgroundOptionsRect[2],backgroundOptionsRect[3],backgroundOptionsRect[4], bgpadding*1.6 * ui_scale)
			end)
		end
	elseif dlistGuishader then
		dlistGuishader = gl.DeleteList(dlistGuishader)
		dlistGuishader2 = gl.DeleteList(dlistGuishader2)
	end
end

-------------------------------------------------------------------------------
-- SCREENSIZE FUNCTIONS
-------------------------------------------------------------------------------

function widget:ViewResize()
	vsx, vsy = Spring.GetViewGeometry()

	widgetSpaceMargin = math_floor((0.0045 * (vsy/vsx))*vsx * ui_scale)
	bgpadding = math.ceil(widgetSpaceMargin * 0.66)

	glossMult = 1 + (2-(ui_opacity*2))

	font = WG['fonts'].getFont(fontFile, 1, 0.2, 1.3)

	iconSizeY = math.floor((vsy / 18) * (1 + (ui_scale - 1) / 1.5))
	iconSizeX = iconSizeY
	fontSize = iconSizeY * 0.31
	repIcoSize = math.floor(iconSizeY * 0.4)

	-- Setup New Screen Alignment
	bar_horizontal = (bar_side > 1)
	if bar_side == 0 then
		-- left
		fac_inext = { 0, -iconSizeY }
		bopt_inext = { iconSizeX, 0 }
	elseif bar_side == 2 then
		-- top
		fac_inext = { iconSizeX, 0 }
		bopt_inext = { 0, -iconSizeY }
	elseif bar_side == 1 then
		-- right
		fac_inext = { 0, -iconSizeY }
		bopt_inext = { -iconSizeX, 0 }
	else
		--bar_side==3       -- bottom
		fac_inext = { iconSizeX, 0 }
		bopt_inext = { 0, iconSizeY }
	end

	checkGuishader(true)
end

-------------------------------------------------------------------------------
-- INITIALIZTION FUNCTIONS
-------------------------------------------------------------------------------

function widget:Initialize()
	widget:ViewResize()

	myTeamID = Spring.GetMyTeamID()

	UpdateFactoryList()

	if removeWhenSpec and Spring.GetGameFrame() > 0 and Spring.GetSpectatingState() then
		widgetHandler:RemoveWidget(self)
	end

	WG['buildbar'] = {}
	WG['buildbar'].getAlternativeIcons = function()
		return alternativeUnitpics
	end
	WG['buildbar'].setAlternativeIcons = function(value)
		alternativeUnitpics = value
	end
end

function widget:GameStart()
	if removeWhenSpec and Spring.GetSpectatingState() then
		widgetHandler:RemoveWidget(self)
	end
end

function widget:Shutdown()
	for i = 1, #dlists do
		gl.DeleteList(dlists[i])
	end
	dlists = {}
	if WG['guishader'] then
		WG['guishader'].RemoveDlist('buildbar')
		WG['guishader'].RemoveDlist('buildbar2')
		if dlistGuishader then
			dlistGuishader = gl.DeleteList(dlistGuishader)
		end
		if dlistGuishader2 then
			dlistGuishader2 = gl.DeleteList(dlistGuishader2)
		end
	end
end

function widget:GetConfigData()
	return {
		side = bar_side,
		offset = bar_offset,
		align = bar_align,
		openByClick = bar_openByClick,
		autoclose = bar_autoclose,
		alternativeUnitpics = alternativeUnitpics,
	}
end

function widget:SetConfigData(data)
	bar_side = data.side or 2
	bar_offset = data.offset or 0
	bar_align = data.align or 0
	bar_openByClick = data.openByClick or false
	bar_autoclose = data.autoclose or (not bar_openByClick)

	bar_side = math.min(math.max(bar_side, 0), 3)
	bar_align = math.min(math.max(bar_align, -1), 1)
	if data.alternativeUnitpics ~= nil then
		alternativeUnitpics = data.alternativeUnitpics
	end
end



-------------------------------------------------------------------------------
-- RECTANGLE FUNCTIONS
-------------------------------------------------------------------------------

local function OffsetRect(rect, x_offset, y_offset)
	rect[3], rect[1] = rect[3] + x_offset, rect[1] + x_offset
	rect[2], rect[4] = rect[2] + y_offset, rect[4] + y_offset
end

local function RectWH(left, top, width, height)
	local rect = { left, top }
	rect[3] = rect[1] + width
	rect[4] = rect[2] - height
	return rect
end

local function GetFacIconRect(i)
	local xmin = facRect[1] + i * fac_inext[1]
	local ymax = facRect[2] + i * fac_inext[2]
	return xmin, ymax, xmin + iconSizeX, ymax - iconSizeY
end

local function IsInRect(left, top, rect)
	return left >= rect[1] and left <= rect[3] and top <= rect[2] and top >= rect[4]
end

-------------------------------------------------------------------------------
-- DRAW FUNCTIONS
-------------------------------------------------------------------------------

local function DrawRectRound(px, py, sx, sy, cs, tl, tr, br, bl, c1, c2)
	local csyMult = 1 / ((sy - py) / cs)

	if c2 then
		gl.Color(c1[1], c1[2], c1[3], c1[4])
	end
	gl.Vertex(px + cs, py, 0)
	gl.Vertex(sx - cs, py, 0)
	if c2 then
		gl.Color(c2[1], c2[2], c2[3], c2[4])
	end
	gl.Vertex(sx - cs, sy, 0)
	gl.Vertex(px + cs, sy, 0)

	-- left side
	if c2 then
		gl.Color(c1[1] * (1 - csyMult) + (c2[1] * csyMult), c1[2] * (1 - csyMult) + (c2[2] * csyMult), c1[3] * (1 - csyMult) + (c2[3] * csyMult), c1[4] * (1 - csyMult) + (c2[4] * csyMult))
	end
	gl.Vertex(px, py + cs, 0)
	gl.Vertex(px + cs, py + cs, 0)
	if c2 then
		gl.Color(c2[1] * (1 - csyMult) + (c1[1] * csyMult), c2[2] * (1 - csyMult) + (c1[2] * csyMult), c2[3] * (1 - csyMult) + (c1[3] * csyMult), c2[4] * (1 - csyMult) + (c1[4] * csyMult))
	end
	gl.Vertex(px + cs, sy - cs, 0)
	gl.Vertex(px, sy - cs, 0)

	-- right side
	if c2 then
		gl.Color(c1[1] * (1 - csyMult) + (c2[1] * csyMult), c1[2] * (1 - csyMult) + (c2[2] * csyMult), c1[3] * (1 - csyMult) + (c2[3] * csyMult), c1[4] * (1 - csyMult) + (c2[4] * csyMult))
	end
	gl.Vertex(sx, py + cs, 0)
	gl.Vertex(sx - cs, py + cs, 0)
	if c2 then
		gl.Color(c2[1] * (1 - csyMult) + (c1[1] * csyMult), c2[2] * (1 - csyMult) + (c1[2] * csyMult), c2[3] * (1 - csyMult) + (c1[3] * csyMult), c2[4] * (1 - csyMult) + (c1[4] * csyMult))
	end
	gl.Vertex(sx - cs, sy - cs, 0)
	gl.Vertex(sx, sy - cs, 0)

	-- bottom left
	if c2 then
		gl.Color(c1[1], c1[2], c1[3], c1[4])
	end
	if ((py <= 0 or px <= 0) or (bl ~= nil and bl == 0)) and bl ~= 2 then
		gl.Vertex(px, py, 0)
	else
		gl.Vertex(px + cs, py, 0)
	end
	gl.Vertex(px + cs, py, 0)
	if c2 then
		gl.Color(c1[1] * (1 - csyMult) + (c2[1] * csyMult), c1[2] * (1 - csyMult) + (c2[2] * csyMult), c1[3] * (1 - csyMult) + (c2[3] * csyMult), c1[4] * (1 - csyMult) + (c2[4] * csyMult))
	end
	gl.Vertex(px + cs, py + cs, 0)
	gl.Vertex(px, py + cs, 0)
	-- bottom right
	if c2 then
		gl.Color(c1[1], c1[2], c1[3], c1[4])
	end
	if ((py <= 0 or sx >= vsx) or (br ~= nil and br == 0)) and br ~= 2 then
		gl.Vertex(sx, py, 0)
	else
		gl.Vertex(sx - cs, py, 0)
	end
	gl.Vertex(sx - cs, py, 0)
	if c2 then
		gl.Color(c1[1] * (1 - csyMult) + (c2[1] * csyMult), c1[2] * (1 - csyMult) + (c2[2] * csyMult), c1[3] * (1 - csyMult) + (c2[3] * csyMult), c1[4] * (1 - csyMult) + (c2[4] * csyMult))
	end
	gl.Vertex(sx - cs, py + cs, 0)
	gl.Vertex(sx, py + cs, 0)
	-- top left
	if c2 then
		gl.Color(c2[1], c2[2], c2[3], c2[4])
	end
	if ((sy >= vsy or px <= 0) or (tl ~= nil and tl == 0)) and tl ~= 2 then
		gl.Vertex(px, sy, 0)
	else
		gl.Vertex(px + cs, sy, 0)
	end
	gl.Vertex(px + cs, sy, 0)
	if c2 then
		gl.Color(c2[1] * (1 - csyMult) + (c1[1] * csyMult), c2[2] * (1 - csyMult) + (c1[2] * csyMult), c2[3] * (1 - csyMult) + (c1[3] * csyMult), c2[4] * (1 - csyMult) + (c1[4] * csyMult))
	end
	gl.Vertex(px + cs, sy - cs, 0)
	gl.Vertex(px, sy - cs, 0)
	-- top right
	if c2 then
		gl.Color(c2[1], c2[2], c2[3], c2[4])
	end
	if ((sy >= vsy or sx >= vsx) or (tr ~= nil and tr == 0)) and tr ~= 2 then
		gl.Vertex(sx, sy, 0)
	else
		gl.Vertex(sx - cs, sy, 0)
	end
	gl.Vertex(sx - cs, sy, 0)
	if c2 then
		gl.Color(c2[1] * (1 - csyMult) + (c1[1] * csyMult), c2[2] * (1 - csyMult) + (c1[2] * csyMult), c2[3] * (1 - csyMult) + (c1[3] * csyMult), c2[4] * (1 - csyMult) + (c1[4] * csyMult))
	end
	gl.Vertex(sx - cs, sy - cs, 0)
	gl.Vertex(sx, sy - cs, 0)
end
function RectRound(px, py, sx, sy, cs, tl, tr, br, bl, c1, c2)
	-- (coordinates work differently than the RectRound func in other widgets)
	gl.Texture(false)
	gl.BeginEnd(GL.QUADS, DrawRectRound, px, py, sx, sy, cs, tl, tr, br, bl, c1, c2)
end



-- cs (corner size) is not implemented yet
local function RectRoundProgress(left,bottom,right,top, cs, progress, color)

	local xcen = (left+right) / 2
	local ycen = (top+bottom) / 2

	local alpha = 360 * (progress)
	local alpha_rad = math_rad(alpha)
	local beta_rad  = math_pi/2 - alpha_rad
	local list = {}
	local listCount = 1
	list[listCount] = {v = {xcen, ycen}}
	listCount = listCount + 1
	list[#list+1] = {v = {xcen, top}}

	local x,y
	x = (top-ycen) * math_tan(alpha_rad) + xcen
	if alpha < 90 and x < right then   -- < 25%
		listCount = listCount + 1
		list[listCount] = {v = {x,  top}}
	else
		listCount = listCount + 1
		list[listCount] = {v = {right, top}}
		y = (right-xcen) * math_tan(beta_rad) + ycen
		if alpha < 180 and y > bottom then   -- < 50%
			listCount = listCount + 1
			list[listCount] = {v = {right, y}}
		else
			listCount = listCount + 1
			list[listCount] = {v = {right, bottom}}
			x = (top-ycen) * math_tan(-alpha_rad) + xcen
			if alpha < 270 and x > left then   -- < 75%
				listCount = listCount + 1
				list[listCount] = {v = {x, bottom}}
			else
				listCount = listCount + 1
				list[listCount] = {v = {left, bottom}}
				y = (right-xcen) * math_tan(-beta_rad) + ycen
				if alpha < 350 and y < top then   -- < 97%
					listCount = listCount + 1
					list[listCount] = {v = {left, y}}
				else
					listCount = listCount + 1
					list[listCount] = {v = {left, top}}
					x = (top-ycen) * math_tan(alpha_rad) + xcen
					listCount = listCount + 1
					list[listCount] = {v = {x, top}}
				end
			end
		end
	end

	glColor(color[1],color[2],color[3],color[4])
	glShape(GL_TRIANGLE_FAN, list)
	glColor(1,1,1,1)
end

local function DrawRectRoundCircle(x, y, z, radius, cs, centerOffset, color1, color2)
	if not color2 then color2 = color1 end
	--centerOffset = 0
	local coords = {
		{x-radius+cs, z+radius, y},   -- top left
		{x+radius-cs, z+radius, y},   -- top right
		{x+radius, z+radius-cs, y},   -- right top
		{x+radius, z-radius+cs, y},   -- right bottom
		{x+radius-cs, z-radius, y},   -- bottom right
		{x-radius+cs, z-radius, y},   -- bottom left
		{x-radius, z-radius+cs, y},   -- left bottom
		{x-radius, z+radius-cs, y},   -- left top
	}
	local cs2 = cs * (centerOffset/radius)
	local coords2 = {
		{x-centerOffset+cs2, z+centerOffset, y},   -- top left
		{x+centerOffset-cs2, z+centerOffset, y},   -- top right
		{x+centerOffset, z+centerOffset-cs2, y},   -- right top
		{x+centerOffset, z-centerOffset+cs2, y},   -- right bottom
		{x+centerOffset-cs2, z-centerOffset, y},   -- bottom right
		{x-centerOffset+cs2, z-centerOffset, y},   -- bottom left
		{x-centerOffset, z-centerOffset+cs2, y},   -- left bottom
		{x-centerOffset, z+centerOffset-cs2, y},   -- left top
	}
	for i = 1, 8 do
		local i2 = (i>=8 and 1 or i + 1)
		glColor(color2)
		glVertex(coords[i][1], coords[i][2], coords[i][3])
		glVertex(coords[i2][1], coords[i2][2], coords[i2][3])
		glColor(color1)
		glVertex(coords2[i2][1], coords2[i2][2], coords2[i2][3])
		glVertex(coords2[i][1], coords2[i][2], coords2[i][3])
	end
end
local function RectRoundCircle(x, y, z, radius, cs, centerOffset, color1, color2)
	glBeginEnd(GL.QUADS, DrawRectRoundCircle, x, y, z, radius, cs, centerOffset, color1, color2)
end

local function DrawTexRectRound(px, py, sx, sy, cs, tl, tr, br, bl, offset)
	local csyMult = 1 / ((sy - py) / cs)
	offset = offset or 0

	local function drawTexCoordVertex(x, y)
		local yc = 1 - ((y - py) / (sy - py))
		local xc = (offset * 0.5) + ((x - px) / (sx - px)) + (-offset * ((x - px) / (sx - px)))
		yc = 1 - (offset * 0.5) - ((y - py) / (sy - py)) + (offset * ((y - py) / (sy - py)))
		gl.TexCoord(xc, yc)
		gl.Vertex(x, y, 0)
	end

	-- mid section
	drawTexCoordVertex(px + cs, py)
	drawTexCoordVertex(sx - cs, py)
	drawTexCoordVertex(sx - cs, sy)
	drawTexCoordVertex(px + cs, sy)

	-- left side
	drawTexCoordVertex(px, py + cs)
	drawTexCoordVertex(px + cs, py + cs)
	drawTexCoordVertex(px + cs, sy - cs)
	drawTexCoordVertex(px, sy - cs)

	-- right side
	drawTexCoordVertex(sx, py + cs)
	drawTexCoordVertex(sx - cs, py + cs)
	drawTexCoordVertex(sx - cs, sy - cs)
	drawTexCoordVertex(sx, sy - cs)

	-- bottom left
	if ((py <= 0 or px <= 0) or (bl ~= nil and bl == 0)) and bl ~= 2 then
		drawTexCoordVertex(px, py)
	else
		drawTexCoordVertex(px + cs, py)
	end
	drawTexCoordVertex(px + cs, py)
	drawTexCoordVertex(px + cs, py + cs)
	drawTexCoordVertex(px, py + cs)
	-- bottom right
	if ((py <= 0 or sx >= vsx) or (br ~= nil and br == 0)) and br ~= 2 then
		drawTexCoordVertex(sx, py)
	else
		drawTexCoordVertex(sx - cs, py)
	end
	drawTexCoordVertex(sx - cs, py)
	drawTexCoordVertex(sx - cs, py + cs)
	drawTexCoordVertex(sx, py + cs)
	-- top left
	if ((sy >= vsy or px <= 0) or (tl ~= nil and tl == 0)) and tl ~= 2 then
		drawTexCoordVertex(px, sy)
	else
		drawTexCoordVertex(px + cs, sy)
	end
	drawTexCoordVertex(px + cs, sy)
	drawTexCoordVertex(px + cs, sy - cs)
	drawTexCoordVertex(px, sy - cs)
	-- top right
	if ((sy >= vsy or sx >= vsx) or (tr ~= nil and tr == 0)) and tr ~= 2 then
		drawTexCoordVertex(sx, sy)
	else
		drawTexCoordVertex(sx - cs, sy)
	end
	drawTexCoordVertex(sx - cs, sy)
	drawTexCoordVertex(sx - cs, sy - cs)
	drawTexCoordVertex(sx, sy - cs)
end
function TexRectRound(px, py, sx, sy, cs, tl, tr, br, bl, zoom)
	gl.BeginEnd(GL.QUADS, DrawTexRectRound, px, py, sx, sy, cs, tl, tr, br, bl, zoom)
end

local function DrawTexRect(rect, texture, color)
	if color ~= nil then
		glColor(color)
	else
		glColor(1, 1, 1, 1)
	end
	glTexture(texture)
	glTexRect(rect[1], rect[4], rect[3], rect[2])
	glColor(1, 1, 1, 1)
	glTexture(false)
end

local function DrawBuildProgress(left, top, right, bottom, progress, color)
	glColor(color)
	local xcen = (left + right) / 2
	local ycen = (top + bottom) / 2

	local alpha = 360 * (progress)
	local alpha_rad = math.rad(alpha)
	local beta_rad = math.pi / 2 - alpha_rad
	local list = {}
	local listCount = 1
	list[listCount] = { v = { xcen, ycen } }
	listCount = listCount + 1
	list[#list + 1] = { v = { xcen, top } }

	local x, y
	x = (top - ycen) * tan(alpha_rad) + xcen
	if (alpha < 90) and (x < right) then
		listCount = listCount + 1
		list[listCount] = { v = { x, top } }
	else
		listCount = listCount + 1
		list[listCount] = { v = { right, top } }
		y = (right - xcen) * tan(beta_rad) + ycen
		if (alpha < 180) and (y > bottom) then
			listCount = listCount + 1
			list[listCount] = { v = { right, y } }
		else
			listCount = listCount + 1
			list[listCount] = { v = { right, bottom } }
			x = (top - ycen) * tan(-alpha_rad) + xcen
			if (alpha < 270) and (x > left) then
				listCount = listCount + 1
				list[listCount] = { v = { x, bottom } }
			else
				listCount = listCount + 1
				list[listCount] = { v = { left, bottom } }
				y = (right - xcen) * tan(-beta_rad) + ycen
				if (alpha < 350) and (y < top) then
					listCount = listCount + 1
					list[listCount] = { v = { left, y } }
				else
					listCount = listCount + 1
					list[listCount] = { v = { left, top } }
					x = (top - ycen) * tan(alpha_rad) + xcen
					listCount = listCount + 1
					list[listCount] = { v = { x, top } }
				end
			end
		end
	end

	glShape(GL.TRIANGLE_FAN, list)

	-- adding additive overlay
	glColor(color[1], color[2], color[3], color[4] / 10)
	glBlending(GL_SRC_ALPHA, GL_ONE)
	glShape(GL_TRIANGLE_FAN, list)
	glBlending(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA)

	glColor(1, 1, 1, 1)
end

local function drawIcon(rect, tex, color, zoom)

	glTexture(tex)
	glColor(color[1],color[2],color[3],color[4])
	TexRectRound(rect[1], rect[2], rect[3], rect[4], cornerSize, nil,nil,nil,nil, zoom)
	glTexture(false)

	-- lighten top
	glBlending(GL_SRC_ALPHA, GL_ONE)
	-- glossy half
	RectRound(rect[1], rect[2]+((rect[4]-rect[2])*0.5), rect[3], rect[4], cornerSize, 2,2,0,0,{1,1,1,0}, {1,1,1,0.13})
	glBlending(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA)

	-- extra darken gradually
	RectRound(rect[1], rect[2], rect[3], rect[4], cornerSize, 0,0,2,2,{0,0,0,0.13}, {0,0,0,0})

	local halfSize = (rect[3] - rect[1])*0.5
	glBlending(GL_SRC_ALPHA, GL_ONE)
	RectRoundCircle(
		rect[1]+halfSize,
		0,
		rect[2]+halfSize,
		halfSize, cornerSize*0.6,
		halfSize-math_max(1,math_floor(halfSize*0.08)),
		{1,1,1,0.07}, {1,1,1,0.07}
	)
	glBlending(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA)
end

local function DrawOptionsBackground()
	local addDist = math_floor(widgetSpaceMargin*0.4)
	backgroundOptionsRect = {boptRect[1]-addDist, boptRect[4]-addDist, boptRect[3], boptRect[2]+addDist}

	-- background
	RectRound(backgroundOptionsRect[1],backgroundOptionsRect[2],backgroundOptionsRect[3],backgroundOptionsRect[4], bgpadding*1.6, 1,1,1,1,{0.05,0.05,0.05,ui_opacity}, {0,0,0,ui_opacity})
	RectRound(backgroundOptionsRect[1]+bgpadding, backgroundOptionsRect[2]+bgpadding, backgroundOptionsRect[3]-bgpadding, backgroundOptionsRect[4]-bgpadding, bgpadding*1, 1,1,1,1,{0.3,0.3,0.3,ui_opacity*0.1}, {1,1,1,ui_opacity*0.1})

	-- gloss
	glBlending(GL_SRC_ALPHA, GL_ONE)
	RectRound(backgroundOptionsRect[1]+bgpadding,backgroundOptionsRect[4]-((backgroundOptionsRect[4]-backgroundOptionsRect[2])*0.33),backgroundOptionsRect[3]-bgpadding,backgroundOptionsRect[4]-bgpadding, bgpadding, 1,0,0,1, {1,1,1,0.01*glossMult}, {1,1,1,0.055*glossMult})
	RectRound(backgroundOptionsRect[1]+bgpadding,backgroundOptionsRect[2], backgroundOptionsRect[3]-bgpadding,backgroundOptionsRect[2]+((backgroundOptionsRect[4]-backgroundOptionsRect[2])*0.3), bgpadding, 1,0,0,1, {1,1,1,0.025*glossMult}, {1,1,1,0})
	glBlending(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA)
end

local function DrawBackground()
	local addDist = math_floor(widgetSpaceMargin*0.4)
	backgroundRect = {factoriesArea[1]-addDist, factoriesArea[4]-addDist, factoriesArea[3], factoriesArea[2]+addDist}

	-- background
	RectRound(backgroundRect[1],backgroundRect[2],backgroundRect[3],backgroundRect[4], bgpadding*1.6, 1,1,1,1,{0.05,0.05,0.05,ui_opacity}, {0,0,0,ui_opacity})
	RectRound(backgroundRect[1]+bgpadding, backgroundRect[2]+bgpadding, backgroundRect[3]-bgpadding, backgroundRect[4]-bgpadding, bgpadding, 1,0,0,1,{0.3,0.3,0.3,ui_opacity*0.1}, {1,1,1,ui_opacity*0.1})

	-- gloss
	glBlending(GL_SRC_ALPHA, GL_ONE)
	RectRound(backgroundRect[1]+bgpadding,backgroundRect[4]-((backgroundRect[4]-backgroundRect[2])*0.33),backgroundRect[3]-bgpadding,backgroundRect[4]-bgpadding, bgpadding, 1,0,0,1, {1,1,1,0.01*glossMult}, {1,1,1,0.055*glossMult})
	RectRound(backgroundRect[1]+bgpadding,backgroundRect[2], backgroundRect[3]-bgpadding,backgroundRect[2]+((backgroundRect[4]-backgroundRect[2])*0.3), bgpadding, 1,0,0,1, {1,1,1,0.025*glossMult}, {1,1,1,0})
	glBlending(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA)
end

local function DrawButton(rect, unitDefID, options, isFac)	-- options = {pressed,hovered,selected,repeat,hovered_repeat,waypoint,progress,amount,alpha}
	cornerSize = (rect[3] - rect[1]) * 0.03

	-- hover or pressed?
	local zoom = 0.04
	local hoverPadding = widgetSpaceMargin*0.5
	local iconAlpha = (options.alpha or 1)
	if options.pressed then
		--hoverPadding = math_floor(widgetSpaceMargin*0.6)
		iconAlpha = 1
		zoom = 0.17
	elseif options.hovered then
		--hoverPadding = math_floor(widgetSpaceMargin*0.25)
		iconAlpha = 1
		zoom = 0.12
	end

	-- draw icon
	local imgRect = { rect[1] + (hoverPadding*1), rect[2] - hoverPadding, rect[3] - (hoverPadding*1), rect[4] + hoverPadding }

	local tex
	if alternativeUnitpics and hasAlternativeUnitpic[unitDefID] then
		tex = ':lr128,128:unitpics/alternative/' .. unitBuildPic[unitDefID]
	else
		tex = ':lr128,128:unitpics/' .. unitBuildPic[unitDefID]
	end
	drawIcon({imgRect[1], imgRect[4], imgRect[3], imgRect[2]}, tex, {1, 1, 1, iconAlpha}, zoom)

	-- Progress
	if (options.progress or -1) > -1 then
		glBlending(GL_SRC_ALPHA, GL_ONE)
		RectRoundProgress(imgRect[1], imgRect[4], imgRect[3], imgRect[2], cornerSize, options.progress, { 1, 1, 1, 0.22 })
		glBlending(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA)
	end

	-- loop status?
	if options['repeat'] then
		local color = { 1, 1, 1, 0.8 }
		if options.hovered_repeat then
			color = { 1, 1, 1, 0.65 }
		end
		glTexture(repeatPic)
		glColor(1, 1, 1, 0.65)
		DrawTexRect({imgRect[3]-repIcoSize-4,imgRect[2]-4,imgRect[3]-4,imgRect[2]-repIcoSize-4}, repeatPic, color)
	elseif isFac then
		local color = { 1, 1, 1, 0.35 }
		if options.hovered_repeat then
			color = { 1, 1, 1, 0.5 }
		end
		glTexture(repeatPic)
		glColor(1, 1, 1, 0.5)
		DrawTexRect({imgRect[3]-repIcoSize-4,imgRect[2]-4,imgRect[3]-4,imgRect[2]-repIcoSize-4}, repeatPic, color)
	end

	-- amount
	if (options.amount or 0) > 0 then
		font:Begin()
		font:Print(options.amount, rect[1] + ((rect[3] - rect[1]) * 0.22), rect[4] - ((rect[4] - rect[2]) * 0.22), fontSize, "o")
		font:End()
	end
	glTexture(false)
	glColor(1,1,1,1)
end

local sec = 0
local uiOpacitySec = 0.5
function widget:Update(dt)

	if chobbyInterface then
		return
	end

	uiOpacitySec = uiOpacitySec + dt
	if uiOpacitySec > 0.5 then
		uiOpacitySec = 0
		if ui_scale ~= Spring.GetConfigFloat("ui_scale", 1) then
			ui_scale = Spring.GetConfigFloat("ui_scale", 1)
			widget:ViewResize(Spring.GetViewGeometry())
			widget:Shutdown()
			widget:Initialize()
		end
		uiOpacitySec = 0
		if ui_opacity ~= Spring.GetConfigFloat("ui_opacity", 0.66) then
			ui_opacity = Spring.GetConfigFloat("ui_opacity", 0.66)
		end
	end

	if removeWhenSpec and Spring.GetGameFrame() > 0 and Spring.GetSpectatingState() then
		widgetHandler:RemoveWidget(self)
	end

	if myTeamID ~= Spring.GetMyTeamID() then
		myTeamID = Spring.GetMyTeamID()
		UpdateFactoryList()
	end

	local icon
	local mx, my, lb, mb, rb = GetMouseState()

	sec = sec + dt
	local doupdate = false
	if sec > 0.1 then
		doupdate = true
	end
	if factoriesArea ~= nil then
		if IsInRect(mx, my, { factoriesArea[1], factoriesArea[2], factoriesArea[3], factoriesArea[4] }) then
			doupdate = true
			factoriesAreaHovered = true
		elseif factoriesAreaHovered then
			factoriesAreaHovered = nil
			doupdate = true
		end
	end
	if setInfoDisplayUnitID then
		setInfoDisplayUnitID = nil
		if WG['info'] then
			WG['info'].clearDisplayUnitID()
		end
	end
	if doupdate then
		sec = 0
		SetupDimensions(#facs)
		SetupSubDimensions()
		for i = 1, #dlists do
			gl.DeleteList(dlists[i])
		end
		checkGuishader(true)
		dlists = {}
		local dlistsCount = 1

		factoriesArea = nil

		-- draw factory list
		local fac_rec = RectWH(math_floor(facRect[1]), math_floor(facRect[2]), iconSizeX, iconSizeY)
		for i, facInfo in ipairs(facs) do

			local unitDefID = facInfo.unitDefID
			local options = {}

			local unitBuildDefID = -1
			local unitBuildID = -1

			-- determine options -------------------------------------------------------------------
			-- building?
			unitBuildID = GetUnitIsBuilding(facInfo.unitID)
			if unitBuildID then
				unitBuildDefID = GetUnitDefID(unitBuildID)
				_, _, _, _, options.progress = GetUnitHealth(unitBuildID)
				unitDefID = unitBuildDefID
			elseif (unfinished_facs[facInfo.unitID]) then
				_, _, _, _, options.progress = GetUnitHealth(facInfo.unitID)
				if (options.progress >= 1) then
					options.progress = -1
					unfinished_facs[facInfo.unitID] = nil
				end
			end
			-- repeat mode?
			if select(4, GetUnitStates(facInfo.unitID, false, true)) then
				options['repeat'] = true
			else
				options['repeat'] = false
			end
			-- hover or pressed?
			if (i == hoveredFac + 1) then
				options.hovered_repeat = IsInRect(mx, my, { fac_rec[3] - repIcoSize, fac_rec[2], fac_rec[3], fac_rec[2] - repIcoSize })
				options.pressed = (lb or mb or rb) or (options.hovered_repeat)
				options.hovered = true
			end
			-- border
			options.waypoint = (waypointMode > 1) and (i == waypointFac + 1)
			options.selected = (i == openedMenu + 1)

			dlistsCount = dlistsCount + 1
			dlists[dlistsCount] = gl.CreateList(DrawButton, fac_rec, unitDefID, options, true)
			if factoriesArea == nil then
				factoriesArea = { fac_rec[1], fac_rec[2], fac_rec[3], fac_rec[4] }
			else
				factoriesArea[4] = fac_rec[4]
			end

			-- setup next icon pos
			OffsetRect(fac_rec, fac_inext[1], fac_inext[2])
		end
		if factoriesArea then
			dlists[1] = gl.CreateList(DrawBackground)
			dlists[dlistsCount+1] = gl.CreateList(DrawOptionsBackground)
		end
	end
end

-------------------------------------------------------------------------------
-- DRAWSCREEN
-------------------------------------------------------------------------------

function widget:RecvLuaMsg(msg, playerID)
	if msg:sub(1, 18) == 'LobbyOverlayActive' then
		chobbyInterface = (msg:sub(1, 19) == 'LobbyOverlayActive1')
	end
end

function widget:DrawScreen()
	local t0 = Spring.GetTimer()
	if chobbyInterface then
		return
	end

	local icon
	local mx, my, lb, mb, rb = GetMouseState()


	if #dlists == 0 then
		if dlistGuishader and WG['guishader'] then
			WG['guishader'].RemoveDlist('buildbar')
			WG['guishader'].RemoveDlist('buildbar2')
		end
	elseif WG['guishader'] then
		if dlistGuishader then
			WG['guishader'].InsertDlist(dlistGuishader, 'buildbar')
		end
		if dlistGuishader2 then
			WG['guishader'].InsertDlist(dlistGuishader2, 'buildbar2')
		end
	end

	for i = 1, #dlists do
		gl.CallList(dlists[i])
	end

	-- draw factory list
	if (factoriesArea ~= nil and IsInRect(mx, my, { factoriesArea[1], factoriesArea[2], factoriesArea[3], factoriesArea[4] })) or
		(buildoptionsArea ~= nil and IsInRect(mx, my, { buildoptionsArea[1], buildoptionsArea[2], buildoptionsArea[3], buildoptionsArea[4] })) then
		local fac_rec = RectWH(math_floor(facRect[1]), math_floor(facRect[2]), iconSizeX, iconSizeY)
		buildoptionsArea = nil
		for i, facInfo in ipairs(facs) do


			-- draw build list
			if i == openedMenu + 1 then
				-- draw buildoptions
				local bopt_rec = RectWH(fac_rec[1] + bopt_inext[1],fac_rec[2] + bopt_inext[2], iconSizeX, iconSizeY)

				local buildList = facInfo.buildList
				local buildQueue = GetBuildQueue(facInfo.unitID)
				for j, unitDefID in ipairs(buildList) do
					local unitDefID = unitDefID
					local options = {}
					-- determine options -------------------------------------------------------------------
					-- building?
					if unitDefID == unitBuildDefID then
						_, _, _, _, options.progress = GetUnitHealth(unitBuildID)
					end
					-- amount
					options.amount = buildQueue[unitDefID]
					-- hover or pressed?
					if j == hoveredBOpt + 1 then
						options.pressed = (lb or mb or rb)
						if lb then
							options.pressed = 1
						elseif rb then
							options.pressed = 2
						elseif mb then
							options.pressed = 3
						end
						options.hovered = true
					end
					options.alpha = 0.85
					-----------------------------------------------------------------------------------------
					DrawButton(bopt_rec, unitDefID, options)
					if buildoptionsArea == nil then
						buildoptionsArea = { bopt_rec[1], bopt_rec[2], bopt_rec[3], bopt_rec[4] }
					else
						buildoptionsArea[1] = bopt_rec[1]
					end
					-- setup next icon pos
					OffsetRect(bopt_rec, bopt_inext[1], bopt_inext[2])

					--if j % 3==0 then
					--  xmin_,xmax_ = xmin   + bopt_inext[1],xmin_ + iconSizeX
					--  ymax_,ymin_ = ymax_  - iconSizeY, ymin_ - iconSizeY
					--end
				end
			else
				-- draw buildqueue
				local buildQueue = Spring.GetFullBuildQueue(facInfo.unitID, maxVisibleBuilds + 1)
				if buildQueue ~= nil then
					local bopt_rec = RectWH(fac_rec[1] + bopt_inext[1], fac_rec[2] + bopt_inext[2], iconSizeX, iconSizeY)

					local n, j = 1, maxVisibleBuilds
					while buildQueue[n] do
						local unitBuildDefID, count = next(buildQueue[n], nil)
						if n == 1 then
							count = count - 1
						end -- cause we show the actual in building unit instead of the factory icon

						if count > 0 then
							local yPad = math_floor(iconSizeY * 0.88)
							local xPad = yPad
							local zoom = 0.04
							drawIcon({bopt_rec[3] - xPad, bopt_rec[2] - yPad, bopt_rec[1] + xPad, bopt_rec[4] + yPad}, "#" .. unitBuildDefID, {1, 1, 1, 0.5}, zoom)
							--TexRectRound(bopt_rec[1] + xPad, bopt_rec[4] + yPad, bopt_rec[3] - xPad, bopt_rec[2] - yPad, (bopt_rec[3] - bopt_rec[1]) * 0.05)
							if count > 1 then
								font:Begin()
								font:SetTextColor(1, 1, 1, 0.66)
								font:Print(count, bopt_rec[1] + ((bopt_rec[3] - bopt_rec[1]) * 0.22), bopt_rec[4] - ((bopt_rec[4] - bopt_rec[2]) * 0.22), fontSize, "o")
								font:End()
							end

							OffsetRect(bopt_rec, bopt_inext[1], bopt_inext[2])
							j = j - 1
							if j == 0 then
								break
							end
						end
						n = n + 1
					end
				end
			end

			-- setup next icon pos
			OffsetRect(fac_rec, fac_inext[1], fac_inext[2])
		end
	else
		buildoptionsArea = nil
	end
end

function widget:DrawWorld()
	if chobbyInterface then
		return
	end

	-- Draw factories command lines
	if waypointMode > 1 or openedMenu >= 0 then
		local fac
		if waypointMode > 1 then
			fac = facs[waypointFac + 1]
		else
			fac = facs[openedMenu + 1]
		end
		if fac ~= nil then
			DrawUnitCommands(fac.unitID)
		end
	end
end

function widget:DrawInMiniMap(sx, sy)

	if openedMenu > -1 then
		gl.PushMatrix()
		local pt = math.min(sx, sy)

		gl.LoadIdentity()
		gl.Translate(0, 1, 0)
		gl.Scale(1 / msx, -1 / msz, 1)

		local r, g, b = GetTeamColor(myTeamID)
		local alpha = 0.5 + math.abs((Spring.GetGameSeconds() % 0.25) * 4 - 0.5)
		local x, _, z = Spring.GetUnitBasePosition(facs[openedMenu + 1].unitID)

		if x ~= nil then
			gl.PointSize(pt * 0.066)
			gl.Color(0, 0, 0)
			gl.BeginEnd(GL.POINTS, function()
				gl.Vertex(x, z)
			end)
			gl.PointSize(pt * 0.051)
			gl.Color(r, g, b, alpha)
			gl.BeginEnd(GL.POINTS, function()
				gl.Vertex(x, z)
			end)
			gl.PointSize(1)
			gl.Color(1, 1, 1, 1)
		end
		gl.PopMatrix()
	end
end

-------------------------------------------------------------------------------
-- GEOMETRIC FUNCTIONS
-------------------------------------------------------------------------------

local function _clampScreen(mid, half, vsd)
	if mid - half < 0 then
		return 0, half * 2
	elseif mid + half > vsd then
		return vsd - half * 2, vsd
	else
		local val = math.floor(mid - half)
		return val, val + half * 2
	end
end

local function _adjustSecondaryAxis(bar_side, vsd, iconSizeD)
	-- bar_side is 0 for left and top, and 1 for right and bottom
	local val = bar_side * (vsd - iconSizeD)
	return val, iconSizeD + val
end

function SetupDimensions(count)
	local length, mid, vsd, iconSizeA, iconSizeB
	if bar_horizontal then
		-- horizontal (top or bottom bar)
		vsa, iconSizeA, vsb, iconSizeB = vsx, iconSizeX, vsy, iconSizeY
	else
		-- vertical (left or right bar)
		vsa, iconSizeA, vsb, iconSizeB = vsy, iconSizeY, vsx, iconSizeX
	end
	length = math.floor(iconSizeA * count)
	mid = vsa * 0.5 + bar_offset

	-- setup expanding direction
	mid = mid + bar_align * length * 0.5

	-- clamp screen
	local v1, v2 = _clampScreen(mid, length * 0.5, vsa)

	-- adjust SecondaryAxis
	local v3, v4 = _adjustSecondaryAxis(bar_side % 2, vsb, iconSizeB)

	-- assign rect
	if bar_horizontal then
		facRect[1], facRect[3], facRect[4], facRect[2] = v1, v2, v3, v4
	else
		facRect[4], facRect[2], facRect[1], facRect[3] = v1, v2, v3, v4
	end
end

function SetupSubDimensions()
	if openedMenu < 0 then
		boptRect = { -1, -1, -1, -1 }
		return
	end

	local buildListn = #facs[openedMenu + 1].buildList
	if bar_horizontal then
		--please note the factorylist is horizontal not the buildlist!!!

		boptRect[1] = math.floor(facRect[1] + iconSizeX * openedMenu)
		boptRect[3] = boptRect[1] + iconSizeX
		if bar_side == 2 then
			--top
			boptRect[2] = vsy - iconSizeY
			boptRect[4] = boptRect[2] - math.floor(iconSizeY * buildListn)
		else
			--bottom
			boptRect[4] = iconSizeY
			boptRect[2] = iconSizeY + math.floor(iconSizeY * buildListn)
		end

	else

		boptRect[2] = math.floor(facRect[2] - iconSizeY * openedMenu)
		boptRect[4] = boptRect[2] - iconSizeY
		if bar_side == 0 then
			--left
			boptRect[1] = iconSizeX
			boptRect[3] = iconSizeX + math.floor(iconSizeX * buildListn)
		else
			--right
			boptRect[3] = vsx - iconSizeX
			boptRect[1] = boptRect[3] - math.floor(iconSizeX * buildListn)
		end

	end
end


-------------------------------------------------------------------------------
-- UNIT FUNCTIONS
-------------------------------------------------------------------------------
function GetBuildQueue(unitID)
	local result = {}
	local queue = GetFullBuildQueue(unitID)
	if queue ~= nil then
		for _, buildPair in ipairs(queue) do
			local udef, count = next(buildPair, nil)
			if result[udef] ~= nil then
				result[udef] = result[udef] + count
			else
				result[udef] = count
			end
		end
	end
	return result
end


-------------------------------------------------------------------------------
-- UNIT INITIALIZTION FUNCTIONS
-------------------------------------------------------------------------------
function UpdateFactoryList()
	facs = {}
	local count = 0

	local teamUnits = Spring.GetTeamUnits(myTeamID)
	for num = 1, #teamUnits do
		local unitID = teamUnits[num]
		local unitDefID = GetUnitDefID(unitID)
		if unitBuildOptions[unitDefID] then
			count = count + 1
			facs[count] = { unitID = unitID, unitDefID = unitDefID, buildList = unitBuildOptions[unitDefID] }
			local _, _, _, _, buildProgress = GetUnitHealth(unitID)
			if buildProgress and buildProgress < 1 then
				unfinished_facs[unitID] = true
			end
		end
	end
end


--function widget:UnitFinished(unitID, unitDefID, unitTeam)
function widget:UnitCreated(unitID, unitDefID, unitTeam)
	if unitTeam ~= myTeamID then
		return
	end

	if unitBuildOptions[unitDefID] then
		facs[#facs + 1] = { unitID = unitID, unitDefID = unitDefID, buildList = unitBuildOptions[unitDefID] }
	end
	unfinished_facs[unitID] = true
end

function widget:UnitGiven(unitID, unitDefID, unitTeam, oldTeam)
	widget:UnitCreated(unitID, unitDefID, unitTeam)
end

function widget:UnitDestroyed(unitID, unitDefID, unitTeam)
	if unitTeam ~= myTeamID then
		return
	end

	if unitBuildOptions[unitDefID] then
		for i, facInfo in ipairs(facs) do
			if unitID == facInfo.unitID then
				if openedMenu + 1 == i and openedMenu > #facs - 2 then
					openedMenu = openedMenu - 1
					if openedMenu < 0 then
						menuHovered = false
					end
				end
				table.remove(facs, i)
				unfinished_facs[unitID] = nil
				return
			end
		end
	end
end

function widget:UnitTaken(unitID, unitDefID, unitTeam, newTeam)
	widget:UnitDestroyed(unitID, unitDefID, unitTeam)
end

function widget:PlayerChanged()
	if removeWhenSpec and Spring.GetSpectatingState() then
		widgetHandler:RemoveWidget(self)
	end
end


-------------------------------------------------------------------------------
-- MOUSE PRESS FUNCTIONS
-------------------------------------------------------------------------------

function widget:MousePress(x, y, button)

	pressedFac = hoveredFac
	pressedBOpt = hoveredBOpt

	if hoveredFac + hoveredBOpt >= -1 then
		if waypointMode > 1 then
			Spring.Echo("BuildBar: Exited greedy waypoint mode")
			Spring.PlaySoundFile(sound_waypoint, 0.9, 'ui')
		end
		waypointFac = -1
		waypointMode = 0
	else
		--todo: close hovered
		if waypointMode > 1 then
			-- greedy waypointMode
			return (button ~= 2) -- we allow middle click scrolling in greedy waypoint mode
		elseif (button == 3) and (openedMenu >= 0) and (#GetSelectedUnits() == 0) then
			-- lazy waypointMode
			waypointMode = 1   -- lazy mode
			waypointFac = openedMenu
			return true
		end

		if waypointMode > 1 then
			Spring.Echo("BuildBar: Exited greedy waypoint mode")
			Spring.PlaySoundFile(sound_waypoint, 0.9, 'ui')
		end
		waypointFac = -1
		waypointMode = 0

		if button ~= 2 then
			openedMenu = -1
			menuHovered = false
		end
		return false
	end
	return true
end

function widget:MouseRelease(x, y, button)
	if pressedFac == hoveredFac and
		pressedBOpt == hoveredBOpt and
		waypointMode < 1
	then
		if hoveredFac >= 0 and waypointMode < 1 then
			MenuHandler(x, y, button)
		else
			BuildHandler(button)
		end
	elseif waypointMode > 0 and waypointFac >= 0 then
		WaypointHandler(x, y, button)
	end
	return -1
end

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------

function MenuHandler(x, y, button)
	if button > 3 then
		return
	end

	if button == 1 then
		local icoRect = {}
		_, icoRect[2], icoRect[3], _ = GetFacIconRect(pressedFac)
		icoRect[1], icoRect[4] = icoRect[3] - repIcoSize, icoRect[2] - repIcoSize
		if IsInRect(x, y, icoRect) then
			--repeat icon clicked
			local unitID = facs[pressedFac + 1].unitID
			local onoff = { 1 }
			if select(4, GetUnitStates(unitID, false, true)) then
				onoff = { 0 }
			end
			Spring.GiveOrderToUnit(unitID, CMD.REPEAT, onoff, 0)
			Spring.PlaySoundFile(sound_click, 0.8, 'ui')
		else
			--if (bar_openByClick) then
			if (not menuHovered) and (openedMenu == pressedFac) then
				openedMenu = -1
				Spring.PlaySoundFile(sound_click, 0.75, 'ui')
			else
				menuHovered = false
				openedMenu = pressedFac
				Spring.PlaySoundFile(sound_click, 0.75, 'ui')
			end
		end
	elseif button == 2 then
		local x, y, z = Spring.GetUnitPosition(facs[pressedFac + 1].unitID)
		Spring.SetCameraTarget(x, y, z)
	elseif button == 3 then
		Spring.Echo("BuildBar: Entered greedy waypoint mode")
		Spring.PlaySoundFile(sound_waypoint, 0.9, 'ui')
		waypointMode = 2 -- greedy mode
		waypointFac = openedMenu
		openedMenu = -1
		pressedFac = -1
		hoveredFac = -1
		blured = false
	end
	return
end

function BuildHandler(button)
	local alt, ctrl, meta, shift = Spring.GetModKeyState()
	local opt = {}
	if alt then
		opt[#opt + 1] = "alt"
	end
	if ctrl then
		opt[#opt + 1] = "ctrl"
	end
	if meta then
		opt[#opt + 1] = "meta"
	end
	if shift then
		opt[#opt + 1] = "shift"
	end

	if button == 1 then
		Spring.GiveOrderToUnit(facs[openedMenu + 1].unitID, -(facs[openedMenu + 1].buildList[pressedBOpt + 1]), {}, opt)
		Spring.PlaySoundFile(sound_queue_add, 0.75, 'ui')
	elseif button == 3 then
		opt[#opt + 1] = "right"
		Spring.GiveOrderToUnit(facs[openedMenu + 1].unitID, -(facs[openedMenu + 1].buildList[pressedBOpt + 1]), {}, opt)
		Spring.PlaySoundFile(sound_queue_rem, 0.75, 'ui')
	end
end

function WaypointHandler(x, y, button)
	if button == 1 or button > 3 then
		Spring.Echo("BuildBar: Exited greedy waypoint mode")
		Spring.PlaySoundFile(sound_waypoint, 0.9, 'ui')
		menuHovered = false
		waypointFac = -1
		waypointMode = 0
		openedMenu = -1
		return
	end

	local alt, ctrl, meta, shift = Spring.GetModKeyState()
	local opt = { "right" }
	if alt then
		opt[#opt + 1] = "alt"
	end
	if ctrl then
		opt[#opt + 1] = "ctrl"
	end
	if meta then
		opt[#opt + 1] = "meta"
	end
	if shift then
		opt[#opt + 1] = "shift"
	end

	local type, param = Spring.TraceScreenRay(x, y)
	if type == 'ground' then
		Spring.GiveOrderToUnit(facs[waypointFac + 1].unitID, CMD.MOVE, param, opt)
	elseif type == 'unit' then
		Spring.GiveOrderToUnit(facs[waypointFac + 1].unitID, CMD.GUARD, { param }, opt)
	else
		--feature
		type, param = Spring.TraceScreenRay(x, y, true)
		Spring.GiveOrderToUnit(facs[waypointFac + 1].unitID, CMD.MOVE, param, opt)
	end
end


function MouseOverIcon(x, y)
	if x >= facRect[1] and x <= facRect[3] and y >= facRect[4] and y <= facRect[2] then
		local icon
		if bar_horizontal then
			icon = math.floor((x - facRect[1]) / fac_inext[1])
		else
			icon = math.floor((y - facRect[2]) / fac_inext[2])
		end

		if icon >= #facs then
			icon = (#facs - 1)
		elseif icon < 0 then
			icon = 0
		end

		return icon
	end
	return -1
end

function MouseOverSubIcon(x, y)
	if openedMenu >= 0 and x >= boptRect[1] and x <= boptRect[3] and y >= boptRect[4] and y <= boptRect[2] then
		local icon
		if bar_side == 0 then
			icon = math.floor((x - boptRect[1]) / bopt_inext[1])
		elseif bar_side == 2 then
			icon = math.floor((y - boptRect[2]) / bopt_inext[2])
		elseif bar_side == 1 then
			icon = math.floor((x - boptRect[3]) / bopt_inext[1])
		else
			--bar_side==3
			icon = math.floor((y - boptRect[4]) / bopt_inext[2])
		end

		if icon > #facs[openedMenu + 1].buildList - 1 then
			icon = #facs[openedMenu + 1].buildList - 1
		elseif icon < 0 then
			icon = 0
		end

		return icon
	end
	return -1
end



function widget:IsAbove(x, y)
	if WG['topbar'] and WG['topbar'].showingQuit() then
		menuHovered = false
		openedMenu = -1
		return false
	end

	local _, _, lb, mb, rb = GetMouseState()
	if ((lb or mb or rb) and openedMenu == -1) or waypointMode == 2 then
		return false
	end

	hoveredFac = MouseOverIcon(x, y)
	hoveredBOpt = MouseOverSubIcon(x, y)

	-- set hover unitdef id for buildmenu so info widget can show it
	if WG['buildmenu'] then
		if hoveredFac >= 0 then
			if WG['info'] then
				setInfoDisplayUnitID = facs[hoveredFac + 1].unitID
				WG['info'].displayUnitID(setInfoDisplayUnitID)
			end
		elseif hoveredBOpt >= 0 then
			if hoveredBOpt >= 0 then
				WG['buildmenu'].hoverID = facs[openedMenu + 1].buildList[hoveredBOpt + 1]
			end
		end
	end

	if hoveredFac >= 0 then
		--factory icon
		if not bar_openByClick and (openedMenu < 0 or menuHovered) then
			menuHovered = true
			openedMenu = hoveredFac
		end
		if not blured then
			Spring.PlaySoundFile(sound_hover, 0.8, 'ui')
			blured = true
		end
		return true
	elseif openedMenu >= 0 and IsInRect(x, y, boptRect) then
		--buildoption icon
		if not blured then
			Spring.PlaySoundFile(sound_hover, 0.8, 'ui')
			blured = true
		end
		return true
	else
		if bar_autoclose and (bar_openByClick or not bar_openByClick and menuHovered) then
			menuHovered = false
			openedMenu = -1
		end
	end

	if blured then
		Spring.PlaySoundFile(sound_hover, 0.8, 'ui')
		blured = false
	end
	return false
end
