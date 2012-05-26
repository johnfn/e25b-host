{$, $number, $function, $string, $object, types} = (if typeof window == 'undefined' then (require "./types").Types else this.Types)

SIZE = 20 #size of a tile.
SCREEN_WIDTH  = 500
SCREEN_HEIGHT = 500
MAP_WIDTH  = SIZE * 20
MAP_HEIGHT = SIZE * 20

Key = Fathom.Key
U = Fathom.Util

map = new Fathom.Map(20, 20, 20)

class Character extends Fathom.Entity
  constructor: (x, y) ->
    types $number, $number
    super x, y, SIZE

    @vx = @vy = 0
    @speed = 4

    @direction = new Fathom.Vector(1, 0)
    @on "pre-update", Fathom.BasicHooks.rpgLike(5, this)
    @on "post-update", Fathom.BasicHooks.decel this
    @on "post-update", Fathom.BasicHooks.onLeaveScreen(this, MAP_WIDTH, MAP_HEIGHT, @onLeaveScreen)

  onLeaveScreen: ->
    dx = Math.floor(@x / MAP_WIDTH)
    dy = Math.floor(@y / MAP_WIDTH)

    @x -= dx * MAP_WIDTH
    @y -= dy * MAP_WIDTH

    map.setCorner(new Fathom.Vector(dx, dy))

  groups: ->
    ["renderable", "updateable"]

  render: (context) ->
    context.fillStyle = "#0f0"
    context.fillRect @x, @y, @size, @size

  shoot: () ->
    new Bullet(@x, @y, @direction)

  update: () ->
    if U.movementVector().nonzero()
      @direction = U.movementVector()

    @shoot() if Key.isDown(Key.X)

    @x += @vx
    #TODO.
    if @__fathom.entities.any [(other) => other.collides(this)]
      @x -= @vx
      @vx = 0

    @y += @vy
    if @__fathom.entities.any [(other) => other.collides(this)]
      @y -= @vy
      @vy = 0

  depth : -> 1

class Enemy extends Fathom.Entity
  constructor: (@x, @y) ->
    @health = 5
    super x, y, 20

  depth: -> 5

  hurt: (dmg) ->
    @health -= dmg
    if @health < 0
      @die()

  groups: -> ["renderable", "updateable", "enemy"]

  update: () ->

  render: (context) ->
    context.fillStyle = "#fff"
    context.fillRect @x, @y, @size, @size

class Bullet extends Fathom.Entity
  constructor: (@x, @y, direction) ->
    types $number, $number, $("Vector")
    super x, y, 10

    @speed = 10
    @direction = direction.normalize().multiply(@speed)

    @on "pre-update", Fathom.BasicHooks.move(@, @direction)
    @on "post-update", Fathom.BasicHooks.onCollide @, "wall", => @die()
    @on "post-update", Fathom.BasicHooks.onCollide @, "enemy", (e) => e.hurt(1); @die()
    @on "post-update", Fathom.BasicHooks.onLeaveScreen @, SCREEN_WIDTH, SCREEN_HEIGHT, => @die()

  groups: -> ["renderable", "updateable", "bullet"]

  update: () ->

  depth: -> 5

  collides: -> false

  render: (context) ->
    context.fillStyle = "#222"
    context.fillRect @x, @y, @size, @size

character = new Character(20, 20)
enemy = new Enemy(80, 80)

loadedMap = false

gameLoop = (context) ->
  if not loadedMap
    map.fromImage("static/map.png", new Fathom.Vector(0, 0), -> )
    loadedMap = true

Fathom.initialize gameLoop, "main"
