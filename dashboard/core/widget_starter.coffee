###

  Widget starter is the Mozaic component managing the relationship
  between in-memory widgets and the DOM. In principle, it listens to
  changes of the DOM (widgets added/removed) and reacts intelligently to them.
  I will denote these two types of processes by the terms "spawn" and "GC".

  Changes to the DOM are detected through the preferred method available
  on the client's browser. The faster, the more preferred :)
  In the order of preference, the methods we use are:
  - mutation observers
  - DOM mutation events
  - polling (for those browsers written in Redmond :P)

  spawning
  ========
  TODO: explain it.

###

define ['cs!mozaic_module', 'cs!pubsub'], (Module) ->
    checkDOMInterval = 200
    class WidgetStarter extends Module
        ###
            Monitors the DOM for the appearance of new widgets.
            Loads them up whenever they appear.
            When new widgets are marked as delayed (i.e with Constanst.DELAY_WIDGET class)
            the starter delayes their execution untill the class is removed.

            waiting_list: dictionary of channels, every value
                is a list of widgets neededing that channel to become available
            widgets: dictionary of widgets that still need some channels`
            channels: dictionary which retains available channels
        ###

        waiting_list: {}
        widgets: {}
        channels: {}
        widgets_for_gc: []
        widgets_for_urgent_gc: [] # Widgets with priority for GC
        destroyed_widgets: {} # A hash with the ids of destroyed widgets

        garbageCollectionInterval: 10000
        garbageCollectionBatchSize: 30

        constructor: ->
            super()
            pipe = loader.get_module('pubsub')
            pipe.subscribe('/initialized_channel', (channel) =>
                # Make widget starter aware of incoming channels
                channel = channel.name
                @channels[channel] = true

                if not @waiting_list[channel] then @waiting_list[channel] = []
                # Consume widgets which are waiting on this channel
                while  (widget = @waiting_list[channel].shift())
                    @widgets[widget].unitialized_channels -= 1
                    if @widgets[widget].unitialized_channels == 0
                        @loadWidget(@widgets[widget].params)
                        delete @widgets[widget]
            )


        wasDelayedNode: (mutation) ->
            ###
            # Checks if the mutation object passed as argument is caused by the removal of class.
            # Handles both MutationEvents and MutationObserver objects.
            # @param {Object} mutation MutationEvent | MutationRecord depending on source.
            # @return {Boolean}
            # @reference http://www.w3.org/TR/dom/#mutation-observers
            # @reference http://www.w3.org/TR/DOM-Level-3-Events/#events-mutationevents
            ###

            isMutationRecord =
                mutation.type is 'attributes' and
                mutation.attributeName is 'class' and
                mutation.target?.className?.indexOf('mozaic-widget') isnt -1 and # Must be widget.
                mutation.oldValue?.indexOf(Constants.DELAY_WIDGET) isnt -1 and # Should have been delayed
                mutation.target?.className?.indexOf(Constants.DELAY_WIDGET) is -1 # Should not be delayed anymore

            isMutationEvent = # for DOM Mutation Events
                mutation.attrChange is 1 and # MODIFICATION type change.
                mutation.attrName is 'class' and # Changed attr should be a class.
                mutation.newValue?.indexOf('mozaic-widget') isnt -1 and # Element should be a widget.
                mutation.newValue?.indexOf(Constants.DELAY_WIDGET) is -1 and # Element should no longer be delayed.
                mutation.prevValue?.indexOf(Constants.DELAY_WIDGET) isnt -1 # Element was previously marked as delayed.

            return isMutationRecord or isMutationEvent

        initialize: =>

            setTimeout(@garbageCollectWidgets, @garbageCollectionInterval)

            MutationObserver = window.MutationObserver or window.WebKitMutationObserver or window.MozMutationObserver

            if MutationObserver
                observer = new MutationObserver (mutations) =>
                    for mutation in mutations
                        @checkInsertedNode $ node for node in mutation.addedNodes if mutation.addedNodes?
                        @checkRemovedNode $ node for node in mutation.removedNodes if mutation.removedNodes?
                        # Check nodes that previously had Constants.DELAY_WIDGET class and now it's been removed by FoldedController
                        @checkInsertedNode $ mutation.target if @wasDelayedNode mutation
                    return false

                observer.observe document,
                    childList: true
                    subtree: true
                    attributes: true # Listen for attribute changes as well.
                    attributeOldValue: true # Pass in the old attribute value, we need it to check if it had Constants.DELAY_WIDGET class.
                    attributeFilter: ['class'] # Pass only class attribute changes

            else if document.addEventListener?
                document.addEventListener "DOMNodeInserted", (e) =>
                    @checkInsertedNode $ e.target

                document.addEventListener "DOMNodeRemoved", (e) =>
                    @checkRemovedNode $ e.target

                # Listen for attribute changes and filter them by class and Constants.DELAY_WIDGET
                document.addEventListener "DOMAttrModified", (e) =>
                    @checkInsertedNode $ e.target if @wasDelayedNode e

            else # e.g IE7, IE8 -> use setInterval technique for checking the DOM at certain intervals
                # Right now, it doesn't know when DOM elements are removed to garbage collect them
                # Also, it doesn't use a setInterval, but rather a recursive Timeout after the inner
                # execution has finished. Since the functions from checkDOM will be called very
                # frequently, for performance issues the fat arrow is not used anymore
                initializeWidget = @initializeWidget
                checkDOM = ->
                    $('.mozaic-widget').each (idx, el) ->
                        $el = $(el)
                        # Do nothing if the widget is either already initialized or delayed
                        if $el.hasClass('mozaic-initialized') or $el.hasClass(Constants.DELAY_WIDGET)
                            return

                        setTimeout ->
                                initializeWidget $el
                            , 0

                    setTimeout ->
                            checkDOM()
                        , checkDOMInterval

                checkDOM()

        checkInsertedNode: ($el) ->
            ###
                Checks to see the which type of element is the newly
                iserted node. If it is an injected widget, then initialize
                it
            ###

            list = []
            # If the current element is an mozaic-widget but it's not delayed.
            if $el.hasClass('mozaic-widget') and not $el.hasClass(Constants.DELAY_WIDGET)
                list.push($el)
            # Find all its children widgets and turn the pseudo-list
            # returned by the jQuery API into a real list. Filter out delayed widgets.
            $inserted_elements = $el.find(".mozaic-widget").not(".#{Constants.DELAY_WIDGET}")
            list.push(element) for element in $inserted_elements

            # Initialize all the widgets by calling setTimeout(0)
            return @initializeNewWidgets(list)

        checkRemovedNode: ($el) ->
            markForGarbageCollection = @markForGarbageCollection
            # If the removed element is a widget, garbage collect it.
            # Be careful, some widgets are removed from the DOM
            # before they have the chance to be initialized. Thus,
            # they don't have a GUID yet, and nothing must be done.
            if $el.hasClass('mozaic-widget')
                markForGarbageCollection($el)
            # Find all its children widgets and garbage collect them
            $el.find('.mozaic-widget').each (idx, el) ->
                markForGarbageCollection(el)

            false

        markForGarbageCollection: (el) =>
            ###
                Marks a DOM element containing a widget (can be either
                initialized or uninitialized) as ready for garbage collection.

                This has two consequences: first, the widget is put into a
                garbage collection queue which will eventually garbage collect
                all their internal references and also unbind them from events.
                But this is an expensive operation and we need an easy way out
                until we stop receiving events (a detached widget will not
                receive any DOM events but only data events). Therefore,
                the second consequence is the setting of a flag for that widget
                which will immediately cause it to start ignoring data events.
            ###
            guid = $(el).data('guid')
            return unless guid or @destroyed_widgets[guid]

            # First mark it as detached
            loader.mark_as_detached(guid)

            # And afterwards put it in the garbage collection queue.
            #
            # Check if this is a widget with priority for GC, and if yes,
            # add it to the priority queue instead of the normal one.
            if $(el).hasClass('urgent_for_gc')
                @widgets_for_urgent_gc.push(guid)
            else
                @widgets_for_gc.push(guid)

        initializeNewWidgets: (list) =>
            ###
                Function for initializing the new widgets.

                The difference between this and a plain old for is that
                tries hard to let the rendering threads take what's theirs
                by calling setTimeout(0) for each step of the iteration.

                Initialilly, this function was recursive. Because of the
                maximum call stack error when reimplementing the system for
                IE7, it has been refactored to be non-recursive and use a
                setTimeout(0) instead
            ###

            while widget = list.shift()
                do (widget) =>
                    setTimeout =>
                            @initializeWidget $(widget)
                        , 0


        startWidget: (params) =>
            ###
                Checks if a widget can be started.
                The main reason for which widgets can't be started is that
                the datasource hasn't initialized all the data channels
                they are subscribed to.
            ###

            # No subscribed channels means no obligations :-)
            if not ('channels' of params)
                @loadWidget(params)
                return true

            unitialized_channels = _.keys(params.channels).length
            id = params.widget_id

            # See how many of widget channels are available and put
            # widget on a waiting list for uninitialized channels
            for k, v of params.channels
                if !@channels[v]?
                    if !@waiting_list[v]?
                        @waiting_list[v] = [id]
                    else
                        @waiting_list[v].push(id)
                else
                    unitialized_channels -= 1

            # If widget has all channels already initialize,
            if unitialized_channels == 0
                @loadWidget(params)
                return

            @widgets[id] =
                unitialized_channels: unitialized_channels
                params: params

        loadWidget: (params) =>
            loader.load_widget(params.name, params.widget_id, params)

        initializeWidget: ($el) =>
            if $el.hasClass('mozaic-initialized')
                return false
            # First thing, mark the widget as initialized
            $el.addClass('mozaic-initialized')

            # Generate a unique GUID as an id for the widget.
            widget_id = _.uniqueId('widget-')

            name = $el.data('widget')

            # Write the GUID to the DOM so that for debugging purposes
            $el.attr('data-guid', widget_id)

            # Extract widget initialization parameters from the DOM
            params = $.parseJSON($el.attr('data-params')) or {}
            params['el'] = $el
            params['name'] = name
            params['widget_id'] = widget_id

            $el.addClass("widget-#{name}")

            # Start the widget
            @startWidget(params)

        garbageCollectWidgets: () =>
            ###
                Destroy all widgets marked as garbage collected
            ###
            # On each GC round, the widgets to destroy are:
            # 1) all the URGENT widgets to GC
            # 2) if the number of widgets at 1) doesn't surpass the GC
            #     batch size, some more 'normal' widgets
            widgets_to_destroy = @widgets_for_urgent_gc
            @widgets_for_urgent_gc = []
            if widgets_to_destroy.length < @garbageCollectionBatchSize and @widgets_for_gc.length > 0
                # Compute how many widgets we need to complete this round
                still_need = @garbageCollectionBatchSize - widgets_to_destroy.length
                # Make sure we don't need too many - only GC what is available
                still_need = Math.min(still_need, @widgets_for_gc.length)
                # Extract the remainder of this batch ..
                batch_remainder = @widgets_for_gc.splice(0, still_need)
                # .. and append it to the list of urgent widgets
                widgets_to_destroy = widgets_to_destroy.concat(batch_remainder)

            # For each widget to be destroyed, mark it as such and
            # destroy it without any doubt :)
            while widget_id = widgets_to_destroy.shift()
                if not @destroyed_widgets[widget_id]
                    loader.destroy_widget(widget_id)
                    @destroyed_widgets[widget_id] = true

            # Also made a periodically check in case some widgets were destroyed
            # within the same controller, without changing it
            setTimeout(@garbageCollectWidgets, @garbageCollectionInterval)

    return WidgetStarter
