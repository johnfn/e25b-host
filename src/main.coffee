SIZE = 20 #size of a tile.
SCREEN_WIDTH  = 500
SCREEN_HEIGHT = 500
MAP_WIDTH  = SIZE * 20
MAP_HEIGHT = SIZE * 20
SCREEN = new Fathom.Rect(0, 0, MAP_WIDTH)

Key = Fathom.Key
U = Fathom.Util

refreshItems = () ->
  console.log character.items[0].disp()
  $("#item-list").html("" + (i.getRepr() for i in character.items).join(""))

  dropEvent = (event, ui) ->
    $(this).children("ul").prepend($(ui.draggable).css('left', '').css('top', ''))

  dropNotPlasmid = (event, ui) ->
    $(this).after($(ui.draggable).css('left', '').css('top', ''))

  $(".not-plasmid").draggable()
  $(".not-plasmid").droppable(drop: dropNotPlasmid, greedy: true, hoverClass: "not-plasmid-hover")
  $(".plasmid").droppable(drop: dropEvent, hoverClass: "plasmid-hover")
  $("#container-left").droppable(drop: dropEvent, hoverClass: "plasmid-hover")

class Character extends Fathom.Entity
  constructor: (x, y, map) ->
    super x, y, SIZE, SIZE, "#0f0"

    @vx = @vy = 0
    @speed = 4
    @items = []
    @direction = new Fathom.Vector(1, 0)

    @on "pre-update", Fathom.BasicHooks.decel()
    @on "pre-update", Fathom.BasicHooks.rpgLike(5)

    @on "pre-update", Fathom.BasicHooks.onLeaveMap(this, map, @onLeaveScreen)
    @on "pre-update", Fathom.BasicHooks.onCollide "item", @pickupItem

    @on "post-update", Fathom.BasicHooks.resolveCollisions()

  pickupItem: (item) ->
    @items.push(new InventoryItem(item))
    item.die()
    refreshItems()

  onLeaveScreen: ->
    dx = Math.floor(@x / map.width)
    dy = Math.floor(@y / map.height)

    @x -= dx * map.width
    @y -= dy * map.height

    map.setCorner(new Fathom.Vector(dx, dy))

    cam.snap()

  groups: ->
    ["renderable", "updateable", "character"]

  shoot: () ->
    if Fathom.Tick.ticks % 4 == 0
      new Bullet(@x, @y, @direction)

  update: () ->
    if U.movementVector().nonzero()
      @direction = U.movementVector()
    @shoot() if Key.isDown(Key.X)

  depth : -> 1

class InventoryItem
  constructor: (groundItem) ->
    @type = groundItem.type

  getRepr: () ->
    if @type == "Plasmid"
      "<li class='plasmid'><a href='javascript:#{@disp()}'>#{@getDesc()}</a><input type='button' value='Build!'></input><ul class='plasmid-append'></ul></li>"
    else
      "<li class='not-plasmid'><a href='javascript:#{@disp()}'>#{@getDesc()}</a></li>"

  getDesc: () ->
    @type

  longDesc: () ->
    switch @type
      when "Plasmid"
        "<div><b>Plasmid:</b></div>A circular string of DNA helpful for creating new molecules."
      else
        @type

  disp: () ->
    "$(\"#desc\").html(\"#{@longDesc()}\")"

class GroundItem extends Fathom.Entity
  constructor: (@x, @y, @type=U.randElem(["1", "2", "3"])) ->
    @description = "This is a longer description. Go go go."
    @color = U.randElem(["#0ff","#0f0","#00f","#fff"])
    super x, y, 20, 20, "#0aa"
  depth: -> 15
  groups: -> ["renderable", "updateable", "item"]

class Enemy extends Fathom.Entity
  constructor: (@x, @y) ->
    @destination = new Fathom.Point(@x, @y)

    @health = 5
    super x, y, 20, 20, "#000"

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

class Bullet extends Fathom.Entity
  constructor: (@x, @y, direction) ->
    super x, y, 10

    @speed = 10
    @direction = direction.normalize().multiply(@speed)

    @on "pre-update", Fathom.BasicHooks.move(@direction)
    @on "post-update", Fathom.BasicHooks.onCollide "wall", => @die()
    @on "post-update", Fathom.BasicHooks.onCollide "enemy", (e) => e.hurt(1); @die()
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
i1 = new GroundItem(120, 120)
i2 = new GroundItem(80, 120)
i2 = new GroundItem(100, 120)
i2 = new GroundItem(100, 100)

character.pickupItem(new GroundItem(0, 0, "Plasmid"))
character.pickupItem(new GroundItem(0, 0, "Plasmid"))
character.pickupItem(new GroundItem(0, 0, "Plasmid"))

messages = ["Welcome to my cool e25b game!",
"Press the arrow keys to move around.",
"The world is full of monsters that you can genetically engineer molecules to fight against!",
"If you click on a monster, you can get some sense as to its weakness."
"Pick up items and drag them onto plasmids on the right toolbar, and then click Build to make a molecule.",
"Shoot the molecules you've made with X."]

$ ->
  refreshItems()

  $("#main").click (e) ->
    items = Fathom.mousePick(e.pageX, e.pageY)
    if items.length > 0
      $("#desc").html("You clicked on #{items[0]}.")
    else
      $("#desc").html("")

  $("#message-done").click (e) ->
    messages.shift()

  $("#hide-help").click (e) ->
    $("#help").toggle()

gameLoop = (context) ->
  if messages.length
    $("#message-content").html(messages[0])
    $("#message").show()
  else
    $("#message").hide()

Fathom.initialize gameLoop, "main"
