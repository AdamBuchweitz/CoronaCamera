-- Class
local Camera = {}

local Running = false

local centerX, centerY = display.contentCenterX, display.contentCenterY
local screenX, screenY = display.screenOriginX, display.screenOriginY

-- Actor to track
local Actor

-- Main Camera stage
local Stage

-- Array of stages
local Stages = {}

-- Holder for all the stages
local StageHolder = display.newGroup()
--StageHolder:setReferencePoint(display.c)

local EscapeGroup = display.newGroup()
--EscapeGroup:setReferencePoint(display.c)

-- Screen for keeping positions
local screen

-- Camera boundaries
local cameraBounds

-- Motion ease
local Easing = 5

local abs = math.abs
local ipairs = ipairs
local xBuffer, yBuffer = false, false
local usingDirector = false

Camera.zoomLevel = 1

local zoomDir
local setPositions = function( axis, buffer, speed )
    if abs(Stage.xScale - Camera.zoomLevel) > 0.0005 then
        if Stage.xScale > Camera.zoomLevel then zoomDir = "out"
        else zoomDir = "in" end
    else zoomDir = "set" end
    if axis ~= "x" and axis ~= "y" then
        for i,v in ipairs(Stages) do
            local deltaX, deltaY
            if zoomDir then
                if zoomDir == "out" then v:scale(0.999, 0.999)
                elseif zoomDir == "in" then v:scale(1.001, 1.001)
                else v.xScale, v.yScale = Camera.zoomLevel, Camera.zoomLevel end
            end
            if v.axisLock == "x" then
                deltaX, deltaY = ( centerX / v.xScale - Actor.x ) * v.depth - v.x, ( centerY / v.yScale - Actor.y ) * v.depth - v.y
            elseif v.axisLock == "y" then
                deltaX, deltaY = ( centerX / v.xScale - Actor.x ) * v.depth - v.x, ( centerY / v.yScale - Actor.y ) - v.y
            else
                deltaX, deltaY = ( centerX / v.xScale - Actor.x ) * v.depth - v.x, ( centerY / v.yScale - Actor.y ) * v.depth - v.y
            end

            v.x, v.y = v.x + deltaX / Easing, v.y + deltaY / Easing
        end
    elseif axis == "x" then
        print("axis = x")
        for i,v in ipairs(Stages) do
            local deltaX
            if buffer then
                deltaX = ( centerX - Actor.x )
                --print( screen.x - v.x)
                if buffer == "left" then
                    --v.x = v.x + deltaX
                    v.x = v.x + ( screen.x - v.x ) / Easing
                else
                    v.x = screen.x + screen.width - v.width + 20
                end
            else
                if v.axisLock == "x" then
                    deltaX = ( centerX - Actor.x ) - v.x -- keep the stage on the same horizontal plane
                else
                    deltaX = ( centerX - Actor.x ) * v.depth - v.x
                end
                v.x = v.x + deltaX / Easing * ((speed or 10) / 10)
            end
        end
    else
        print("axis = y")
        for i,v in ipairs(Stages) do
            local deltaX
            if v.axisLock == "x" then
                deltaX = ( centerX - Actor.x ) - v.x
            else
                deltaX = ( centerX - Actor.x ) * v.depth - v.x
            end
            v.x = v.x + deltaX / Easing
            if v.axisLock == "y" then
                v.y = ( centerY - Actor.y ) -- keep the stage on the same horizontal plane
            else
                v.y = ( centerY - Actor.y ) * v.depth
            end
        end
    end
end

-- Local functions

local left, top, right, bottom
Camera.enterFrame = function( event )
    if Actor then
        local speed = math.abs(Actor.xPrev - Actor.x)
        Actor.xPrev = Actor.x
        if cameraBounds then

            right  = Actor.x - screen.x > cameraBounds.left --+ 100
            left   = Actor.x - screen.x < cameraBounds.right -- 100
            top    = Actor.y - screen.y < cameraBounds.bottom
            bottom = Actor.y - screen.y > cameraBounds.top

            if top and bottom then
                yBuffer = false
                setPositions("y")
            elseif not top then -- bottom buffer
                yBuffer = true
            elseif not bottom then -- top buffer
                yBuffer = true
            end

            if right and left then
                xBuffer = false
                setPositions("x")--, nil, speed
            elseif not left then -- right buffer
                xBuffer = true
                --setPositions("x", "right", speed)
            elseif not right then -- left buffer
                xBuffer = true
                --setPositions("x", "left", speed)
            end
        else
            setPositions()
        end
    end
    --if #Camera.tiles then
        --for i,v in ipairs(Camera.tiles) do
            --local gx, gy = v.one:localToContent( 0, 0 )
            ----print(gx, gy)
            --if v.parent.x < v.width then
                --print("got to parallax")
            --end
        --end
    --end
end

Camera.track = function( obj )
    local onDelay = function()
        Actor = obj
        Actor.xPrev = 0
        Stage:insert(Actor)
    end
    timer.performWithDelay(100, onDelay, false)
    --Stage.x, Stage.y = centerX - Actor.x, centerX - Actor.y
end

Camera.untrack = function()
    Actor = nil
end

Camera.add = function( obj, depth, axisLock )
    if depth then
        local stg
        for i,v in ipairs(Stages) do
            if v.depth == depth then
                stg = v
            end
        end
        if stg and stg.axisLock == axisLock then
            stg:insert(obj)
            obj:translate(-stg.x, -stg.y)
        else
            stg = display.newGroup()
            --stg:setReferencePoint(display.c)
            stg.depth = depth
            stg.axisLock = axisLock
            stg:insert(obj)
            Stages[ #Stages+1 ] = stg
            local pos = nil
            if depth > 0 then
                for i=2, #Stages do
                    if depth <= Stages[i].depth then
                        StageHolder:insert(i,stg)
                        StageHolder:insert( Stage )
                        break
                    end
                end
            else
            end
        end
    else
        Stage:insert(obj)
        obj:translate(-Stage.x, -Stage.y)
    end
end

Camera.setCameraBounds = function( left, top, right, bottom)
    cameraBounds = {}
    cameraBounds.left = left + centerX
    cameraBounds.top = top + centerY
    cameraBounds.right = right - centerX
    cameraBounds.bottom = bottom - centerY
end

Camera.setMotionEase = function( num )
    if type(num) == "number" then
        Easing = num
    else
        error("Expecting a number, recieved a "..type(num))
    end
end

-- TODO Pan
Camera.trackFinger = function()
end

-- TODO Transition to point
Camera.moveTo = function( x, y, scale )
end

Camera.zoomTo = function( num )
    Camera.zoomLevel = num
end

-- TODO Pinch zoom
Camera.zoom = function( num )
    for i,v in ipairs(Stages) do
        transition.to(v, {time=2000, xScale=-0.2, yScale=-0.2, delta=true, transition=easing.inOutQuad})
    end
end

Camera.tiles = {}
Camera.tile = function(path, w, h, depth, lock)
    local tiler = {}

    if type(path) == "string" then
        tiler.one = display.newImageRect(path, w, h, "bl")
        tiler.two = display.newImageRect(path, w, h, "br")
    else
        tiler.one = path[1]:grabSprite(path[2], true)
        tiler.two = path[1]:grabSprite(path[2], true)
    end

    tiler.two.xScale = -1

    tiler.position = function( self, x, y )
        Camera.add(tiler.one, depth, lock)
        Camera.add(tiler.two, depth, lock)
        tiler.one.x, tiler.one.y = x, y
        tiler.two.x, tiler.two.y = x + tiler.one.width, y
        tiler.parent = tiler.one.parent
        tiler.width = tiler.one.width * -2
    end

    Camera.tiles[#Camera.tiles+1] = tiler

    return tiler
end

Camera.init = function( directorGroup )
    usingDirector = directorGroup ~= nil
    if not Running then
        Running = true
        Stage = display.newGroup()
        --Stage:setReferencePoint(display.c)
        Stage.depth = 1
        Stages[1] = Stage
        StageHolder:insert(Stage)

        screen = display.newRect( screenX, screenY, screenWidth, screenHeight, "c")
        screen.isVisible = false
        Stage:insert(screen)

        Runtime:addEventListener("enterFrame", Camera)
    end
    if usingDirector then
        directorGroup:insert(StageHolder)
    end
end

-- TODO this will need to loop through and remove all objects and their fields
Camera.kill = function()
    Actor = nil
    Runtime:removeEventListener("enterFrame", Camera)
    local i, g = #Stages
    while i > 0 do
        g = table.remove(Stages)
        if usingDirector then
            display.remove(g)
        end
        i = i-1
    end
    EscapeGroup:insert(StageHolder)
    Running = false
end

return Camera

