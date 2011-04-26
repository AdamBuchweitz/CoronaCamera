-- Class
local Camera = {}

local Running = false

local centerX, centerY = display.contentCenterX, display.contentCenterY
local screenX, screenY = display.screenOriginX, display.screenOriginY

-- Actor to track
local Actor

-- Main Camera stage
local Stage = display.newGroup()
Stage.depth = 1

-- Array of stages
local Stages = {}
Stages[1] = Stage

-- Holder for all the stages
local StageHolder = display.newGroup()
StageHolder:insert(Stage)

-- Screen for keeping positions
local screen = display.newRect( screenX, screenY, screenWidth, screenHeight)
screen.isVisible = false
Stage:insert(screen)

-- Camera boundaries
local cameraBounds

local abs = math.abs
local ipairs = ipairs
local xBuffer, yBuffer = false, false

-- Motion ease
-- TODO make this work...
local Easing = 1


local setPositions = function( axis, ease )
    if axis ~= "x" and axis ~= "y" then
        for i,v in ipairs(Stages) do
            local deltaX, deltaY
            if v.axisLock == "x" then
                deltaX, deltaY = ( centerX - Actor.x ) - v.x, ( centerY - Actor.y ) * v.depth - v.y
            elseif v.axisLock == "y" then
                deltaX, deltaY = ( centerX - Actor.x ) * v.depth - v.x, ( centerY - Actor.y ) - v.y
            else
                deltaX, deltaY = ( centerX - Actor.x ) * v.depth - v.x, ( centerY - Actor.y ) * v.depth - v.y
            end
            v.x, v.y = v.x + deltaX / Easing, v.y + deltaY / Easing
        end
    elseif axis == "x" then
        for i,v in ipairs(Stages) do
            local deltaX = ( centerX - Actor.x ) * v.depth - v.x
            if v.axisLock == "x" then
                v.x = ( centerX - Actor.x ) / (ease or 1) -- keep the stage on the same verticle plane
            else
                --v.x = ( centerX - Actor.x ) * v.depth / (ease or 1)
                v.x = v.x + deltaX / (ease or 1)
                --print(abs(deltaX), i)
                --v.x = ( v.x + deltaX )
            end
        end
    else
        for i,v in ipairs(Stages) do
            if v.axisLock == "y" then
                v.y = ( centerY - Actor.y ) -- keep the stage on the same horizontal plane
            else
                v.y = ( centerY - Actor.y ) * v.depth
            end
        end
    end
end

-- Local functions
local onEnterFrame = function( event )
    if Actor then
        --local speed = math.abs(Actor.xPrev - Actor.x)
        --Actor.xPrev = Actor.x
        if cameraBounds then

            local left, top, right, bottom
            right  = Actor.x - screen.x > cameraBounds.left + 100
            left   = Actor.x - screen.x < cameraBounds.right - 100
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
                setPositions("x")
            elseif not left then -- right buffer
                xBuffer = true
                --setPositions("x", 10)
            elseif not right then -- left buffer
                xBuffer = true
                --setPositions("x", 10)
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

-- TODO Pinch zoom
Camera.zoom = function( event )
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

-- TODO this will need to loop through and remove all objects and their fields
Camera.kill = function()
    Runtime:removeEventListener("enterFrame", onEnterFrame)
    for key,value in pairs(Camera) do
        v = nil
    end
    Camera = nil
end

return Camera
