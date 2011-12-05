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
local StageHolder
--StageHolder:setReferencePoint(display.c)

local EscapeGroup = display.newGroup()
--EscapeGroup:setReferencePoint(display.c)

-- Screen for keeping positions
local screen

-- Camera boundaries
local cameraBounds

-- Motion ease
local Easing = 5

local abs    = math.abs
local flr    = math.floor
local ceil   = math.ceil
local tonum  = tonumber
local ipairs = ipairs
local xBuffer, yBuffer = false, false
local usingDirector = false
local cullCount, cull = 0

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
            if v.axisLock == "x" then
                deltaX, deltaY = ( centerX / v.xScale - Actor.x ) * v.depth - v.x, ( centerY / v.yScale - Actor.y ) * v.depth - v.y
                deltaX = 0
            elseif v.axisLock == "y" then
                deltaX, deltaY = ( centerX / v.xScale - Actor.x ) * v.depth - v.x, ( centerY / v.yScale - Actor.y ) - v.y
            else
                deltaX, deltaY = ( centerX / v.xScale - Actor.x ) * v.depth - v.x, ( centerY / v.yScale - Actor.y ) * v.depth - v.y
            end

            local xEase = Easing - Actor.xSpeed / Easing * 1.8
            local yEase = Easing - Actor.ySpeed / Easing * 1.8
            if xEase < 1 then xEase = 1 end
            if yEase < 1 then yEase = 1 end
            v.x, v.y = v.x + deltaX / xEase, v.y + deltaY / yEase
            if zoomDir then
                if zoomDir == "out" then
                    v:scale(0.999, 0.999)
                    v:translate(v.contentWidth * -0.0005 * Camera.zoomLevel, v.contentHeight * -0.0005 * Camera.zoomLevel)
                elseif zoomDir == "in" then
                    v:scale(1.001, 1.001)
                    v:translate(v.contentWidth * -0.0005 * Camera.zoomLevel, v.contentHeight * -0.0005 * Camera.zoomLevel)
                else
                    v.xScale, v.yScale = Camera.zoomLevel, Camera.zoomLevel
                end
            end
        end

    elseif axis == "x" then
        for i,v in ipairs(Stages) do
            local deltaX
            if buffer then
                deltaX = ( centerX - Actor.x )
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
        Actor.xSpeed = abs(Actor.xPrev - Actor.x)
        Actor.ySpeed = abs(Actor.yPrev - Actor.y)
        Actor.xPrev = Actor.x
        Actor.yPrev = Actor.y
        if cameraBounds then

            right  = Actor.x - screen.x + display.screenOriginX > cameraBounds.left
            left   = Actor.x - screen.x + display.screenOriginX < cameraBounds.right
            top    = Actor.y - screen.y + display.screenOriginY < cameraBounds.bottom
            bottom = Actor.y - screen.y + display.screenOriginY > cameraBounds.top

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
            elseif not left then -- right buffer
                Actor.x = cameraBounds.right - 2
                xBuffer = true
                --setPositions("x", "right", speed)
            elseif not right then -- left buffer
                Actor.x = cameraBounds.left + 2
                xBuffer = true
                --setPositions("x", "left", speed)
            end
            setPositions("x")--, nil, speed
        else
            setPositions()
        end
    end

    if #Camera.hTiles > 0 then

        -- cycle through every tilerr
        for i=1, #Camera.hTiles do

            local childArr = Camera.hTiles[i].children

            -- how many children are there?
            local numChildren = #childArr

            -- this is the last tiler in the group
            local lastChild = childArr[numChildren]
            -- this is the first tiler in the group
            local firstChild = childArr[1]

            local fx, fy = firstChild:localToContent( 0, 0 )
            local lx, ly = lastChild:localToContent( 0, 0 )
            if fx < 0 - firstChild.contentWidth then

                -- set the tile at the last childs x position and add a width
                firstChild.x = lastChild.x + lastChild.contentWidth
                table.insert(childArr, table.remove(childArr, 1))
            elseif lx > screenWidth + firstChild.contentWidth then

                -- set the tile and the first childs x position and subtract a width
                lastChild.x = firstChild.x - lastChild.contentWidth
                table.insert(childArr, 1, table.remove(childArr))
            end
        end
    end

    if #Camera.vTiles > 0 then

        -- cycle through every tilerr
        for i=1, #Camera.vTiles do

            local childArr = Camera.vTiles[i].children

            -- how many children are there?
            local numChildren = #childArr

            -- this is the last tiler in the group
            local lastChild = childArr[numChildren]
            -- this is the first tiler in the group
            local firstChild = childArr[1]

            local fx, fy = firstChild:localToContent( 0, 0 )
            local lx, ly = lastChild:localToContent( 0, 0 )
            if fy < 0 - firstChild.contentHeight then

                -- set the tile at the last childs x position and add a width
                firstChild.y = lastChild.y + lastChild.contentHeight
                table.insert(childArr, table.remove(childArr, 1))
            elseif ly > screenHeight + firstChild.contentHeight then

                -- set the tile and the first childs x position and subtract a width
                lastChild.y = firstChild.y - lastChild.contentHeight
                table.insert(childArr, 1, table.remove(childArr))
            end
        end
    end
end

cull = function()
    local a, o = Actor
    for i=1, Stage.numChildren do
        o = Stage[i]
        if o.y < a.y - screenHeight or o.y > a.y + screenHeight then
            o.isVisible = false
        else o.isVisible = true end
        if o.x < a.x - screenWidth or o.x > a.x + screenWidth then
            o.isVisible = false
        else o.isVisible = true end
    end
    if panningActor then panningActor.isVisible = false end
    screen.isVisible = false
end

Camera.track = function( obj )
    local onDelay
    onDelay = function()
        if obj and Stage then
            Actor = obj
            Actor.xPrev = Actor.x
            Actor.yPrev = Actor.y
            Stage:insert(Actor)
        end
        onDelay = nil
    end
    timer.performWithDelay(100, onDelay, false)
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
            if depth > 0 then
                for i=2, #Stages do
                    if depth <= Stages[i].depth then
                        StageHolder:insert(i,stg)
                        StageHolder:insert( Stage )
                        break
                    end
                end
            end
        end
    else
        Stage:insert(obj)
        obj:translate(-Stage.x, -Stage.y)
    end
    obj.depth = depth or 1
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

local panningActor, panTransition, panTimer
local xOrigin, yOrigin

-- TODO Transition to point
Camera.panning = false

local getPanningActor = function()
    if not panningActor then
        panningActor = display.newRect(0, 0, 5, 5)
        panningActor.isVisible = false
    end
    if Actor then
        panningActor.x, panningActor.y = Actor.x, Actor.y
    else
        panningActor.x, panningActor.y = centerX, centerY
    end
    return panningActor
end

onTouch = function(e)
    if e.phase == "began" or not xOrigin then
        local a = getPanningActor()
        a.x, a.y = Stage:contentToLocal(e.x + (centerX - e.x), e.y + (centerY - e.y))

        xOrigin, yOrigin = a.x, a.y

        if dragEnabled == "y" then a.y = yOrigin
        elseif dragEnabled == "x" then a.x = xOrigin
        else a.x, a.y = xOrigin, yOrigin end

        Camera.panning = true
        Camera.track(a)
    elseif e.phase == "moved" then
        if dragEnabled == "y" then panningActor.y = yOrigin + e.yStart - e.y
        elseif dragEnabled == "x" then panningActor.x = xOrigin + e.xStart - e.x
        else panningActor.x, panningActor.y = xOrigin + e.xStart - e.x, yOrigin + e.yStart - e.y end
    end
end

Camera.enableDrag = function(axis)
    if not dragEnabled then
        dragEnabled = axis or true
        Runtime:addEventListener("touch", onTouch)
    end
end

Camera.disableDrag = function()
    if dragEnabled then
        dragEnabled = nil
        Runtime:removeEventListener("touch", onTouch)
    end
end

Camera.pan = function( args )

    Camera.panning = true
    Camera.track(getPanningActor())

    panTransition = transition.to(panningActor, {time=args.time, x=args.x, y=args.y, delay=args.delay, delta=args.delta ~= false, transition=args.ease or easing.inOutQuad, onComplete=args.onComplete })
    local onComplete = function()
        Camera.panning = false
        Camera.untrack()
        if args.callback then args.callback() end
    end
    --panTimer = timer.performWithDelay(args.time * Easing * 0.5, onComplete, false)
end

Camera.cancelPan = function()
    timer.cancel(panTimer)
    transition.cancel(panTransition)

    Camera.panning = false

    if Actor == panningActor then
        Camera.untrack()
        display.remove(panningActor)
        panningActor = nil
    end
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

Camera.hTiles = {}
Camera.vTiles = {}
Camera.tile = function(path, w, h, depth, lock, axis)

    local newTile = function()
        if type(path) == "string" then
            return display.newImageRect(path, w, h)
        else
            return path[1]:grabSprite(path[2], true)
        end
    end

    local tiler = display.newGroup()
    tiler.children = {}

    local axis, numTiles, t = axis or "h"

    if axis == "h" then
        Camera.hTiles[#Camera.hTiles+1] = tiler
        numTiles = ceil(screenWidth / w)

        for i=0, numTiles + 1 do
            t = newTile( path )
            t:setReferencePoint(display.BottomCenterReferencePoint)
            t.x, t.y = t.contentWidth*0.5+i*t.contentWidth, t.y + t.contentHeight
            if flr(i/2) ~= i/2 then
                t.xScale = t.xScale * -1
            end
            tiler:insert(t)
            tiler.children[i+1] = t
        end
    elseif axis == "v" then
        Camera.vTiles[#Camera.vTiles+1] = tiler
        numTiles = ceil(screenHeight / h)

        for i=0, numTiles + 1 do
            t = newTile( path )
            t:setReferencePoint(display.CenterLeftReferencePoint)
            t.x, t.y = t.x + t.contentWidth, t.contentHeight*0.5+i*t.contentHeight
            if flr(i/2) ~= i/2 then
                t.yScale = t.yScale * -1
            end
            tiler:insert(t)
            tiler.children[i+1] = t
        end
    end

    Camera.add(tiler, depth, lock)

    tiler.position = function( self, x, y )
        tiler:setReferencePoint(display.BottomLeftReferencePoint)
        tiler.x, tiler.y = x, y - tiler.contentHeight
    end

    return tiler
end

Camera.init = function( directorGroup )
    if not Running then
        Running = true

        Stage = display.newGroup()
        StageHolder = display.newGroup()
        StageHolder:insert(Stage)
        Stage.depth = 1
        Stages[1] = Stage

        screen = display.newRect( screenX, screenY, screenWidth, screenHeight, "c")
        screen.isVisible = false
        Stage:insert(screen)

        Runtime:addEventListener("enterFrame", Camera)
    end
end

-- TODO this will need to loop through and remove all objects and their fields
Camera.kill = function()
    Actor = nil
    panningActor = nil
    Runtime:removeEventListener("enterFrame", Camera)

    Camera.untrack()

    if dragEnabled then
        Camera.disableDrag()
    end

    while #Camera.hTiles > 0 do
        table.remove(Camera.hTiles)
    end

    while #Camera.vTiles > 0 do
        table.remove(Camera.vTiles)
    end

    while #Stages > 0 do
        display.remove(table.remove(Stages))
    end
    Stage = nil
    Stages = {}
    display.remove(StageHolder)
    StageHolder = nil

    --EscapeGroup:insert(StageHolder)
    Running = false
end

Camera.setAlpha = function(n)
    StageHolder.alpha = n
end

Camera.getActor = function()
    return Actor or panningActor
end

Camera.getStage = function()
    return StageHolder
end

Camera.running = function()
    return Running
end

return Camera
