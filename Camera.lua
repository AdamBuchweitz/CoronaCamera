-- Class
local Camera = {}

local Running = false

-- Motion ease
-- TODO make this work...
local Ease = 0

-- Actor to track
local Actor
local halfHeight, halfWidth

-- Camera stage
local Stage = display.newGroup()
Stage.depth = 1

local Stages = {}
Stages[1] = Stage

local StageHolder = display.newGroup()
StageHolder:insert(Stage)

-- Screen
local screen = display.newRect( 0, 0, screenWidth, screenHeight)
screen.isVisible = false
Stage:insert(screen)

-- Boundaries
local cameraBounds

local setPositions = function( axis, edge )
    if axis ~= "x" and axis ~= "y" then
        for i,v in ipairs(Stages) do
            if v.axisLock == "x" then
            elseif v.axisLock == "y" then
            else
                v.x, v.y = ( centerX - Actor.x ) * v.depth , ( centerX - Actor.y ) * v.depth
            end
        end
    elseif axis == "x" then
        for i,v in ipairs(Stages) do
            if edge then
            elseif v.axisLock == "x" then
                v.x = ( centerX - Actor.x )
            else
                v.x = ( centerX - Actor.x ) * v.depth
            end
        end
    else
        for i,v in ipairs(Stages) do
            if edge then
                --if edge == "top" then
                    --v.y = screenY+screenHeight
                --else
                    --v.y = screen.y
                --end
            elseif v.axisLock == "y" then
                v.y = ( centerY - Actor.y )
            else
                v.y = ( centerY - Actor.y ) * v.depth
            end
        end
    end
end

-- Local functions
local onEnterFrame = function( event )
    if Actor then
        local speed = math.abs(Actor.xPrev - Actor.x)
        Actor.xPrev = Actor.x
        if cameraBounds then
            local xDiff, yDiff = Actor.x - screen.x, Actor.y - screen.y
            if yDiff > cameraBounds.top and yDiff < cameraBounds.bottom then
                setPositions("y")
            elseif cameraBounds.top - yDiff > 300 then
                setPositions("y", "top")
            elseif cameraBounds.bottom - yDiff < -200 then
                setPositions("y", "bottom")
            end
            if xDiff > cameraBounds.left and xDiff < cameraBounds.right then
                setPositions("x")
            else
                --setPositions("x", true)
            end
        else
            setPositions()
        end
    end
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
    cameraBounds.top = top + centerY
    cameraBounds.left = left + centerX
    cameraBounds.bottom = bottom - centerY
    cameraBounds.right = right - centerX
end

Camera.setMotionEase = function( num )
    if type(num) == "number" then
        Ease = num
    else
        error("Expecting a number, recieved a "..type(num))
    end
end

Camera.trackFinger = function()
end

Camera.moveTo = function( x, y )
end

Camera.init = function( useDirector )
    if not Running then
        Running = true
        Runtime:addEventListener("enterFrame", onEnterFrame)
    end
    if useDirector then
        useDirector:insert(StageHolder)
    end
end

Camera.kill = function()
    Runtime:removeEventListener("enterFrame", onEnterFrame)
    for key,value in pairs(Camera) do
        v = nil
    end
    Camera = nil
end

return Camera
