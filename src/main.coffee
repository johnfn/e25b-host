"use strict"

SIZE = 20 #size of a tile.

all_entities = new Fathom.Entities

class Character extends Fathom.Entity
  constructor : (x, y) ->
    super x, y, SIZE

    @vx = @vy = 0
    @speed = 4

    @on "post-update", Fathom.BasicHooks.decel this

  groups : ->
    ["renderable", "updateable"]

  render: (context) ->
    context.fillStyle = "#0f0"
    context.fillRect @x, @y, @size, @size

  update: (entities) ->
    Fathom.BasicHooks.rpgLike(5, this)()

    @x += @vx

    if entities.any ["wall", ((other) => other.collides(this))]
      @x -= @vx
      @vx = 0

    @y += @vy
    if entities.any ["wall", ((other) => other.collides(this))]
      @y -= @vy
      @vy = 0

  depth : -> 1

character = new Character(20, 20)

## build map

map = new Fathom.Map(10, 10, 20)

for x in [0...10]
  for y in [0...10]
    map.setTile(x, y, if x == 8 then 1 else 0)

all_entities.add character
all_entities.add map

gameLoop = (context) ->
  all_entities.update all_entities
  all_entities.render context

Fathom.initialize gameLoop, "main"
