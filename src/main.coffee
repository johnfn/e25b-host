SIZE = 20 #size of a tile.
SCREEN_WIDTH = 500
SCREEN_HEIGHT = 500

all_entities = new Fathom.Entities

class Character extends Fathom.Entity
  constructor: (x, y) ->
    types $number, $number
    super x, y, SIZE

    @vx = @vy = 0
    @speed = 4

    @on "pre-update", Fathom.BasicHooks.rpgLike(5, this)
    @on "post-update", Fathom.BasicHooks.decel this

  groups: ->
    ["renderable", "updateable"]

  render: (context) ->
    context.fillStyle = "#0f0"
    context.fillRect @x, @y, @size, @size

  update: (entities) ->
    types $("Entities")
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
  constructor: (x, y) ->
    types $number, $number
    super x, y, 10

    @direction = new Fathom.Point(10, 0)
    @on "pre-update", Fathom.BasicHooks.moveForward(this, @direction)

  groups: -> ["renderable", "updateable", "bullet"]

  update: (entities) ->
    types $("Entities")
    Fathom.BasicHooks.dieAtWall(this, entities)()
    Fathom.BasicHooks.dieOffScreen(this, SCREEN_WIDTH, SCREEN_HEIGHT, entities)()

  depth: -> 5

  render: (context) ->
    context.fillStyle = "#222"
    context.fillRect @x, @y, @size, @size

character = new Character(20, 20)

## build map

map = new Fathom.Map(10, 10, 20)

#for x in [0...10]
#  for y in [0...10]
#    map.setTile(x, y, if x == 8 then 1 else 0)

all_entities.add character
all_entities.add map
all_entities.add (new Bullet(10, 10))

a = false

gameLoop = (context) ->
  if not a
    map.fromImage("static/map.png")
    a = true

  all_entities.update all_entities
  all_entities.render context

Fathom.initialize gameLoop, "main"
