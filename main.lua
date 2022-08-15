function love.load()

    love.window.setMode(1920, 1080, {borderless=true})

    love.graphics.setDefaultFilter("nearest", "nearest")
    anim8 = require "/libraries/anim8"
    wf = require "/libraries/windfield/windfield"
    sti = require "/libraries/Simple-Tiled-Implementation/sti"

    world = wf.newWorld(0, 800, false)
    world:setQueryDebugDrawing(true)

    world:addCollisionClass("Tiles")
    world:addCollisionClass("Player")
    world:addCollisionClass("Pit")

    sprites = {}
    sprites.playerSheet = love.graphics.newImage("/sprites/wayne/wayne.dds")
    local playerGrid = anim8.newGrid(120, 120, sprites.playerSheet:getWidth(), sprites.playerSheet:getHeight())

    animations = {}
    animations.idle = anim8.newAnimation(playerGrid("1-1", 3), 1)
    animations.walk = anim8.newAnimation(playerGrid("1-2", 1), 0.15)
    animations.run = anim8.newAnimation(playerGrid("1-4", 2), 0.08)
    animations.jump = anim8.newAnimation(playerGrid("1-1", 4), 0.05)

    player = {}
    player = world:newRectangleCollider(360, 100, 40, 80, {collision_class = "Player"})
    player.speed = 180
    player:setFixedRotation(true) 
    player.animation = animations.idle
    player.isMoving = false
    player.isJumping = false
    player.isFalling = false
    player.isRunning = false
    player.direction = 1
    
    keybinds = {
        jump = "w",
        moveRight = "d",
        moveLeft = "a",
        running = "lshift"
    }

    deathZone = world:newRectangleCollider(0, 1080, 1920, 20, {collision_class = "Pit"})

    platforms = {}

    -- Defining the jumping.

    function love.keypressed(key)
        if key == keybinds.jump then
            local colliders = world:queryRectangleArea(player:getX() - 40, player:getY() + 45, 80, 1)
            if #colliders > 0 then
                player:applyLinearImpulse(0, -1500)
                player.isFalling = true
            end
        end
    end
    loadLevel()
end

-- Everything that will be updated every frame.

function love.update(dt)
    world:update(dt)
    level:update(dt)
    animations.idle:update(dt)
    animations.run:update(dt)
    animations.walk:update(dt)
    animations.jump:update(dt)
    
    if player.body then
        player.isMoving = false
        px, py = player:getPosition()
        if love.keyboard.isDown(keybinds.moveRight) then
            player:setX(px + player.speed*dt)
            player.isMoving = true
            player.direction = 1
        end
        if love.keyboard.isDown(keybinds.moveLeft) then
            player:setX(px - player.speed*dt)
            player.isMoving = true
            player.direction = -1
        end
        deathZone:setType("static")
        if player:enter("Pit") then
            player:destroy()
        end
    end

    -- If the player holds down the running button, this function will be called.

    player.isRunning = false
    if love.keyboard.isDown(keybinds.running) then
        player.speed = 300
        player.isRunning = true
    end

    -- Defining the ground animations

    if player.isRunning == true and player.isMoving == false then
        player.animation = animations.idle
    elseif player.isRunning then
        player.animation = animations.run
    elseif player.isMoving then
        player.animation = animations.walk
    else
        player.animation = animations.idle
    end

    player.animation:update(dt)
end

function loadLevel()
    level = sti("levels//testing/test1/test1.lua")
    for i, obj in pairs(level.layers["platforms"].objects) do
        spawningPlatforms(obj.x, obj.y, obj.width, obj.height) 
    end
end

function spawningPlatforms(x, y, width, height)
    if width > 0 and height > 0 then
        local tiles = world:newRectangleCollider(x, y, width, height, {collision_class = "Tiles"})
        tiles:setType("static")
        table.insert(platforms, tiles)
    end
end

function love.draw()
    love.graphics.setBackgroundColor(0, 0, 0, 1)
    world:draw()
    level:drawLayer(level.layers["tiles"])
    player.animation:draw(sprites.playerSheet, px, py, nil, 1 * player.direction, 1, 25, 80)
end