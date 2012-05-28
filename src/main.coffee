{$, $number, $function, $string, $object, types} = (if typeof window == 'undefined' then (require "./types").Types else this.Types)

SIZE = 20 #size of a tile.
SCREEN_WIDTH  = 500
SCREEN_HEIGHT = 500
MAP_WIDTH  = SIZE * 20
MAP_HEIGHT = SIZE * 20
SCREEN = new Fathom.Rect(0, 0, MAP_WIDTH)

Key = Fathom.Key
U = Fathom.Util

class Character extends Fathom.Entity
  constructor: (x, y, map) ->
    types Number, Number, Fathom.Map
    super x, y, SIZE

    @vx = @vy = 0
    @speed = 4

    @direction = new Fathom.Vector(1, 0)
    @on "pre-update", Fathom.BasicHooks.rpgLike(5, this)
    @on "pre-update", Fathom.BasicHooks.decel this

    @on "pre-update", Fathom.BasicHooks.onLeaveMap(this, map, @onLeaveScreen)
    @on "pre-update", Fathom.BasicHooks.onCollide @, "item", @pickupItem

    @on "post-update", Fathom.BasicHooks.resolveCollisions @

  pickupItem: (item) ->
    item.die()
    console.log "item get!"

  onLeaveScreen: ->
    dx = Math.floor(@x / map.width)
    dy = Math.floor(@y / map.height)

    @x -= dx * map.width
    @y -= dy * map.height

    map.setCorner(new Fathom.Vector(dx, dy))

    cam.snap()

  groups: ->
    ["renderable", "updateable", "character"]

  render: (context) ->
    context.fillStyle = "#0f0"
    context.fillRect @x, @y, @width, @height

  shoot: () ->
    new Bullet(@x, @y, @direction)

  update: () ->
    if U.movementVector().nonzero()
      @direction = U.movementVector()
    @shoot() if Key.isDown(Key.X)

  depth : -> 1

class Item extends Fathom.Entity
  constructor: (@x, @y) -> super x, y, 20, 20, "#0aa"
  depth: -> 15
  groups: -> ["renderable", "updateable", "item"]

class Enemy extends Fathom.Entity
  constructor: (@x, @y) ->
    @destination = new Fathom.Point(@x, @y)

    @health = 5
    super x, y, 20

  depth: -> 5

  hurt: (dmg) ->
    @health -= dmg
    if @health < 0
      @die()

  groups: -> ["renderable", "updateable", "enemy"]

  update: () ->
    if @close(@destination) or (@entities().one "map").collides(@destination.toRect(20)) or (not SCREEN.touchingPoint @destination)
      @destination = new Fathom.Point(@x, @y) #@point()
      @destination.add((new Fathom.Vector()).randomize().multiply(20))
    @add(@destination.subtract(@).normalize())

  render: (context) ->
    context.fillStyle = "#fff "
    context.fillRect @x, @y, @width, @height

class Bullet extends Fathom.Entity
  constructor: (@x, @y, direction) ->
    types Number, Number, Fathom.Vector
    super x, y, 10

    @speed = 10
    @direction = direction.normalize().multiply(@speed)

    @on "pre-update", Fathom.BasicHooks.move(@, @direction)
    @on "post-update", Fathom.BasicHooks.onCollide @, "wall", => @die()
    @on "post-update", Fathom.BasicHooks.onCollide @, "enemy", (e) => e.hurt(1); @die()
    @on "post-update", Fathom.BasicHooks.onLeaveMap(this, map, @die)

  groups: -> ["renderable", "updateable", "bullet"]
  update: () ->
  depth: -> 5
  collides: -> false

  render: (context) ->
    context.fillStyle = "#222"
    context.fillRect @x, @y, @width, @height

class FPSText extends Fathom.Text
  constructor: (args...) ->
    super(args...)
    @dontAdjust = true
  update: () -> @text = Fathom.getFPS().toString().substring(0, 4)
  depth: -> 12
  groups: -> ["renderable", "updateable"]

map = new Fathom.Map(40, 40, 20)
map.fromImage("static/map.png", new Fathom.Vector(0, 0), -> )

character = new Character(40, 40, map)
enemy = new Enemy(80, 80)
fps = new FPSText("")
bar = new Fathom.FollowBar character, 50, 50
cam = new Fathom.FollowCam(character, -40, -40, MAP_WIDTH, MAP_HEIGHT)
i1 = new Item(120, 120)
i2 = new Item(80, 120)

gameLoop = (context) ->

Fathom.initialize gameLoop, "main"
