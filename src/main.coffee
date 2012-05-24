SIZE = 20 #size of a tile.
SCREEN_WIDTH = 500
SCREEN_HEIGHT = 500

Key = Fathom.Key
U = Fathom.Util

all_entities = new Fathom.Entities

class Character extends Fathom.Entity
  constructor: (x, y) ->
    types $number, $number
    super x, y, SIZE

    @vx = @vy = 0
    @speed = 4

    @direction = new Fathom.Vector(1, 0)
    @on "pre-update", Fathom.BasicHooks.rpgLike(5, this)
    @on "post-update", Fathom.BasicHooks.decel this

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

class Bullet extends Fathom.Entity
  constructor: (@x, @y, direction, entities) ->
    types $number, $number, $("Vector"), $("Entities")
    super x, y, 10

    @speed = 10
    @direction = direction.normalize().multiply(@speed)

    @on "pre-update", Fathom.BasicHooks.moveForward(this, @direction)
    @on "post-update", Fathom.BasicHooks.dieAtWall(this, entities)
    @on "post-update", Fathom.BasicHooks.dieOffScreen(this, SCREEN_WIDTH, SCREEN_HEIGHT, entities)

  groups: -> ["renderable", "updateable", "bullet"]

  update: (entities) ->
    types $("Entities")

  depth: -> 5

  render: (context) ->
    context.fillStyle = "#222"
    context.fillRect @x, @y, @size, @size

character = new Character(20, 20)

## build map

map = new Fathom.Map(10, 10, 20)

all_entities.add character
all_entities.add map

loadedMap = false

gameLoop = (context) ->
  if not loadedMap
    map.fromImage("static/map.png")
    loadedMap = true

  all_entities.update all_entities
  all_entities.render context

Fathom.initialize gameLoop, "main"
