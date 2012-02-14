-- Class
local Camera = {}

local Running = false

local centerX, centerY = display.contentCenterX, display.contentCenterY
local screenX, screenY = display.screenOriginX, display.screenOriginY
local trackX, trackY = centerX, centerY

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

local tInsert, tRemove = table.insert, table.remove
local abs    = math.abs
local flr    = math.floor
local ceil   = math.ceil
local tonum  = tonumber
local ipairs = ipairs
local xBuffer, yBuffer = false, false
local cullCount, cull = 0
local hTiles, vTiles = {}, {}

Camera.zoomLevel = 1

local zoomDir
local setPositions = function( axis, buffer, speed )
    --if abs(Stage.xScale - Camera.zoomLevel) > 0.0005 then
        --if Stage.xScale > Camera.zoomLevel then zoomDir = "out"
        --else zoomDir = "in" end
    --else zoomDir = "set" end
    if axis ~= "x" and axis ~= "y" then

        for i=1, #Stages do
            local v = Stages[i]

            if Camera.panning then
                if v.axisLock == "x" then
                    v.y = ( trackY / v.yScale - Actor.y ) * v.depth
                elseif v.axisLock == "y" then
                    v.x = ( trackX / v.xScale - Actor.x ) * v.depth
                else
                    v.x, v.y = ( trackX / v.xScale - Actor.x ) * v.depth, ( trackY / v.yScale - Actor.y ) * v.depth
                end
            else

                local deltaX, deltaY
                if v.axisLock == "x" then
                    deltaX, deltaY = 0, ( trackY / v.yScale - Actor.y ) * v.depth - v.y
                elseif v.axisLock == "y" then
                    deltaX, deltaY = ( trackX / v.xScale - Actor.x ) * v.depth - v.x, 0
                else
                    deltaX, deltaY = ( trackX / v.xScale - Actor.x ) * v.depth - v.x, ( trackY / v.yScale - Actor.y ) * v.depth - v.y
                end

                local xEase = Easing - Actor.xSpeed / Easing * 1.8
                local yEase = Easing - Actor.ySpeed / Easing * 1.8
                if xEase < 1 then xEase = 1 end
                if yEase < 1 then yEase = 1 end
                v:translate(deltaX / xEase, deltaY / yEase)
            end
            --if zoomDir then
                --if zoomDir == "out" then
                    --v:scale(0.999, 0.999)
                    --v:translate(v.contentWidth * -0.0005 * Camera.zoomLevel, v.contentHeight * -0.0005 * Camera.zoomLevel)
                --elseif zoomDir == "in" then
                    --v:scale(1.001, 1.001)
                    --v:translate(v.contentWidth * -0.0005 * Camera.zoomLevel, v.contentHeight * -0.0005 * Camera.zoomLevel)
                --else
                    --v.xScale, v.yScale = Camera.zoomLevel, Camera.zoomLevel
                --end
            --end
        end

    elseif axis == "x" then
        print('x')
        for i,v in ipairs(Stages) do
            local deltaX
            if buffer then
                deltaX = ( trackX - Actor.x )
                if buffer == "left" then
                    --v.x = v.x + deltaX
                    v.x = v.x + ( screen.X - v.x ) / Easing
                else
                    v.x = screen.X + screen.width - v.width + 20
                end
            else
                if v.axisLock == "x" then
                    deltaX = ( trackX - Actor.x ) - v.x -- keep the stage on the same horizontal plane
                else
                    deltaX = ( trackX - Actor.x ) * v.depth - v.x
                end
                v.x = v.x + deltaX / Easing * ((speed or 10) / 10)
            end
        end
    else
        print('y')
        for i,v in ipairs(Stages) do
            local deltaX
            if v.axisLock == "x" then
                deltaX = ( trackX - Actor.x ) - v.x
            else
                deltaX = ( trackX - Actor.x ) * v.depth - v.x
            end
            v.x = v.x + deltaX / Easing
            if v.axisLock == "y" then
                v.y = ( trackY - Actor.y ) -- keep the stage on the same horizontal plane
            else
                v.y = ( trackY - Actor.y ) * v.depth
            end
        end
    end
end

-- Local functions

local left, top, right, bottom
Camera.enterFrame = function( event )
    if Actor then
        local x, y = Actor.x, Actor.y
        Actor.xSpeed = abs(Actor.xPrev - x)
        Actor.ySpeed = abs(Actor.yPrev - y)
        Actor.xPrev = x
        Actor.yPrev = y
        if cameraBounds then

            right  = x - screen.X + display.screenOriginX > cameraBounds.left
            left   = x - screen.X + display.screenOriginX < cameraBounds.right
            top    = y - screen.Y + display.screenOriginY < cameraBounds.bottom
            bottom = y - screen.Y + display.screenOriginY > cameraBounds.top

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
                x = cameraBounds.right - 2
                xBuffer = true
                --setPositions("x", "right", speed)
            elseif not right then -- left buffer
                x = cameraBounds.left + 2
                xBuffer = true
                --setPositions("x", "left", speed)
            end
            setPositions("x")--, nil, speed
        else
            setPositions()
        end
    end

    -- cycle through every tiler
    for i=1, #hTiles do

        local childArr = hTiles[i].children

        -- how many children are there?
        local numChildren = #childArr

        -- this is the last tiler in the group
        local lastChild = childArr[numChildren]
        -- this is the first tiler in the group
        local firstChild = childArr[1]

        local fx, fy = firstChild:localToContent( 0, 0 )
        local lx, ly = lastChild:localToContent( 0, 0 )
        if fx + firstChild.contentWidth < screenLeft then

            -- set the tile at the last childs x position and add a width
            firstChild:translate(hTiles[i].totalWidth, 0)
            tInsert(childArr, tRemove(childArr, 1))
        elseif lx - firstChild.contentWidth > screenRight then

            -- set the tile and the first childs x position and subtract a width
            lastChild:translate(-hTiles[i].totalWidth, 0)
            tInsert(childArr, 1, tRemove(childArr))
        end
    end

    -- cycle through every tiler
    for i=1, #vTiles do

        local childArr = vTiles[i].children

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
            tInsert(childArr, tRemove(childArr, 1))
        elseif ly > screenHeight + firstChild.contentHeight then

            -- set the tile and the first childs x position and subtract a width
            lastChild.y = firstChild.y - lastChild.contentHeight
            tInsert(childArr, 1, tRemove(childArr))
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
        for i=1, #Stages do
            if Stages[i].depth == depth then
                stg = Stages[i]
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
    cameraBounds.left = left + trackX
    cameraBounds.top = top + trackY
    cameraBounds.right = right - trackX
    cameraBounds.bottom = bottom - trackY
end

Camera.setMotionEase = function( num )
    if type(num) == "number" then
        Easing = num
    else
        error("Expecting a number, recieved a "..type(num))
    end
end

Camera.setTrackingPoint = function( x, y )
    trackX, trackY = x or trackX, y or trackY
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
        panningActor.x, panningActor.y = trackX - Stage.x, trackY - Stage.y
    end
    return panningActor
end

onTouch = function(e)
    if e.phase == "began" or not xOrigin then
        local a = getPanningActor()
        a.x, a.y = Stage:contentToLocal(e.x + (trackX - e.x), e.y + (trackY - e.y))

        xOrigin, yOrigin = a.x, a.y

        if dragEnabled == "y" then a.y = yOrigin
        elseif dragEnabled == "x" then a.x = xOrigin
        else a.x, a.y = xOrigin, yOrigin end

        Camera.dragging = true
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

    local onComplete = function()
        Camera.panning = false
        Camera.untrack()
        if args.onComplete then args.onComplete() end
    end
    panTransition = transition.to(panningActor, {time=args.time, x=args.x, y=args.y, delay=args.delay, delta=args.delta ~= false, transition=args.ease or easing.inOutQuad, onComplete=onComplete })
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

Camera.tile = function(path, w, h, depth, lock, axis, spacer)
    local spacer = spacer or 0

    local tiler = display.newGroup()
    tiler.children = {}

    local newTile = function()
        if type(path) == "string" then
            return display.newImageRect(path, w, h)
        else
            return path[1]:grabSprite(path[2], true)
        end
    end

    local axis, numTiles, t = axis or "h"

    if axis == "h" then
        hTiles[#hTiles+1] = tiler
        numTiles = ceil(screenWidth / (w + spacer))

        for i=0, numTiles + 1 do
            t = newTile( path )
            t:setReferencePoint(display.BottomLeftReferencePoint)
            if t.contentWidth ~= w then
                s = w / t.width
                t.xScale, t.yScale = s, s
            end
            if i % 2 == 1 then
                t.xScale = t.xScale * -1
                t:setReferencePoint(display.BottomRightReferencePoint)
            end
            if path[3] then
                t:scale(path[3], path[3])
            end
            t.x = w * i + spacer * i
            tiler:insert(t)
            tiler.children[i+1] = t
        end
        tiler.totalWidth = (w + spacer) * (numTiles + 1)
    elseif axis == "v" then
        vTiles[#vTiles+1] = tiler
        numTiles = ceil(screenHeight / h)

        for i=0, numTiles + 1 do
            t = newTile( path )
            t:setReferencePoint(display.CenterLeftReferencePoint)
            t.x, t.y = t.x + t.contentWidth, t.contentHeight*0.5+i*t.contentHeight + spacer * i
            if i % 2 == 1 then
                t.yScale = t.yScale * -1
                t:translate(0,t.contentHeight)
            end
            tiler:insert(t)
            tiler.children[i+1] = t
        end
    end

    tiler:setReferencePoint(display.BottomLeftReferencePoint)
    tiler.x, tiler.y = screenLeft, screenBottom

    Camera.add(tiler, depth, lock)

    tiler.position = function( x, y )
        tiler:translate(x,y)
        tiler.xInitial, tiler.yInitial = x, y
    end

    return tiler
end

Camera.resetTiles = function()

    local kids, amt = nil, nil

    for i=1, #hTiles do

        kids = hTiles[i].children
        amt = kids[1].x
        for j=1, #kids do
            kids[j]:translate(-amt, 0)
        end
    end

    for i=1, #vTiles do

        kids = vTiles[i].children
        amt = kids[1].y
        for j=1, #kids do
            kids[j]:translate(0,-amt)
        end
    end

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
        screen.X, screen.Y = screen.x, screen.y
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

    while #hTiles > 0 do
        tRemove(hTiles)
    end

    while #vTiles > 0 do
        tRemove(vTiles)
    end

    while #Stages > 0 do
        display.remove(tRemove(Stages))
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

Camera.getStage = function(depth)
    if depth then
        for i=1, #Stages do
            if Stages[i].depth == depth then
                return Stages[i]
            end
        end
    else
        return StageHolder
    end
end

Camera.running = function()
    return Running
end

return Camera
