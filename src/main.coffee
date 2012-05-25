{$, $number, $function, $string, $object, types} = (if typeof window == 'undefined' then (require "./types").Types else this.Types)

SIZE = 20 #size of a tile.
SCREEN_WIDTH  = 500
SCREEN_HEIGHT = 500
MAP_WIDTH  = SIZE * 20
MAP_HEIGHT = SIZE * 20

Key = Fathom.Key
U = Fathom.Util

all_entities = new Fathom.Entities
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

  shoot: (entities) ->
    types $("Entities")
    entities.add(new Bullet(@x, @y, @direction, all_entities))

  update: (entities) ->
    types $("Entities")

    if U.movementVector().nonzero()
      @direction = U.movementVector()

    @shoot(entities) if Key.isDown(Key.X)

    @x += @vx
    if entities.any [(other) => other.collides(this)]
      @x -= @vx
      @vx = 0

    @y += @vy
    if entities.any [(other) => other.collides(this)]
      @y -= @vy
      @vy = 0

  depth : -> 1

class Enemy extends Fathom.Entity
  constructor: (@x, @y, entities) ->
    @health = 5
    super x, y, 20

  depth: -> 5

  hurt: (dmg) ->
    @health -= dmg
    if @health < 0
      @die()

  groups: -> ["renderable", "updateable", "enemy"]

  update: (entities) ->

  render: (context) ->
    context.fillStyle = "#fff"
    context.fillRect @x, @y, @size, @size

class Bullet extends Fathom.Entity
  constructor: (@x, @y, direction, entities) ->
    types $number, $number, $("Vector"), $("Entities")
    super x, y, 10

    @speed = 10
    @direction = direction.normalize().multiply(@speed)

    @on "pre-update", Fathom.BasicHooks.move(@, @direction)
    @on "post-update", Fathom.BasicHooks.onCollide @, entities, "wall", => @die()
    @on "post-update", Fathom.BasicHooks.onCollide @, entities, "enemy", (e) => e.hurt(1); @die()
    @on "post-update", Fathom.BasicHooks.onLeaveScreen @, SCREEN_WIDTH, SCREEN_HEIGHT, => @die()

  groups: -> ["renderable", "updateable", "bullet"]

  update: (entities) ->
    types $("Entities")

  depth: -> 5

  collides: -> false

  render: (context) ->
    context.fillStyle = "#222"
    context.fillRect @x, @y, @size, @size

character = new Character(20, 20)
enemy = new Enemy(80, 80)

all_entities.add character
all_entities.add enemy
all_entities.add map

loadedMap = false

gameLoop = (context) ->
  if not loadedMap
    map.fromImage("static/map.png", new Fathom.Vector(0, 0), -> )
    loadedMap = true

  all_entities.update all_entities
  all_entities.render context

Fathom.initialize gameLoop, all_entities, "main"
