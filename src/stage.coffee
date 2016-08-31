Util = require('./util').Util
IDGenerator = require('./id').IDGenerator

module.exports.Stage = class Stage
  constructor: (@canvas) ->
    if not @canvas?
      throw new Error('must specify a canvas')

    @bindEvent()

    @layers = []

    @idGenerator = new IDGenerator

  addLayer: (layer) ->
    @layers.push layer
    @redraw()
    return this

  addLayerBefore: (layer, before) ->
    Util.aInsertBefore @layers, layer, before
    @redraw()
    return this

  addLayerAfter: (layer, after) ->
    Util.aInsertAfter @layers, layer, after
    @redraw()
    return this

  removeLayer: (layer) ->
    Util.aRemoveEqual @layers, layer
    @redraw()
    return this

  clearLayers: ->
    @layers = []
    @redraw()
    return this

  bindEvent: ->
    @canvas.on 'click', (evt) =>
      @broadcastMouseEvent evt

  _walkLayers: (layers, cb, depth = 0) ->
    if depth > 100
      return

    for layer in layers
      cb layer, depth
      if layer.children.length > 0
        @_walkLayers layer.children, cb, depth++

  walkLayers: (cb) ->
    @_walkLayers @layers, cb

  broadcastMouseEvent: (evt) ->
    fulfilled = []
    @walkLayers (layer) ->
      if layer.containPoint evt.x, evt.y
        fulfilled.push layer

    fulfilled.sort (a, b) ->
      return b.id - a.id

    fulfilled.every (layer) ->
      listeners = layer.listenersOf evt.name
      bubbling = false
      listeners.forEach (listener) ->
        bubbling = (listener.call layer, evt.name, evt) ? false
      return bubbling isnt false

  _draw: ->
    for layer in @layers
      layer.stage = this
      layer.ctx = @canvas.ctx
      layer.draw()

  redraw: ->
    @canvas.clear()
    @canvas.currentStage = this
    @idGenerator.reset()
    @_draw()
    return this
