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

  $(".use").click (e) ->
    character.setWeapon $(this).parent().children("a").text()

  $(".build").click (e) ->
    # Grab plasmid names
    names = []
    $(this).parent().children("ul").children("li").children("a").each -> names.push($(this).text())

    contents = ["Cloning site", "Antibiotic resistance gene", "E. Coli origin of replication"]
    if contents[0] in names and contents[1] in names and contents[2] in names
      for itemName in contents
        character.removeItem(itemName)
      $(this).parent().remove()
      character.pickupItem(new GroundItem(0, 0, "Weakness thing.", true))

class Character extends Fathom.Entity
  constructor: (x, y, map) ->
    super x, y, SIZE, SIZE, "#0f0"

    @vx = @vy = 0
    @speed = 4
    @items = []
    @direction = new Fathom.Vector(1, 0)
    @weapon = "normal weapon"

    @on "pre-update", Fathom.BasicHooks.decel()
    @on "pre-update", Fathom.BasicHooks.rpgLike(5)

    @on "pre-update", Fathom.BasicHooks.onLeaveMap(this, map, @onLeaveScreen)
    @on "pre-update", Fathom.BasicHooks.onCollide "item", @pickupItem

    @on "post-update", Fathom.BasicHooks.resolveCollisions()

  setWeapon: (@weapon) ->
    @gunColor = U.randElem(["#0ff","#0f0","#00f","#fff"])

  pickupItem: (item) ->
    @items.push(new InventoryItem(item))
    item.die()
    refreshItems()

  itemList: () ->
    i.getDesc() for i in @items

  removeItem: (name) ->
    i = 0

    while i < @items.length
      if @items[i].getDesc() == name
        break
      i++

    @items.splice(i, 1)

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
      b = new Bullet(@x, @y, @direction, @gunColor)

  update: () ->
    if U.movementVector().nonzero()
      @direction = U.movementVector()
    @shoot() if Key.isDown(Key.X)

  depth : -> 1

ids = 0

class InventoryItem
  constructor: (groundItem) ->
    @type = groundItem.type
    @weapon = groundItem.weapon
    @id = ++ids

  getRepr: () ->
    if @type == "Plasmid"
      "<li class='plasmid'><a href='javascript:#{@disp()}'>#{@getDesc()}</a>
        <input class='build' id='#{@id}' type='button' value='Build!'></input>
        <ul class='plasmid-append'></ul></li>"
    else if @type == "Plasmid with cDNA"
      "<li class='plasmid'><a href='javascript:#{@disp()}'>#{@getDesc()}</a>
        <input class='build' id='#{@id}' type='button' value='Build!'></input>
        <ul class='plasmid-append'></ul></li>"
    else if @weapon
      "<li class='plasmid'><a href='javascript:#{@disp()}'>#{@getDesc()}</a>
        <input class='use' id='#{@id}' type='button' value='Use!'></input>
        <ul class='plasmid-append'></ul></li>"
    else
      "<li class='not-plasmid'><a href='javascript:#{@disp()}'>#{@getDesc()}</a></li>"

  getDesc: () ->
    @type

  longDesc: () ->
    switch @type
      when "Plasmid"
        "<div><b>Plasmid:</b></div>A circular string of DNA helpful for creating new molecules."
      when "Plasmid with cDNA"
        "<div><b>Plasmid with cDNA:</b></div>Similar to the Plasmid, this is a circular string of DNA helpful for creating new molecules. The crucial difference is that with the cDNA we can express eukaryotic genes."
      when "Biolistic bullets"
        "<div><b>Biolistic bullets:</b></div>These are pellets of metal, coated with the DNA you want to replicate. You can shoot them at plants: new plants will grow and take up the DNA that the bullets provide."
      else
        @type

  disp: () ->
    "$(\"#desc\").html(\"#{@longDesc()}\")"

class GroundItem extends Fathom.Entity
  constructor: (@x, @y, @type=U.randElem(["1", "2", "3"]), @weapon=false) ->
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

  describe: () ->


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
  constructor: (@x, @y, direction, @color="#000") ->
    super x, y, 10, 10, @color

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
new GroundItem(100, 80,  "Cloning site")
new GroundItem(100, 120, "Antibiotic resistance gene")
new GroundItem(100, 160, "E. Coli origin of replication")

character.pickupItem(new GroundItem(0, 0, "Plasmid"))
character.pickupItem(new GroundItem(0, 0, "Plasmid with cDNA"))
character.pickupItem(new GroundItem(0, 0, "Biolistic bullets", true))

messages = ["Welcome to my cool e25b game!",
"Press the arrow keys to move around.",
"The world is full of monsters that you can genetically engineer molecules to fight against!",
"You'll notice three items on the ground over there. Go pick them up."]

seenmoremessages = false
moremessages = ["Good! Now, on the right side, drag them all under the Plasmid.",
"This represents actually inserting these items into the plasmid in real life.",
"When you've done that, click Build."]

evenmoremsgs = false
evenmore = ["Nice!"]

$ ->
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

  refreshItems()

gameLoop = (context) ->
  # Picked up stuff?

  if not seenmoremessages
    yep = true

    contents = ["Cloning site", "Antibiotic resistance gene", "E. Coli origin of replication"]
    for c in contents
      if c not in character.itemList()
        yep = false
        break
    if yep
      seenmoremessages = true
      messages = moremessages

  # Show messages.
  $("#weapon").html(character.weapon)
  if messages.length
    $("#message-content").html(messages[0])
    $("#message").show()
  else
    $("#message").hide()

Fathom.initialize gameLoop, "main"
