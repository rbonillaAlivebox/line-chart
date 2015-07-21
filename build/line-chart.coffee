###
line-chart - v1.1.10 - 21 July 2015
https://github.com/n3-charts/line-chart
Copyright (c) 2015 n3-charts
###
# src/line-chart.coffee
old_m = angular.module('n3-charts.linechart', ['n3charts.utils'])
m = angular.module('n3-line-chart', ['n3charts.utils'])

directive = (name, conf) ->
  old_m.directive(name, conf)
  m.directive(name, conf)

directive('linechart', ['n3utils', '$window', '$timeout', (n3utils, $window, $timeout) ->
  link  = (scope, element, attrs, ctrl) ->
    _u = n3utils
    dispatch = _u.getEventDispatcher()
    id = _u.uuid()

    # Hacky hack so the chart doesn't grow in height when resizing...
    element[0].style['font-size'] = 0

    scope.redraw = ->
      scope.update()

      return

    isUpdatingOptions = false
    initialHandlers =
      onSeriesVisibilityChange: ({series, index, newVisibility}) ->
        scope.options.series[index].visible = newVisibility
        scope.$apply()

    scope.update = () ->
      options = _u.sanitizeOptions(scope.options, attrs.mode)
      handlers = angular.extend(initialHandlers, _u.getTooltipHandlers(options))
      dataPerSeries = _u.getDataPerSeries(scope.data, options)
      dimensions = _u.getDimensions(options, element, attrs)
      isThumbnail = attrs.mode is 'thumbnail'

      _u.clean(element[0])

      svg = _u.bootstrap(element[0], id, dimensions)

      fn = (key) -> (options.series.filter (s) -> s.axis is key and s.visible isnt false).length > 0

      axes = _u
        .createAxes(svg, dimensions, options.axes)
        .andAddThemIf({
          all: !isThumbnail
          x: true
          y: fn('y')
          y2: fn('y2')
        })

      if dataPerSeries.length
        _u.setScalesDomain(axes, scope.data, options.series, svg, options)

      _u.drawGridAxes(svg, dimensions, options.axes, axes)
      _u.createContent(svg, id, options, handlers)

      if dataPerSeries.length
        columnWidth = _u.getBestColumnWidth(axes, dimensions, dataPerSeries, options)

        _u
          .drawArea(svg, axes, dataPerSeries, options, handlers)
          .drawColumns(svg, axes, dataPerSeries, columnWidth, options, handlers, dispatch)
          .drawLines(svg, axes, dataPerSeries, options, handlers)
          .drawCandlestick(svg, axes, dataPerSeries, columnWidth, options, handlers, dimensions)
          .drawOhlc(svg, axes, dataPerSeries, columnWidth, options, handlers, dimensions)
          .drawTriangles(svg, axes, dataPerSeries, columnWidth, options, handlers, dimensions)

        if options.drawDots
          _u.drawDots(svg, axes, dataPerSeries, options, handlers, dispatch)

      if options.drawLegend
        _u.drawLegend(svg, options.series, dimensions, handlers, dispatch)

      if options.tooltip.mode is 'scrubber'
        _u.createGlass(svg, dimensions, handlers, axes, dataPerSeries, options, dispatch, columnWidth)
      else if options.tooltip.mode isnt 'none'
        _u.addTooltips(svg, dimensions, options.axes)

    updateEvents = ->

      # Deprecated: this will be removed in 2.x
      if scope.oldclick
        dispatch.on('click', scope.oldclick)
      else if scope.click
        dispatch.on('click', scope.click)
      else
        dispatch.on('click', null)

      # Deprecated: this will be removed in 2.x
      if scope.oldhover
        dispatch.on('hover', scope.oldhover)
      else if scope.hover
        dispatch.on('hover', scope.hover)
      else
        dispatch.on('hover', null)

      # Deprecated: this will be removed in 2.x
      if scope.oldfocus
        dispatch.on('focus', scope.oldfocus)
      else if scope.focus
        dispatch.on('focus', scope.focus)
      else
        dispatch.on('focus', null)

      if scope.toggle
        dispatch.on('toggle', scope.toggle)
      else
        dispatch.on('toggle', null)

    promise = undefined
    window_resize = ->
      $timeout.cancel(promise) if promise?
      promise = $timeout(scope.redraw, 1)

    $window.addEventListener('resize', window_resize)

    scope.$watch('data', scope.redraw, true)
    scope.$watch('options', scope.redraw , true)
    scope.$watchCollection('[click, hover, focus, toggle]', updateEvents)

    # Deprecated: this will be removed in 2.x
    scope.$watchCollection('[oldclick, oldhover, oldfocus]', updateEvents)

    return

  return {
    replace: true
    restrict: 'E'
    scope:
      data: '=', options: '=',
      # Deprecated: this will be removed in 2.x
      oldclick: '=click',  oldhover: '=hover',  oldfocus: '=focus',
      # Events
      click: '=onClick',  hover: '=onHover',  focus: '=onFocus',  toggle: '=onToggle'
    template: '<div></div>'
    link: (scope, element, attrs, ctrl) ->  $timeout(
        () -> link(scope, element, attrs, ctrl),
        0
      )
  }
])

# ----

# D:/tmp/utils.coffee
mod = angular.module('n3charts.utils', [])

mod.factory('n3utils', ['$window', '$log', '$rootScope', ($window, $log, $rootScope) ->
  return {
# src/utils/areas.coffee
      addPatterns: (svg, series) ->
        pattern = svg.select('defs').selectAll('pattern')
        .data(series.filter (s) -> s.striped)
        .enter().append('pattern')
          .attr(
            id: (s) -> s.type + 'Pattern_' + s.index
            patternUnits: "userSpaceOnUse"
            x: 0
            y: 0
            width: 60
            height: 60
          ).append('g')
            .style(
              'fill': (s) -> s.color
              'fill-opacity': 0.3
            )

        pattern.append('rect')
          .style('fill-opacity', 0.3)
          .attr('width', 60)
          .attr('height', 60)

        pattern.append('path')
          .attr('d', "M 10 0 l10 0 l -20 20 l 0 -10 z")

        pattern.append('path')
          .attr('d', "M40 0 l10 0 l-50 50 l0 -10 z")

        pattern.append('path')
          .attr('d', "M60 10 l0 10 l-40 40 l-10 0 z")

        pattern.append('path')
          .attr('d', "M60 40 l0 10 l-10 10 l -10 0 z")

      drawArea: (svg, scales, data, options) ->
        areaSeries = data.filter (series) -> series.type is 'area'

        this.addPatterns(svg, areaSeries)

        drawers =
          y: this.createLeftAreaDrawer(scales, options.lineMode, options.tension)
          y2: this.createRightAreaDrawer(scales, options.lineMode, options.tension)

        svg.select('.content').selectAll('.areaGroup')
          .data(areaSeries)
          .enter().append('g')
            .attr('class', (s) -> 'areaGroup ' + 'series_' + s.index)
            .append('path')
              .attr('class', 'area')
              .style('fill', (s) ->
                return s.color if s.striped isnt true
                return "url(#areaPattern_#{s.index})"
              )
              .style('opacity', (s) -> if s.striped then '1' else '0.3')
              .attr('d', (d) -> drawers[d.axis](d.values))

        return this

      createLeftAreaDrawer: (scales, mode, tension) ->
        return d3.svg.area()
          .x (d) -> return scales.xScale(d.x)
          .y0 (d) -> return scales.yScale(d.y0)
          .y1 (d) -> return scales.yScale(d.y0 + d.y)
          .interpolate(mode)
          .tension(tension)

      createRightAreaDrawer: (scales, mode, tension) ->
        return d3.svg.area()
          .x (d) -> return scales.xScale(d.x)
          .y0 (d) -> return scales.y2Scale(d.y0)
          .y1 (d) -> return scales.y2Scale(d.y0 + d.y)
          .interpolate(mode)
          .tension(tension)

# ----


# src/utils/candlestick.coffee
      drawCandlestick: (svg, axes, data, columnWidth, options, handlers, dimensions) ->
        that = this
        height = dimensions.height
        width = dimensions.width

        data = data.filter (s) -> s.type is 'candlestick'

        if data.length == 0
          return this

        candleWidth = (0.5 * width) / data[0].values.length
        if candleWidth > 60
          candleWidth = 60
        if candleWidth < 4
          candleWidth = 4
        gainColor = 'green'
        lossColor = 'red'

        gainColor = options.series[0].gainColor if options.series[0].gainColor
        lossColor = options.series[0].lossColor if options.series[0].lossColor

        colGroup = svg.select('.content').selectAll('.candleGroup')
          .data(data)
          .enter().append('g')
          .attr('class', (s) -> 'candleGroup series_' + s.index)

        colGroup.selectAll('rect').data((d) -> d.values)
          .enter().append('svg:rect')
          .attr(
            x: (d) ->
              tmpX = axes.xScale(d.x)
              return tmpX - (candleWidth / 2)
            y: (d) ->
              tmpY = axes[d.axis + 'Scale'](d.open)
              tmpHeight = axes[d.axis + 'Scale'](d.close) - axes[d.axis + 'Scale'](d.open)
              if tmpHeight < 0
                tmpHeight = axes[d.axis + 'Scale'](d.open) - axes[d.axis + 'Scale'](d.close)
                tmpY = tmpY - tmpHeight
              return tmpY
            width: (d) ->
              return candleWidth
            height: (d) ->
              tmpHeight = axes[d.axis + 'Scale'](d.close) - axes[d.axis + 'Scale'](d.open)
              if tmpHeight < 0
                tmpHeight = axes[d.axis + 'Scale'](d.open) - axes[d.axis + 'Scale'](d.close)
              return tmpHeight
            fill: (d) ->
              if d.open > d.close
                return lossColor
              return gainColor
          )

        colGroup.selectAll('line.stem').data((d) -> d.values)
          .enter().append('svg:line')
          .attr('class', (d) -> 'stem')
          .attr(
            x1: (d) -> axes.xScale(d.x)
            x2: (d) -> axes.xScale(d.x)
            y1: (d) -> axes[d.axis + 'Scale'](d.high)
            y2: (d) -> axes[d.axis + 'Scale'](d.low)
            stroke: (d) ->
              if d.open > d.close
                return lossColor
              return gainColor
          )

        return this

# ----


# src/utils/columns.coffee
      getPseudoColumns: (data, options) ->
        data = data.filter (s) -> s.type is 'column'

        pseudoColumns = {}
        keys = []
        data.forEach (series, i) ->
          visible = options.series?[i].visible
          if visible is undefined or visible is not false
            inAStack = false
            options.stacks.forEach (stack, index) ->
              if series.id? and series.id in stack.series
                pseudoColumns[series.id] = index
                keys.push(index) unless index in keys
                inAStack = true

            if inAStack is false
              i = pseudoColumns[series.id] = index = keys.length
              keys.push(i)

        return {pseudoColumns, keys}

      getMinDelta: (seriesData, key, scale, range) ->
        return d3.min(
          # Compute the minimum difference along an axis on all series
          seriesData.map (series) ->
            # Compute delta
            return series.values
              # Look at all sclaed values on the axis
              .map((d) -> scale(d[key]))
              # Select only columns in the visible range
              .filter((e) ->
                return if range then e >= range[0] && e <= range[1] else true
              )
              # Return the smallest difference between 2 values
              .reduce((prev, cur, i, arr) ->
                # Get the difference from the current value
                # with the previous value in the array
                diff = if i > 0 then cur - arr[i - 1] else Number.MAX_VALUE
                # Return the new difference if it is smaller
                # than the previous difference
                return if diff < prev then diff else prev
              , Number.MAX_VALUE)
        )

      getBestColumnWidth: (axes, dimensions, seriesData, options) ->
        return 10 unless seriesData and seriesData.length isnt 0

        return 10 if (seriesData.filter (s) -> s.type is 'column').length is 0

        {pseudoColumns, keys} = this.getPseudoColumns(seriesData, options)

        # iner width of the chart area
        innerWidth = dimensions.width - dimensions.left - dimensions.right

        colData = seriesData
          # Get column data (= columns that are not stacked)
          .filter((d) ->
            return pseudoColumns.hasOwnProperty(d.id)
          )

        # Get the smallest difference on the x axis in the visible range
        delta = this.getMinDelta(colData, 'x', axes.xScale, [0, innerWidth])
        
        # We get a big value when we cannot compute the difference
        if delta > innerWidth
          # Set to some good looking ordinary value
          delta = 0.25 * innerWidth

        # number of series to display
        nSeries = keys.length

        return parseInt((delta - options.columnsHGap) / nSeries)

      getColumnAxis: (data, columnWidth, options) ->
        {pseudoColumns, keys} = this.getPseudoColumns(data, options)

        x1 = d3.scale.ordinal()
          .domain(keys)
          .rangeBands([0, keys.length * columnWidth], 0)

        return (s) ->
          return 0 unless pseudoColumns[s.id]?
          index = pseudoColumns[s.id]
          return x1(index) - keys.length*columnWidth/2

      drawColumns: (svg, axes, data, columnWidth, options, handlers, dispatch) ->
        data = data.filter (s) -> s.type is 'column'

        x1 = this.getColumnAxis(data, columnWidth, options)

        data.forEach (s) -> s.xOffset = x1(s) + columnWidth*.5

        colGroup = svg.select('.content').selectAll('.columnGroup')
          .data(data)
          .enter().append("g")
            .attr('class', (s) -> 'columnGroup series_' + s.index)
            .attr('transform', (s) -> "translate(" + x1(s) + ",0)")

        colGroup.each (series) ->
          d3.select(this).selectAll("rect")
            .data(series.values)
            .enter().append("rect")
              .style({
                'stroke': series.color
                'fill': series.color
                'stroke-opacity': (d) -> if d.y is 0 then '0' else '1'
                'stroke-width': '1px'
                'fill-opacity': (d) -> if d.y is 0 then 0 else 0.7
              })
              .attr(
                width: columnWidth
                x: (d) -> axes.xScale(d.x)
                height: (d) ->
                  return axes[d.axis + 'Scale'].range()[0] if d.y is 0
                  return Math.abs(axes[d.axis + 'Scale'](d.y0 + d.y) - axes[d.axis + 'Scale'](d.y0))
                y: (d) ->
                  if d.y is 0 then 0 else axes[d.axis + 'Scale'](Math.max(0, d.y0 + d.y))
              )
              .on('click': (d, i) -> dispatch.click(d, i))
              .on('mouseover', (d, i) ->
                dispatch.hover(d, i)
                handlers.onMouseOver?(svg, {
                  series: series
                  x: axes.xScale(d.x)
                  y: axes[d.axis + 'Scale'](d.y0 + d.y)
                  datum: d
                }, options.axes)
              )
              .on('mouseout', (d) ->
                handlers.onMouseOut?(svg)
              )

        return this
# ----


# src/utils/dots.coffee
      drawDots: (svg, axes, data, options, handlers, dispatch) ->
        dotGroup = svg.select('.content').selectAll('.dotGroup')
          .data data.filter (s) -> s.type in ['line', 'area'] and s.drawDots
          .enter().append('g')
        dotGroup.attr(
            class: (s) -> "dotGroup series_#{s.index}"
            fill: (s) -> s.color
          )
          .selectAll('.dot').data (d) -> d.values
            .enter().append('circle')
            .attr(
              'class': 'dot'
              'r': (d) -> d.dotSize
              'cx': (d) -> axes.xScale(d.x)
              'cy': (d) -> axes[d.axis + 'Scale'](d.y + d.y0)
            )
            .style(
              'stroke': 'white'
              'stroke-width': '2px'
            )
            .on('click': (d, i) -> dispatch.click(d, i))
            .on('mouseover': (d, i) -> dispatch.hover(d, i))

        if options.tooltip.mode isnt 'none'
          dotGroup.on('mouseover', (series) ->
            target = d3.select(d3.event.target)
            d = target.datum()
            target.attr('r', (s) -> s.dotSize + 2)

            handlers.onMouseOver?(svg, {
              series: series
              x: target.attr('cx')
              y: target.attr('cy')
              datum: d
            }, options.axes)
          )
          .on('mouseout', (d) ->
            d3.select(d3.event.target).attr('r', (s) -> s.dotSize)
            handlers.onMouseOut?(svg)
          )

        return this

# ----


# src/utils/events.coffee
      getEventDispatcher: () ->
        
        events = [
          'focus',
          'hover',
          'click',
          'toggle'
        ]

        return d3.dispatch.apply(this, events)
# ----


# src/utils/legend.coffee
      computeLegendLayout: (svg, series, dimensions) ->
        padding = 10
        that = this

        leftWidths = this.getLegendItemsWidths(svg, 'y', series)

        leftLayout = [0]
        i = 1
        while i < leftWidths.length
          leftLayout.push(leftWidths[i-1] + leftLayout[i - 1] + padding)
          i++


        rightWidths = this.getLegendItemsWidths(svg, 'y2', series)
        return [leftLayout] unless rightWidths.length > 0

        w = dimensions.width - dimensions.right - dimensions.left

        cumul = 0
        rightLayout = []
        j = rightWidths.length - 1
        while j >= 0
          rightLayout.push w  - cumul - rightWidths[j]
          cumul += rightWidths[j] + padding
          j--

        rightLayout.reverse()

        return [leftLayout, rightLayout]

      getLegendItemsWidths: (svg, axis, series) ->
        that = this
        bbox = (t) ->
          return that.getTextBBox(t).width

        items = svg.selectAll(".legendItem.#{axis}")
        return [] unless items.length > 0

        widths = []
        i = 0
        while i < items[0].length
          widths.push(bbox(items[0][i]))
          i++

        return widths

      drawLegend: (svg, series, dimensions, handlers, dispatch) ->
        that = this
        legend = svg.append('g').attr('class', 'legend')

        d = 16

        svg.select('defs').append('svg:clipPath')
          .attr('id', 'legend-clip')
          .append('circle').attr('r', d/2)

        groups = legend.selectAll('.legendItem')
          .data(series)

        groups.enter().append('g')
          .on('click', (s, i) ->
            if s.labelIsClickable == false
              return
            visibility = !(s.visible isnt false)
            dispatch.toggle(s, i, visibility)
            handlers.onSeriesVisibilityChange?({
              series: s,
              index: i,
              newVisibility: visibility
            })
          )

        groups.attr(
              'class': (s, i) -> "legendItem series_#{i} #{s.axis}"
              'opacity': (s, i) ->
                if s.visible is false
                  that.toggleSeries(svg, i)
                  return '0.2'

                return '1'
            )
          .each (s) ->
            item = d3.select(this)
            if s.iconIsVisible == true
              item.append('circle')
                .attr(
                  'fill': s.color
                  'stroke': s.color
                  'stroke-width': '2px'
                  'r': d/2
                )

              item.append('path')
                .attr(
                  'clip-path': 'url(#legend-clip)'
                  'fill-opacity': if s.type in ['area', 'column'] then '1' else '0'
                  'fill': 'white'
                  'stroke': 'white'
                  'stroke-width': '2px'
                  'd': that.getLegendItemPath(s, d, d)
                )

              item.append('circle')
                .attr(
                  'fill-opacity': 0
                  'stroke': s.color
                  'stroke-width': '2px'
                  'r': d/2
                )

            if s.labelIsVisible == true
              item.append('text')
                .attr(
                  'class': (d, i) -> "legendText series_#{i}"
                  'font-family': 'Courier'
                  'font-size': 10
                  'transform': (s) ->
                    if s.iconIsVisible is true
                      return 'translate(13, 4)'
                    else
                      return 'translate(-10, 4)'
                  'text-rendering': 'geometric-precision'
                )
                .text((s) ->
                  value = ''
                  if s.labelIsVisible
                    value = s.label || s.y

                  return value
                )

        # Translate every legend g node to its position
        translateLegends = () ->
          [left, right] = that.computeLegendLayout(svg, series, dimensions)
          groups
            .attr(
              'transform': (s, i) ->
                if s.axis is 'y'
                  return "translate(#{left.shift()},#{dimensions.height-40})"
                else
                  return "translate(#{right.shift()},#{dimensions.height-40})"
            )

        # We need to call this once, so the
        # legend text does not blink on every update
        translateLegends()

        # now once again,
        # to make sure, text width gets really! computed properly
        setTimeout(translateLegends, 0)

        return this

      getLegendItemPath: (series, w, h) ->
        if series.type is 'column'
          path = 'M' + (-w/3) + ' ' + (-h/8) + ' l0 ' + h + ' '
          path += 'M0' + ' ' + (-h/3) + ' l0 ' + h + ' '
          path += 'M' + w/3 + ' ' + (-h/10) + ' l0 ' + h + ' '

          return path

        base_path = 'M-' + w/2 + ' 0' + h/3 + ' l' + w/3 + ' -' + h/3 + ' l' + w/3 + ' ' +  h/3 + ' l' + w/3 + ' -' + 2*h/3

        base_path + ' l0 ' + h + ' l-' + w + ' 0z' if series.type is 'area'

        return base_path

      toggleSeries: (svg, index) ->
        isVisible = false

        svg.select('.content').selectAll('.series_' + index)
          .style('display', (s) ->
            if d3.select(this).style('display') is 'none'
              isVisible = true
              return 'initial'
            else
              isVisible = false
              return 'none'
          )

        return isVisible

      updateTextLegendWithTooltip: (svg, index, dataTooltip) ->
        item1 = svg.select('.legend')
        item2 = item1.select('.series_' + index)
        text = item2.select('text')
        tmpText = ''
        if item2.data()[0].labelIsVisible
          tmpText = item2.data()[0].label
        tmpText = tmpText + ' ' + dataTooltip
        text.text(tmpText)

      updateTranslateLegends: (svg, series, dimensions) ->
        [left, right] = this.computeLegendLayout(svg, series, dimensions)
        item1 = svg.select('.legend')
        groups = item1.selectAll('.legendItem')
        groups.attr(
          'transform': (s, i) ->
            if s.axis is 'y'
              return "translate(#{left.shift()},#{dimensions.height-40})"
            else
              return "translate(#{right.shift()},#{dimensions.height-40})"
        )

# ----


# src/utils/lines.coffee
      drawLines: (svg, scales, data, options, handlers) ->
        drawers =
          y: this.createLeftLineDrawer(scales, options.lineMode, options.tension)
          y2: this.createRightLineDrawer(scales, options.lineMode, options.tension)

        lineGroup = svg.select('.content').selectAll('.lineGroup')
          .data data.filter (s) -> s.type in ['line', 'area']
          .enter().append('g')
        lineGroup.style('stroke', (s) -> s.color)
        .attr('class', (s) -> "lineGroup series_#{s.index}")
        .append('path')
          .attr(
            class: 'line'
            d: (d) -> drawers[d.axis](d.values)
          )
          .style(
            'fill': 'none'
            'stroke-width': (s) -> s.thickness
            'stroke-dasharray': (s) ->
              return '10,3' if s.lineMode is 'dashed'
              return undefined
          )
        if options.tooltip.interpolate
          interpolateData = (series) ->
            target = d3.select(d3.event.target)
            try
              mousePos = d3.mouse(this)
            catch error
              mousePos = [0, 0]
            # interpolate between min/max based on mouse coords
            valuesData = target.datum().values
            # find min/max coords and values
            for datum, i in valuesData
              x = scales.xScale(datum.x)
              y = scales.yScale(datum.y)
              if !minXPos? or x < minXPos
                minXPos = x
                minXValue = datum.x
              if !maxXPos? or x > maxXPos
                maxXPos = x
                maxXValue = datum.x
              if !minYPos? or y < minYPos
                minYPos = y
              if !maxYPos? or y > maxYPos
                maxYPos = y
              if !minYValue? or datum.y < minYValue
                minYValue = datum.y
              if !maxYValue? or datum.y > maxYValue
                maxYValue = datum.y

            xPercentage = (mousePos[0] - minXPos) / (maxXPos - minXPos)
            yPercentage = (mousePos[1] - minYPos) / (maxYPos - minYPos)
            xVal = Math.round(xPercentage * (maxXValue - minXValue) + minXValue)
            yVal = Math.round((1 - yPercentage) * (maxYValue - minYValue) + minYValue)

            interpDatum = x: xVal, y: yVal

            handlers.onMouseOver?(svg, {
              series: series
              x: mousePos[0]
              y: mousePos[1]
              datum: interpDatum
            }, options.axes)

          lineGroup
            .on 'mousemove', interpolateData
            .on 'mouseout', (d) -> handlers.onMouseOut?(svg)

        return this

      createLeftLineDrawer: (scales, mode, tension) ->
        return d3.svg.line()
          .x (d) -> scales.xScale(d.x)
          .y (d) -> scales.yScale(d.y + d.y0)
          .interpolate(mode)
          .tension(tension)

      createRightLineDrawer: (scales, mode, tension) ->
        return d3.svg.line()
          .x (d) -> scales.xScale(d.x)
          .y (d) -> scales.y2Scale(d.y + d.y0)
          .interpolate(mode)
          .tension(tension)

# ----


# src/utils/misc.coffee
      getPixelCssProp: (element, propertyName) ->
        string = $window.getComputedStyle(element, null)
          .getPropertyValue(propertyName)
        return +string.replace(/px$/, '')

      getDefaultMargins: ->
        return {top: 20, right: 50, bottom: 60, left: 50}

      getDefaultThumbnailMargins: ->
        return {top: 1, right: 1, bottom: 2, left: 0}

      getElementDimensions: (element, width, height) ->
        dim = {}
        parent = element

        top = this.getPixelCssProp(parent, 'padding-top')
        bottom = this.getPixelCssProp(parent, 'padding-bottom')
        left = this.getPixelCssProp(parent, 'padding-left')
        right = this.getPixelCssProp(parent, 'padding-right')

        dim.width = +(width || parent.offsetWidth || 900) - left - right
        dim.height = +(height || parent.offsetHeight || 500) - top - bottom

        return dim

      getDimensions: (options, element, attrs) ->
        dim = this.getElementDimensions(element[0].parentElement, attrs.width, attrs.height)
        dim = angular.extend(options.margin, dim)

        return dim

      clean: (element) ->
        d3.select(element)
          .on('keydown', null)
          .on('keyup', null)
          .select('svg')
            .remove()

      uuid: () ->
        # @src: http://stackoverflow.com/a/2117523
        return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(
          /[xy]/g, (c) ->
            r = Math.random()*16|0
            v = if c == 'x' then r else r&0x3|0x8
            return v.toString(16)
          )

      bootstrap: (element, id, dimensions) ->
        d3.select(element).classed('chart', true)

        width = dimensions.width
        height = dimensions.height

        svg = d3.select(element).append('svg')
          .attr(
            width: width
            height: height
          )
          .append('g')
            .attr('transform', 'translate(' + dimensions.left + ',' + dimensions.top + ')')

        defs = svg.append('defs')
          .attr('class', 'patterns')

        # Add a clipPath for the content area
        defs.append('clipPath')
          .attr('class', 'content-clip')
          .attr('id', "content-clip-#{id}")
          .append('rect')
            .attr({
              'x': 0
              'y': 0
              'width': width - dimensions.left - dimensions.right
              'height': height - dimensions.top - dimensions.bottom
            })

        return svg

      createContent: (svg, id, options) ->
        content = svg.append('g')
          .attr('class', 'content')

        if options.hideOverflow
          content.attr('clip-path', "url(#content-clip-#{id})")

      createGlass: (svg, dimensions, handlers, axes, data, options, dispatch, columnWidth) ->
        that = this

        glass = svg.append('g')
          .attr(
            'class': 'glass-container'
            'opacity': 0
          )

        scrubberGroup = glass.selectAll('.scrubberItem')
          .data(data).enter()
            .append('g')
              .attr('class', (s, i) -> "scrubberItem series_#{i}")

        scrubberGroup.each (s, i) ->

          item = d3.select(this)

          g = item.append('g')
            .attr('class': "rightTT")

          g.append('path')
            .attr(
              'class': "scrubberPath series_#{i}"
              'y': '-7px'
              'fill': s.color
            )

          that.styleTooltip(g.append('text')
            .style('text-anchor', 'start')
            .attr(
              'class': (d, i) -> "scrubberText series_#{i}"
              'height': '14px'
              'transform': 'translate(7, 3)'
              'text-rendering': 'geometric-precision'
            ))
            .text(s.label || s.y)

          g2 = item.append('g')
            .attr('class': "leftTT")

          g2.append('path')
            .attr(
              'class': "scrubberPath series_#{i}"
              'y': '-7px'
              'fill': s.color
            )

          that.styleTooltip(g2.append('text')
            .style('text-anchor', 'end')
            .attr(
              'class': "scrubberText series_#{i}"
              'height': '14px'
              'transform': 'translate(-13, 3)'
              'text-rendering': 'geometric-precision'
            ))
            .text(s.label || s.y)

          item.append('circle')
            .attr(
              'class': "scrubberDot series_#{i}"
              'fill': 'white'
              'stroke': s.color
              'stroke-width': '2px'
              'r': 4
            )

        glass.append('rect')
          .attr(
            class: 'glass'
            width: dimensions.width - dimensions.left - dimensions.right
            height: dimensions.height - dimensions.top - dimensions.bottom
          )
          .style('fill', 'white')
          .style('fill-opacity', 0.000001)
          .on('mouseover', ->
            handlers.onChartHover(svg, d3.select(this), axes, data, options, dispatch, columnWidth, dimensions)
          )


      getDataPerSeries: (data, options) ->
        series = options.series
        axes = options.axes

        return [] unless series and series.length and data and data.length

        straightened = series.map (s, i) ->
          seriesData =
            index: i
            name: s.y
            values: []
            color: s.color
            axis: s.axis || 'y'
            xOffset: 0
            type: s.type
            thickness: s.thickness
            drawDots: s.drawDots isnt false


          if s.dotSize?
            seriesData.dotSize = s.dotSize

          if s.striped is true
            seriesData.striped = true

          if s.lineMode?
            seriesData.lineMode = s.lineMode

          if s.id
            seriesData.id = s.id

          data.filter((row) -> row[s.y]?).forEach (row) ->
            d =
              x: row[options.axes.x.key]
              y: row[s.y]
              y0: 0
              axis: s.axis || 'y'
              date: row.dateValue || 0
              close: row.closeValue || 0
              open: row.openValue || 0
              high: row.highValue || 0
              low: row.lowValue || 0

            d.dotSize = s.dotSize if s.dotSize?
            seriesData.values.push(d)

          if s.type is 'dailyTriangles'
            seriesData.dailyTrianglesData = s.dailyTrianglesData
          if s.type is 'weeklyTriangles'
            seriesData.weeklyTrianglesData = s.weeklyTrianglesData
          if s.type is 'monthlyTriangles'
            seriesData.monthlyTrianglesData = s.monthlyTrianglesData
          if s.type is 'trianglesLegend'
            seriesData.trianglesLegendData = s.trianglesLegendData

          return seriesData

        if !options.stacks? or options.stacks.length is 0
          return straightened

        layout = d3.layout.stack()
          .values (s) -> s.values

        options.stacks.forEach (stack) ->
          return unless stack.series.length > 0
          layers = straightened.filter (s, i) -> s.id? and s.id in stack.series
          layout(layers)

        return straightened

      estimateSideTooltipWidth: (svg, text) ->
        t = svg.append('text')
        t.text('' + text)
        this.styleTooltip(t)

        bbox = this.getTextBBox(t[0][0])
        t.remove()

        return bbox

      getTextBBox: (svgTextElement) ->
        if svgTextElement isnt null

          try
            return svgTextElement.getBBox()

          catch error
            # NS_ERROR_FAILURE in FF for calling .getBBox()
            # on an element that is not rendered (e.g. display: none)
            # https://bugzilla.mozilla.org/show_bug.cgi?id=612118
            return {height: 0, width: 0, y: 0, x: 0}

        return {}

      getWidestTickWidth: (svg, axisKey) ->
        max = 0
        bbox = this.getTextBBox

        ticks = svg.select(".#{axisKey}.axis").selectAll('.tick')
        ticks[0]?.forEach (t) -> max = Math.max(max, bbox(t).width)

        return max

      getWidestOrdinate: (data, series, options) ->
        widest = ''

        data.forEach (row) ->
          series.forEach (series) ->
            v = row[series.y]

            if series.axis? and options.axes[series.axis]?.ticksFormatter
              v = options.axes[series.axis].ticksFormatter(v)

            return unless v?

            if ('' + v).length > ('' + widest).length
              widest = v

        return widest

# ----


# src/utils/ohlc.coffee
      drawOhlc: (svg, axes, data, columnWidth, options, handlers, dimensions) ->
        that = this
        height = dimensions.height
        width = dimensions.width

        data = data.filter (s) -> s.type is 'ohlc'

        if data.length == 0
          return this

        lineWidth = (0.5 * width) / data[0].values.length
        if lineWidth > 20
          lineWidth = 20
        if lineWidth < 4
          lineWidth = 4
        gainColor = options.series[0].gainColor if options.series[0].gainColor
        lossColor = options.series[0].lossColor if options.series[0].lossColor

        colGroup = svg.select('.content').selectAll('.ohlcGroup')
          .data(data)
          .enter().append('g')
          .attr('class', (s) -> 'ohlcGroup series_' + s.index)

        colGroup.selectAll('open').data((d) -> d.values)
          .enter().append('svg:line')
          .attr(
            x1: (d) ->
              tmpX = axes.xScale(d.x)
              return tmpX - lineWidth
            y1: (d) ->
              return axes[d.axis + 'Scale'](d.open)
            x2: (d) ->
              tmpX = axes.xScale(d.x)
              return tmpX
            y2: (d) ->
              return axes[d.axis + 'Scale'](d.open)
            stroke: (d) ->
              if d.open > d.close
                return lossColor
              return gainColor
          )

        colGroup.selectAll('close').data((d) -> d.values)
          .enter().append('svg:line')
          .attr(
            x1: (d) ->
              tmpX = axes.xScale(d.x)
              return tmpX
            y1: (d) ->
              return axes[d.axis + 'Scale'](d.close)
            x2: (d) ->
              tmpX = axes.xScale(d.x)
              return tmpX + lineWidth
            y2: (d) ->
              return axes[d.axis + 'Scale'](d.close)
            stroke: (d) ->
              if d.open > d.close
                return lossColor
              return gainColor
          )

        colGroup.selectAll('line.stem').data((d) -> d.values)
          .enter().append('svg:line')
          .attr('class', (d) -> 'stem')
          .attr(
            x1: (d) -> axes.xScale(d.x)
            x2: (d) -> axes.xScale(d.x)
            y1: (d) -> axes[d.axis + 'Scale'](d.high)
            y2: (d) -> axes[d.axis + 'Scale'](d.low)
            stroke: (d) ->
              if d.open > d.close
                return lossColor
              return gainColor
          )

        return this

# ----


# src/utils/options.coffee
      getDefaultOptions: ->
        return {
          tooltip: {mode: 'scrubber', type: 'complete'}
          lineMode: 'linear'
          tension: 0.7
          margin: this.getDefaultMargins()
          axes: {
            x: {type: 'linear', key: 'x'}
            y: {type: 'linear'},
            isGridHorizontalLinesVisible: false,
            isGridVerticalLinesVisible: false

          }
          series: [
            labelIsClickable: true,
            iconIsVisible: true,
            labelIsVisible: true,
            labelIsUpdatedWithTooltip: false,
            isTooltipDisplayed: true
          ]
          drawLegend: true
          drawDots: true
          stacks: []
          columnsHGap: 5
          hideOverflow: false
        }

      sanitizeOptions: (options, mode) ->
        options ?= {}

        if mode is 'thumbnail'
          options.drawLegend = false
          options.drawDots = false
          options.tooltip = {mode: 'none', interpolate: false}

        # Parse and sanitize the options
        options.series = this.sanitizeSeriesOptions(options.series)
        options.stacks = this.sanitizeSeriesStacks(options.stacks, options.series)
        options.axes = this.sanitizeAxes(options.axes, this.haveSecondYAxis(options.series))
        options.tooltip = this.sanitizeTooltip(options.tooltip)
        options.margin = this.sanitizeMargins(options.margin)

        options.lineMode or= this.getDefaultOptions().lineMode
        options.tension = if /^\d+(\.\d+)?$/.test(options.tension) then options.tension \
          else this.getDefaultOptions().tension

        options.drawLegend = options.drawLegend isnt false
        options.drawDots = options.drawDots isnt false
        options.columnsHGap = 5 unless angular.isNumber(options.columnsHGap)
        options.hideOverflow = options.hideOverflow or false

        defaultMargin = if mode is 'thumbnail' then this.getDefaultThumbnailMargins() \
          else this.getDefaultMargins()

        # Use default values where no options are defined
        options.series = angular.extend(this.getDefaultOptions().series, options.series)
        options.axes = angular.extend(this.getDefaultOptions().axes, options.axes)
        options.tooltip = angular.extend(this.getDefaultOptions().tooltip, options.tooltip)
        options.margin = angular.extend(defaultMargin, options.margin)

        return options

      sanitizeMargins: (options) ->
        attrs = ['top', 'right', 'bottom', 'left']
        margin = {}

        for opt, value of options
          if opt in attrs
            margin[opt] = parseFloat(value)

        return margin

      sanitizeSeriesStacks: (stacks, series) ->
        return [] unless stacks?

        seriesKeys = {}
        series.forEach (s) -> seriesKeys[s.id] = s

        stacks.forEach (stack) ->
          stack.series.forEach (id) ->
            s = seriesKeys[id]
            if s?
              $log.warn "Series #{id} is not on the same axis as its stack" unless s.axis is stack.axis
            else
              $log.warn "Unknown series found in stack : #{id}" unless s

        return stacks

      sanitizeTooltip: (options) ->
        if !options
          return {mode: 'scrubber'}

        if options.mode not in ['none', 'axes', 'scrubber']
          options.mode = 'scrubber'

        if options.type not in ['complete', 'partial']
          options.type = 'complete'

        if options.mode is 'scrubber'
          delete options.interpolate
        else
          options.interpolate = !!options.interpolate

        if options.mode is 'scrubber' and options.interpolate
          throw new Error('Interpolation is not supported for scrubber tooltip mode.')

        return options

      sanitizeSeriesOptions: (options) ->
        return [] unless options?

        colors = d3.scale.category10()
        knownIds = {}
        options.forEach (s, i) ->
          if knownIds[s.id]?
            throw new Error("Twice the same ID (#{s.id}) ? Really ?")
          knownIds[s.id] = s if s.id?

        options.forEach (s, i) ->
          s.axis = if s.axis?.toLowerCase() isnt 'y2' then 'y' else 'y2'
          s.color or= colors(i)
          s.type = if s.type in ['line', 'area', 'column', 'candlestick', 'ohlc', 'dailyTriangles', 'weeklyTriangles', 'monthlyTriangles', 'trianglesLegend'] then s.type else "line"
          s.labelIsClickable = if s.labelIsClickable in [true, false] then s.labelIsClickable else true
          s.iconIsVisible = if s.iconIsVisible in [true, false] then s.iconIsVisible else true
          s.labelIsVisible = if s.labelIsVisible in [true, false] then s.labelIsVisible else true
          s.labelIsUpdatedWithTooltip = if s.labelIsUpdatedWithTooltip in [true, false] then s.labelIsUpdatedWithTooltip else false
          s.isTooltipDisplayed = if s.isTooltipDisplayed in [true, false] then s.isTooltipDisplayed else true

          if s.type is 'column'
            delete s.thickness
            delete s.lineMode
            delete s.drawDots
            delete s.dotSize
          else if not /^\d+px$/.test(s.thickness)
            s.thickness = '1px'

          if s.type in ['line', 'area']
            if s.lineMode not in ['dashed']
              delete s.lineMode

            if s.drawDots isnt false and !s.dotSize?
              s.dotSize = 2

          if !s.id?
            cnt = 0
            while knownIds["series_#{cnt}"]?
              cnt++
            s.id = "series_#{cnt}"
            knownIds[s.id] = s

          if s.drawDots is false
            delete s.dotSize

        return options

      sanitizeAxes: (axesOptions, secondAxis) ->
        axesOptions = {} unless axesOptions?

        axesOptions.x = this.sanitizeAxisOptions(axesOptions.x)
        axesOptions.x.key or= "x"

        axesOptions.y = this.sanitizeAxisOptions(axesOptions.y)
        axesOptions.y2 = this.sanitizeAxisOptions(axesOptions.y2) if secondAxis

        axesOptions.isGridHorizontalLinesVisible = if axesOptions.isGridHorizontalLinesVisible in [true, false] then axesOptions.isGridHorizontalLinesVisible else false
        axesOptions.isGridVerticalLinesVisible = if axesOptions.isGridVerticalLinesVisible in [true, false] then axesOptions.isGridVerticalLinesVisible else false

        return axesOptions

      sanitizeExtrema: (options) ->
        min = this.getSanitizedNumber(options.min)
        if min?
          options.min = min
        else
          delete options.min

        max = this.getSanitizedNumber(options.max)
        if max?
          options.max = max
        else
          delete options.max

      getSanitizedNumber: (value) ->
        return undefined unless value?

        number = parseFloat(value)

        if isNaN(number)
          $log.warn("Invalid extremum value : #{value}, deleting it.")
          return undefined

        return number

      sanitizeAxisOptions: (options) ->
        return {type: 'linear'} unless options?

        options.type or= 'linear'

        if options.ticksRotate?
          options.ticksRotate = this.getSanitizedNumber(options.ticksRotate)

        # labelFunction is deprecated and will be remvoed in 2.x
        # please use ticksFormatter instead
        if options.labelFunction?
          options.ticksFormatter = options.labelFunction

        # String to format tick values
        if options.ticksFormat?

          if options.type is 'date'
            # Use d3.time.format as formatter
            options.ticksFormatter = d3.time.format(options.ticksFormat)

          else
            # Use d3.format as formatter
            options.ticksFormatter = d3.format(options.ticksFormat)

          # use the ticksFormatter per default
          # if no tooltip format or formatter is defined
          options.tooltipFormatter ?= options.ticksFormatter

        # String to format tooltip values
        if options.tooltipFormat?

          if options.type is 'date'
            # Use d3.time.format as formatter
            options.tooltipFormatter = d3.time.format(options.tooltipFormat)

          else
            # Use d3.format as formatter
            options.tooltipFormatter = d3.format(options.tooltipFormat)

        if options.ticksInterval?
          options.ticksInterval = this.getSanitizedNumber(options.ticksInterval)

        this.sanitizeExtrema(options)

        return options

# ----


# src/utils/scales.coffee
      createAxes: (svg, dimensions, axesOptions) ->
        createY2Axis = axesOptions.y2?

        width = dimensions.width
        height = dimensions.height

        width = width - dimensions.left - dimensions.right
        height = height - dimensions.top - dimensions.bottom

        x = undefined
        if axesOptions.x.type is 'date'
          x = d3.time.scale().rangeRound([0, width])
        else
          x = d3.scale.linear().rangeRound([0, width])
        xAxis = this.createAxis(x, 'x', axesOptions)

        y = undefined
        if axesOptions.y.type is 'log'
          y = d3.scale.log().clamp(true).rangeRound([height, 0])
        else
          y = d3.scale.linear().rangeRound([height, 0])
        y.clamp(true)
        yAxis = this.createAxis(y, 'y', axesOptions)

        y2 = undefined
        if createY2Axis and axesOptions.y2.type is 'log'
          y2 = d3.scale.log().clamp(true).rangeRound([height, 0])
        else
          y2 = d3.scale.linear().rangeRound([height, 0])
        y2.clamp(true)
        y2Axis = this.createAxis(y2, 'y2', axesOptions)


        style = (group) ->
          group.style(
            'font': '10px Courier'
            'shape-rendering': 'crispEdges'
          )

          group.selectAll('path').style(
            'fill': 'none'
            'stroke': '#000'
          )

        return {
          xScale: x
          yScale: y
          y2Scale: y2
          xAxis: xAxis
          yAxis: yAxis
          y2Axis: y2Axis

          andAddThemIf: (conditions) ->
            if !!conditions.all

              if !!conditions.x
                svg.append('g')
                  .attr('class', 'x axis')
                  .attr('transform', 'translate(0,' + height + ')')
                  .call(xAxis)
                  .call(style)

              if !!conditions.y
                svg.append('g')
                  .attr('class', 'y axis')
                  .call(yAxis)
                  .call(style)

              if createY2Axis and !!conditions.y2
                svg.append('g')
                  .attr('class', 'y2 axis')
                  .attr('transform', 'translate(' + width + ', 0)')
                  .call(y2Axis)
                  .call(style)

            return {
              xScale: x
              yScale: y
              y2Scale: y2
              xAxis: xAxis
              yAxis: yAxis
              y2Axis: y2Axis
            }
          }

      createAxis: (scale, key, options) ->
        sides =
          x: 'bottom'
          y: 'left'
          y2: 'right'

        o = options[key]

        axis = d3.svg.axis()
          .scale(scale)
          .orient(sides[key])
          .tickFormat(o?.ticksFormatter)

        return axis unless o?

        # ticks can be either an array of tick values
        if angular.isArray(o.ticks)
          axis.tickValues(o.ticks)

        # or a number of ticks (approximately)
        else if angular.isNumber(o.ticks)
          axis.ticks(o.ticks)

        # or a range function e.g. d3.time.minute
        else if angular.isFunction(o.ticks)
          axis.ticks(o.ticks, o.ticksInterval)

        return axis

      setScalesDomain: (scales, data, series, svg, options) ->
        this.setXScale(scales.xScale, data, series, options.axes)

        axis = svg.selectAll('.x.axis')
          .call(scales.xAxis)

        if options.axes.x.ticksRotate?
          axis.selectAll('.tick>text')
            .attr('dy', null)
            .attr('transform', 'translate(0,5) rotate(' + options.axes.x.ticksRotate + ' 0,6)')
            .style('text-anchor', if options.axes.x.ticksRotate >= 0 then 'start' else 'end')

        if (series.filter (s) -> s.axis is 'y' and s.visible isnt false).length > 0
          yDomain = this.getVerticalDomain(options, data, series, 'y')
          scales.yScale.domain(yDomain).nice()
          axis = svg.selectAll('.y.axis')
            .call(scales.yAxis)

          if options.axes.y.ticksRotate?
            axis.selectAll('.tick>text')
              .attr('transform', 'rotate(' + options.axes.y.ticksRotate + ' -6,0)')
              .style('text-anchor', 'end')

        if (series.filter (s) -> s.axis is 'y2' and s.visible isnt false).length > 0
          y2Domain = this.getVerticalDomain(options, data, series, 'y2')
          scales.y2Scale.domain(y2Domain).nice()
          axis = svg.selectAll('.y2.axis')
            .call(scales.y2Axis)

          if options.axes.y2.ticksRotate?
            axis.selectAll('.tick>text')
              .attr('transform', 'rotate(' + options.axes.y2.ticksRotate + ' 6,0)')
              .style('text-anchor', 'start')


      getVerticalDomain: (options, data, series, key) ->
        return [] unless o = options.axes[key]

        if o.ticks? and angular.isArray(o.ticks)
          return [o.ticks[0], o.ticks[o.ticks.length - 1]]

        mySeries = series.filter (s) -> s.axis is key and s.visible isnt false

        domain = this.yExtent(
          series.filter (s) -> s.axis is key and s.visible isnt false
          data
          options.stacks.filter (stack) -> stack.axis is key
        )
        if o.type is 'log'
          domain[0] = if domain[0] is 0 then 0.001 else domain[0]

        domain[0] = o.min if o.min?
        domain[1] = o.max if o.max?

        return domain

      yExtent: (series, data, stacks) ->
        minY = Number.POSITIVE_INFINITY
        maxY = Number.NEGATIVE_INFINITY

        groups = []
        stacks.forEach (stack) ->
          groups.push stack.series.map (id) -> (series.filter (s) -> s.id is id)[0]

        series.forEach (series, i) ->
          isInStack = false

          stacks.forEach (stack) ->
            if series.id in stack.series
              isInStack = true

          groups.push([series]) unless isInStack

        groups.forEach (group) ->
          group = group.filter(Boolean)
          minY = Math.min(minY, d3.min(data, (d) ->
            group.reduce ((a, s) -> Math.min(a, d[s.y]) ), Number.POSITIVE_INFINITY
          ))
          maxY = Math.max(maxY, d3.max(data, (d) ->
            group.reduce ((a, s) -> a + d[s.y]), 0
          ))

        if minY is maxY
          if minY > 0
            return [0, minY*2]
          else
            return [minY*2, 0]

        return [minY, maxY]

      setXScale: (xScale, data, series, axesOptions) ->
        domain = this.xExtent(data, axesOptions.x.key)
        if series.filter((s) -> s.type is 'column').length
          this.adjustXDomainForColumns(domain, data, axesOptions.x.key)
        else
          this.adjustXDomainForAll(domain, data, axesOptions.x.key)

        o = axesOptions.x
        domain[0] = o.min if o.min?
        domain[1] = o.max if o.max?

        xScale.domain(domain)

      xExtent: (data, key) ->
        [from, to] = d3.extent(data, (d) -> d[key])

        if from is to
          if from > 0
            return [0, from*2]
          else
            return [from*2, 0]

        return [from, to]

      adjustXDomainForColumns: (domain, data, field) ->
        step = this.getAverageStep(data, field)

        if angular.isDate(domain[0])
          domain[0] = new Date(domain[0].getTime() - step)
          domain[1] = new Date(domain[1].getTime() + step)
        else
          domain[0] = domain[0] - step
          domain[1] = domain[1] + step

      adjustXDomainForAll: (domain, data, field) ->
        step = this.getAverageStep(data, field)

        if angular.isDate(domain[0])
          domain[0] = new Date(domain[0].getTime() - step)
          domain[1] = new Date(domain[1].getTime() + step)
        else
          domain[0] = domain[0] - step
          domain[1] = domain[1] + step

      getAverageStep: (data, field) ->
        return 0 unless data.length > 1
        sum = 0
        n = data.length - 1
        i = 0
        while i < n
          sum += data[i + 1][field] - data[i][field]
          i++

        return sum/n

      haveSecondYAxis: (series) ->
        return !series.every (s) -> s.axis isnt 'y2'

      drawGridAxes: (svg, dimensions, axesOptions, axes) ->
        width = dimensions.width
        height = dimensions.height

        width = width - dimensions.left - dimensions.right
        height = height - dimensions.top - dimensions.bottom
        if axesOptions.isGridHorizontalLinesVisible is true
          svg.selectAll("line.y")
            .data(axes['y2Scale'].ticks())
            .enter().append("svg:line")
            .attr("class", "y")
            .attr("x1", 0)
            .attr("x2", width)
            .attr("y1", axes['y2Scale'])
            .attr("y2", axes['y2Scale'])
            .attr("stroke", "#ccc")

        if axesOptions.isGridVerticalLinesVisible is true
          svg.selectAll("line.x")
            .data(axes['xScale'].ticks())
            .enter().append("svg:line")
            .attr("class", "x")
            .attr("x1", axes['xScale'])
            .attr("x2", axes['xScale'])
            .attr("y1", 0)
            .attr("y2", height)
            .attr("stroke", "#ccc")

# ----


# src/utils/scrubber.coffee
      showScrubber: (svg, glass, axes, data, options, dispatch, columnWidth, dimensions) ->
        that = this
        glass.on('mousemove', ->
          svg.selectAll('.glass-container').attr('opacity', 1)
          that.updateScrubber(svg, d3.mouse(this), axes, data, options, dispatch, columnWidth, dimensions)
        )
        glass.on('mouseout', ->
          glass.on('mousemove', null)
          svg.selectAll('.glass-container').attr('opacity', 0)
        )

      getClosestPoint: (values, xValue) ->
        # Create a bisector
        xBisector = d3.bisector( (d) -> d.x ).left
        i = xBisector(values, xValue)

        # Return min and max if index is out of bounds
        return values[0] if i is 0
        return values[values.length - 1] if i > values.length - 1

        # get element before bisection
        d0 = values[i - 1]

        # get element after bisection
        d1 = values[i]

        # get nearest element
        d = if xValue - d0.x > d1.x - xValue then d1 else d0

        return d

      updateScrubber: (svg, [x, y], axes, data, options, dispatch, columnWidth, dimensions) ->
        ease = (element) -> element.transition().duration(50)
        that = this
        positions = []

        data.forEach (series, index) ->
          item = svg.select(".scrubberItem.series_#{index}")

          if options.series[index].visible is false
            item.attr('opacity', 0)
            return

          item.attr('opacity', 1)

          xInvert = axes.xScale.invert(x)
          yInvert = axes.yScale.invert(y)

          v = that.getClosestPoint(series.values, xInvert)
          dispatch.focus(v, series.values.indexOf(v), [xInvert, yInvert])
          text = v.x + ' : ' + v.y
          position = series.values.indexOf(v)
          serieData = series.values[position]
          if options.tooltip.formatter
            text = options.tooltip.formatter(v.x, v.y, options.series[index], serieData)

          if options.series[series.index].labelIsUpdatedWithTooltip
            that.updateTextLegendWithTooltip(svg, index, text)
            that.updateTranslateLegends(svg, options.series[series.index], dimensions)

          if options.series[index].isTooltipDisplayed is false
            item.attr('opacity', 0)
            return

          if options.tooltip.type is 'complete'
            right = item.select('.rightTT')
            rText = right.select('text')
            rText.text(text)

            left = item.select('.leftTT')
            lText = left.select('text')
            lText.text(text)

            sizes =
              right: that.getTextBBox(rText[0][0]).width + 5
              left: that.getTextBBox(lText[0][0]).width + 5

          side = if series.axis is 'y2' then 'right' else 'left'

          xPos = axes.xScale(v.x)

          if options.tooltip.type is 'complete'
            if side is 'left'
              side = 'right' if xPos + that.getTextBBox(lText[0][0]).x - 10 < 0
            else if side is 'right'
              side = 'left' if xPos + sizes.right > that.getTextBBox(svg.select('.glass')[0][0]).width

            if side is 'left'
              ease(right).attr('opacity', 0)
              ease(left).attr('opacity', 1)
            else
              ease(right).attr('opacity', 1)
              ease(left).attr('opacity', 0)

          positions[index] = {index, x: xPos, y: axes[v.axis + 'Scale'](v.y + v.y0), side, sizes}

          # Use a coloring function if defined, else use a color string value
          color = if angular.isFunction(series.color) \
            then series.color(v, series.values.indexOf(v)) else series.color

          # Color the elements of the scrubber
          item.selectAll('circle').attr('stroke', color)
          item.selectAll('path').attr('fill', color)

        positions = this.preventOverlapping(positions)

        tickLength = Math.max(15, 100/columnWidth)

        data.forEach (series, index) ->
          if options.series[index].visible is false
            return

          if options.series[index].isTooltipDisplayed is false
            return

          p = positions[index]
          item = svg.select(".scrubberItem.series_#{index}")

          if options.tooltip.type is 'complete'
            tt = item.select(".#{p.side}TT")

          xOffset = (if p.side is 'left' then series.xOffset else (-series.xOffset))

          if options.tooltip.type is 'complete'
            tt.select('text')
              .attr('transform', ->
                if p.side is 'left'
                  return "translate(#{-3 - tickLength - xOffset}, #{p.labelOffset+3})"
                else
                  return "translate(#{4 + tickLength + xOffset}, #{p.labelOffset+3})"
              )

            tt.select('path')
              .attr(
                'd',
                that.getScrubberPath(
                  p.sizes[p.side] + 1,
                  p.labelOffset,
                  p.side,
                  tickLength + xOffset
                )
              )

          ease(item).attr(
            'transform': """
              translate(#{positions[index].x + series.xOffset}, #{positions[index].y})
            """
          )


      getScrubberPath: (w, yOffset, side, padding) ->
        h = 18
        p = padding
        w = w
        xdir = if side is 'left' then 1 else -1

        ydir = 1
        if yOffset isnt 0
          ydir = Math.abs(yOffset)/yOffset

        yOffset or= 0

        return [
          "m0 0"

          "l#{xdir} 0"
          "l0 #{yOffset + ydir}"
          "l#{-xdir*(p + 1)} 0"

          "l0 #{-h/2 - ydir}"
          "l#{-xdir*w} 0"
          "l0 #{h}"
          "l#{xdir*w} 0"
          "l0 #{-h/2 - ydir}"

          "l#{xdir*(p - 1)} 0"
          "l0 #{-yOffset + ydir}"
          "l1 0"

          "z"
        ].join('')


      preventOverlapping: (positions) ->
        h = 18

        abscissas = {}
        positions.forEach (p) ->
          abscissas[p.x] or= {left: [], right: []}
          abscissas[p.x][p.side].push(p)

        getNeighbours = (side) ->
          neighbours = []
          for x, sides of abscissas
            if sides[side].length is 0
              continue

            neighboursForX = {}
            while sides[side].length > 0
              p = sides[side].pop()
              foundNeighbour = false
              for y, neighbourhood of neighboursForX
                if +y - h <= p.y <= +y + h
                  neighbourhood.push(p)
                  foundNeighbour = true

              neighboursForX[p.y] = [p] unless foundNeighbour

            neighbours.push(neighboursForX)
          return neighbours

        offset = (neighboursForAbscissas) ->
          step = 20
          for abs, xNeighbours of neighboursForAbscissas
            for y, neighbours of xNeighbours
              n = neighbours.length
              if n is 1
                neighbours[0].labelOffset = 0
                continue
              neighbours = neighbours.sort (a, b) -> a.y - b.y
              if n%2 is 0
                start = -(step/2)*(n/2)
              else
                start = -(n-1)/2*step

              neighbours.forEach (neighbour, i) -> neighbour.labelOffset = start + step*i
          return


        offset(getNeighbours('left'))
        offset(getNeighbours('right'))

        return positions

# ----


# src/utils/tooltips.coffee
      getTooltipHandlers: (options) ->
        if options.tooltip.mode is 'scrubber'
          return {
            onChartHover: angular.bind(this, this.showScrubber)
          }
        else
          return {
            onMouseOver: angular.bind(this, this.onMouseOver)
            onMouseOut: angular.bind(this, this.onMouseOut)
          }

      styleTooltip: (d3TextElement) ->
        # This needs to be defined as .attr() otherwise
        # FF will not render and compute it properly
        return d3TextElement.attr({
          'font-family': 'monospace'
          'font-size': 10
          'fill': 'white'
          'text-rendering': 'geometric-precision'
        })

      addTooltips: (svg, dimensions, axesOptions) ->
        width = dimensions.width
        height = dimensions.height

        width = width - dimensions.left - dimensions.right
        height = height - dimensions.top - dimensions.bottom

        w = 24
        h = 18
        p = 5

        xTooltip = svg.append('g')
          .attr(
            'id': 'xTooltip'
            'class': 'xTooltip'
            'opacity': 0
          )

        xTooltip.append('path')
          .attr('transform', "translate(0,#{(height + 1)})")

        this.styleTooltip(xTooltip.append('text')
          .style('text-anchor', 'middle')
          .attr(
            'width': w
            'height': h
            'transform': 'translate(0,' + (height + 19) + ')'
          )
        )

        yTooltip = svg.append('g')
          .attr(
            id: 'yTooltip'
            class: 'yTooltip'
            opacity: 0
          )

        yTooltip.append('path')
        this.styleTooltip(yTooltip.append('text')
          .attr(
            'width': h
            'height': w
          )
        )

        if axesOptions.y2?
          y2Tooltip = svg.append('g')
            .attr(
              'id': 'y2Tooltip'
              'class': 'y2Tooltip'
              'opacity': 0
              'transform': 'translate(' + width + ',0)'
            )

          y2Tooltip.append('path')

          this.styleTooltip(y2Tooltip.append('text')
            .attr(
              'width': h
              'height': w
            )
          )

      onMouseOver: (svg, event, axesOptions) ->
        this.updateXTooltip(svg, event, axesOptions.x)

        if event.series.axis is 'y2'
          this.updateY2Tooltip(svg, event, axesOptions.y2)
        else
          this.updateYTooltip(svg, event, axesOptions.y)

      onMouseOut: (svg) ->
        this.hideTooltips(svg)

      updateXTooltip: (svg, {x, datum, series}, xAxisOptions) ->
        xTooltip = svg.select("#xTooltip")

        xTooltip.transition()
          .attr(
            'opacity': 1.0
            'transform': "translate(#{x},0)"
          )

        _f = xAxisOptions.tooltipFormatter
        textX = if _f then _f(datum.x) else datum.x

        label = xTooltip.select('text')
        label.text(textX)

        # Use a coloring function if defined, else use a color string value
        color = if angular.isFunction(series.color) \
          then series.color(datum, series.values.indexOf(datum)) else series.color

        xTooltip.select('path')
          .style('fill', color)
          .attr('d', this.getXTooltipPath(label[0][0]))

      getXTooltipPath: (textElement) ->
        w = Math.max(this.getTextBBox(textElement).width, 15)
        h = 18
        p = 5 # Size of the 'arrow' that points towards the axis

        return 'm-' + w/2 + ' ' + p + ' ' +
          'l0 ' + h + ' ' +
          'l' + w + ' 0 ' +
          'l0 ' + '' + (-h) +
          'l' + (-w/2 + p) + ' 0 ' +
          'l' + (-p) + ' -' + h/4 + ' ' +
          'l' + (-p) + ' ' + h/4 + ' ' +
          'l' + (-w/2 + p) + ' 0z'

      updateYTooltip: (svg, {y, datum, series}, yAxisOptions) ->
        yTooltip = svg.select("#yTooltip")
        yTooltip.transition()
          .attr(
            'opacity': 1.0
            'transform': "translate(0, #{y})"
          )

        _f = yAxisOptions.tooltipFormatter
        textY = if _f then _f(datum.y) else datum.y

        label = yTooltip.select('text')
        label.text(textY)
        w = this.getTextBBox(label[0][0]).width + 5

        label.attr(
          'transform': 'translate(' + (- w - 2) + ',3)'
          'width': w
        )

        # Use a coloring function if defined, else use a color string value
        color = if angular.isFunction(series.color) \
          then series.color(datum, series.values.indexOf(datum)) else series.color

        yTooltip.select('path')
          .style('fill', color)
          .attr('d', this.getYTooltipPath(w))

      updateY2Tooltip: (svg, {y, datum, series}, yAxisOptions) ->
        y2Tooltip = svg.select("#y2Tooltip")
        y2Tooltip.transition()
          .attr('opacity', 1.0)

        _f = yAxisOptions.tooltipFormatter
        textY = if _f then _f(datum.y) else datum.y

        label = y2Tooltip.select('text')
        label.text(textY)
        w = this.getTextBBox(label[0][0]).width + 5
        label.attr(
          'transform': 'translate(7, ' + (parseFloat(y) + 3) + ')'
          'w': w
        )

        # Use a coloring function if defined, else use a color string value
        color = if angular.isFunction(series.color) \
          then series.color(datum, series.values.indexOf(datum)) else series.color

        y2Tooltip.select('path')
          .style('fill', color)
          .attr(
            'd': this.getY2TooltipPath(w)
            'transform': 'translate(0, ' + y + ')'
          )

      getYTooltipPath: (w) ->
        h = 18
        p = 5 # Size of the 'arrow' that points towards the axis

        return 'm0 0' +
          'l' + (-p) + ' ' + (-p) + ' ' +
          'l0 ' + (-h/2 + p) + ' ' +
          'l' + (-w) + ' 0 ' +
          'l0 ' + h + ' ' +
          'l' + w + ' 0 ' +
          'l0 ' + (-h/2 + p) +
          'l' + (-p) + ' ' + p + 'z'

      getY2TooltipPath: (w) ->
        h = 18
        p = 5 # Size of the 'arrow' that points towards the axis

        return 'm0 0' +
          'l' + p + ' ' + p + ' ' +
          'l0 ' + (h/2 - p) + ' ' +
          'l' + w + ' 0 ' +
          'l0 ' + (-h) + ' ' +
          'l' + (-w) + ' 0 ' +
          'l0 ' + (h/2 - p) + ' ' +
          'l' + (-p) + ' ' + p + 'z'

      hideTooltips: (svg) ->
        svg.select("#xTooltip")
          .transition()
          .attr('opacity', 0)

        svg.select("#yTooltip")
          .transition()
          .attr('opacity', 0)

        svg.select("#y2Tooltip")
          .transition()
          .attr('opacity', 0)

# ----


# src/utils/triangles.coffee
    drawTriangles: (svg, axes, data, columnWidth, options, handlers, dimensions) ->
      this.drawDailyTriangles(svg, axes, data)
      this.drawWeeklyTriangles(svg, axes, data)
      this.drawMonthlyTriangles(svg, axes, data)
      this.drawTriangleLegend(svg, axes, data)
      return this

    drawDailyTriangles: (svg, axes, data) ->
      that = this

      data = data.filter (s) -> s.type is 'dailyTriangles'

      if data.length == 0 or data[0].dailyTrianglesData is null or data[0].dailyTrianglesData.length == 0
        return this

      triangleGroup = svg.select('.content').selectAll('.dailyTrianglesGroup')
        .data(data)
        .enter().append('g')
        .attr('class', (s) -> 'dailyTrianglesGroup series_' + s.index)

      this.drawDailyTrianglePolygons(triangleGroup, axes)
      this.drawDailyTriangleWords(triangleGroup, axes)

    drawDailyTrianglePolygons: (triangleGroup, axes) ->
      that = this

      triangleGroup.selectAll('dailyTriangles').data((d) -> d.dailyTrianglesData)
        .enter().append('svg:polygon')
        .attr(
          'points', (d) -> that.getTrianglePoints(d.isUp)
        )
        .attr('transform', (d) ->
          x = axes.xScale(d.x) - 8
          if d.chartType is 'Line'
            if d.isUp is true
              y = axes.y2Scale(d.closeValue) + 2
            else
              y = axes.y2Scale(d.closeValue) - 16
          else
            if d.isUp is true
              y = axes.y2Scale(d.lowValue) + 1
            else
              y = axes.y2Scale(d.highValue) - 16
          return 'translate('+ x + ',' + y + ')'
        )
        .attr('fill', (d) ->
          if d.isUp is true
            return '#009933'
          else
            return '#CC0000'
        )

    drawDailyTriangleWords: (triangleGroup, axes) ->
      that = this

      triangleGroup.selectAll('dailyWords').data((d) -> d.dailyTrianglesData)
      .enter().append('svg:path')
      .attr(
        'd', (d) -> that.getDailyTrianglePath(d.isUp)
      )
      .attr('transform', (d) ->
        x = axes.xScale(d.x) - 8
        if d.chartType is 'Line'
          if d.isUp is true
            y = axes.y2Scale(d.closeValue) + 2
          else
            y = axes.y2Scale(d.closeValue) - 16
        else
          if d.isUp is true
            y = axes.y2Scale(d.lowValue) + 1
          else
            y = axes.y2Scale(d.highValue) - 16
        return 'translate('+ x + ',' + y + ')'
      )
      .attr('fill', '#FFFFFF')

    getDailyTrianglePath: (isUp) ->
      if isUp is true
        path = 'M4.5,7.5h3.495c0.687,0,1.241,0.086,1.667,0.258c0.423,0.172,0.773,0.419,1.049,0.742' +
          'c0.279,0.318,0.479,0.695,0.602,1.123c0.127,0.424,0.188,0.875,0.188,1.354c0,0.748-0.091,1.33-0.277,1.739' +
          'c-0.184,0.412-0.439,0.759-0.771,1.036c-0.325,0.277-0.678,0.464-1.057,0.559C8.878,14.436,8.412,14.5,7.995,14.5H4.5V7.5z' +
          'M6.851,9.086v3.823h0.576c0.492,0,0.841-0.05,1.048-0.149c0.207-0.102,0.371-0.275,0.487-0.525c0.118-0.25,0.177-0.655,0.177-1.217' +
          'c0-0.74-0.132-1.248-0.394-1.521c-0.263-0.274-0.699-0.413-1.31-0.413H6.851V9.086z'
      else
        path = 'M4.5,1.5h3.495c0.687,0,1.241,0.086,1.667,0.258c0.423,0.172,0.775,0.419,1.049,0.742' +
          'c0.279,0.319,0.479,0.695,0.602,1.123C11.439,4.047,11.5,4.498,11.5,4.976c0,0.749-0.091,1.33-0.277,1.74' +
          'c-0.184,0.412-0.439,0.759-0.771,1.036C10.126,8.03,9.773,8.216,9.395,8.311C8.878,8.436,8.412,8.5,7.995,8.5H4.5V1.5z M6.851,3.086' +
          'v3.823h0.576c0.492,0,0.841-0.05,1.048-0.149c0.207-0.102,0.371-0.276,0.487-0.525c0.118-0.25,0.177-0.656,0.177-1.217' +
          'c0-0.74-0.132-1.248-0.394-1.521c-0.263-0.275-0.699-0.413-1.31-0.413H6.851V3.086z'
      return path

    drawWeeklyTriangles: (svg, axes, data) ->
      that = this

      data = data.filter (s) -> s.type is 'weeklyTriangles'

      if data.length == 0 or data[0].weeklyTrianglesData is null or data[0].weeklyTrianglesData.length == 0
        return this

      triangleGroup = svg.select('.content').selectAll('.weeklyTrianglesGroup')
      .data(data)
      .enter().append('g')
      .attr('class', (s) -> 'weeklyTrianglesGroup series_' + s.index)

      this.drawWeeklyTrianglePolygons(triangleGroup, axes)
      this.drawWeeklyTriangleWords(triangleGroup, axes)

    drawWeeklyTrianglePolygons: (triangleGroup, axes) ->
      that = this

      triangleGroup.selectAll('weeklyTriangles').data((d) -> d.weeklyTrianglesData)
      .enter().append('svg:polygon')
      .attr(
        'points', (d) -> that.getTrianglePoints(d.isUp)
      )
      .attr('transform', (d) ->
        x = axes.xScale(d.x) - 8
        if d.chartType is 'Line'
          if d.isUp is true
            y = axes.y2Scale(d.closeValue) + 2
          else
            y = axes.y2Scale(d.closeValue) - 16
        else
          if d.isUp is true
            y = axes.y2Scale(d.lowValue) + 1
          else
            y = axes.y2Scale(d.highValue) - 16
        return 'translate('+ x + ',' + y + ')'
      )
      .attr('fill', (d) ->
        if d.isUp is true
          return '#009933'
        else
          return '#CC0000'
      )

    drawWeeklyTriangleWords: (triangleGroup, axes) ->
      that = this

      triangleGroup.selectAll('weeklyWords').data((d) -> d.weeklyTrianglesData)
      .enter().append('svg:path')
      .attr(
        'd', (d) -> that.getWeeklyTrianglePath(d.isUp)
      )
      .attr('transform', (d) ->
        x = axes.xScale(d.x) - 8
        if d.chartType is 'Line'
          if d.isUp is true
            y = axes.y2Scale(d.closeValue) + 2
          else
            y = axes.y2Scale(d.closeValue) - 16
        else
          if d.isUp is true
            y = axes.y2Scale(d.lowValue) + 1
          else
            y = axes.y2Scale(d.highValue) - 16
        return 'translate('+ x + ',' + y + ')'
      )
      .attr('fill', '#FFFFFF')

    getWeeklyTrianglePath: (isUp) ->
      if isUp is true
        path = 'M3,7.5h2.098l0.755,3.918L6.959,7.5H9.05l1.108,3.913L10.912,7.5H13l-1.577,7H9.258l-1.255-4.407L6.754,14.5' +
          'H4.589L3,7.5z'
      else
        path = 'M3,1.5h2.098l0.755,3.917L6.959,1.5H9.05l1.108,3.913L10.912,1.5H13l-1.577,7H9.258L8.002,4.093L6.754,8.5' +
          'H4.589L3,1.5z'
      return path

    drawMonthlyTriangles: (svg, axes, data) ->
      that = this

      data = data.filter (s) -> s.type is 'monthlyTriangles'

      if data.length == 0 or data[0].monthlyTrianglesData is null or data[0].monthlyTrianglesData.length == 0
        return this

      triangleGroup = svg.select('.content').selectAll('.monthlyTrianglesGroup')
      .data(data)
      .enter().append('g')
      .attr('class', (s) -> 'monthlyTrianglesGroup series_' + s.index)

      this.drawMonthlyTrianglePolygons(triangleGroup, axes)
      this.drawMonthlyTriangleWords(triangleGroup, axes)

    drawMonthlyTrianglePolygons: (triangleGroup, axes) ->
      that = this

      triangleGroup.selectAll('monthlyTriangles').data((d) -> d.monthlyTrianglesData)
      .enter().append('svg:polygon')
      .attr(
        'points', (d) -> that.getTrianglePoints(d.isUp)
      )
      .attr('transform', (d) ->
        x = axes.xScale(d.x) - 8
        if d.chartType is 'Line'
          if d.isUp is true
            y = axes.y2Scale(d.closeValue) + 2
          else
            y = axes.y2Scale(d.closeValue) - 16
        else
          if d.isUp is true
            y = axes.y2Scale(d.lowValue) + 1
          else
            y = axes.y2Scale(d.highValue) - 16
        return 'translate('+ x + ',' + y + ')'
      )
      .attr('fill', (d) ->
        if d.isUp is true
          return '#009933'
        else
          return '#CC0000'
      )

    drawMonthlyTriangleWords: (triangleGroup, axes) ->
      that = this

      triangleGroup.selectAll('monthlyWords').data((d) -> d.monthlyTrianglesData)
      .enter().append('svg:path')
      .attr(
        'd', (d) -> that.getMonthlyTrianglePath(d.isUp)
      )
      .attr('transform', (d) ->
        x = axes.xScale(d.x) - 8
        if d.chartType is 'Line'
          if d.isUp is true
            y = axes.y2Scale(d.closeValue) + 2
          else
            y = axes.y2Scale(d.closeValue) - 16
        else
          if d.isUp is true
            y = axes.y2Scale(d.lowValue) + 1
          else
            y = axes.y2Scale(d.highValue) - 16
        return 'translate('+ x + ',' + y + ')'
      )
      .attr('fill', '#FFFFFF')

    getMonthlyTrianglePath: (isUp) ->
      if isUp is true
        path = 'M3.5,7.5h3.251l1.253,4.258L9.25,7.5h3.25v7h-2.024V9.162L8.914,14.5H7.081L5.523,9.162V14.5H3.5V7.5z'
      else
        path = 'M3.5,1.5h3.251l1.253,4.258L9.25,1.5h3.25v7h-2.024V3.162L8.914,8.5H7.081L5.523,3.162V8.5H3.5V1.5z'
      return path

    getTrianglePoints: (isUp) ->
      if isUp is true
        points = '16,15.5 7.999,0.5 0,15.5'
      else
        points = '0,0.5 7.999,15.5 16,0.5'
      return points

# ----


# src/utils/trianglesLegend.coffee
    drawTriangleLegend: (svg, axes, data) ->
      that = this

      data = data.filter (s) -> s.type is 'trianglesLegend'
      if data.length == 0 or data[0].trianglesLegendData is null or data[0].trianglesLegendData is undefined
        return this

      legend = svg.select('.content').selectAll('.trianglesLegend')
        .data(data)
        .enter().append('g')
        .attr('class', 'trianglesLegend')

      this.drawTriangleLegendRectangle(legend, data)

      this.drawMonthlyTriangleLegendPolygon(legend, data)
      this.drawMonthlyTriangleLegendWord(legend, data)
      this.drawMonthlyTriangleLegendText(legend, data)

      this.drawDailyTriangleLegendPolygon(legend, data)
      this.drawDailyTriangleLegendWord(legend, data)
      this.drawDailyTriangleLegendText(legend, data)

      this.drawWeeklyTriangleLegendPolygon(legend, data)
      this.drawWeeklyTriangleLegendWord(legend, data)
      this.drawWeeklyTriangleLegendText(legend, data)

      this.drawTraingleLegendDivider(legend, data)

      this.drawTriangleLegendScoreLabel(legend, data)
      this.drawTriangleLegendScoreData(legend, data)

    drawTriangleLegendRectangle: (legend, data) ->
      legend.selectAll('trianglesLegendRect').data(data).enter().append('svg:rect')
        .attr(
          x: 0
          y: 0
          width: 110
          height: 92
          fill: '#F5F5F5'
        )

    drawMonthlyTriangleLegendPolygon: (legend, data) ->
      that = this
      legend.selectAll('monthlyTriangleLegend').data(data)
        .enter().append('svg:polygon')
        .attr(
          'points', (d) -> that.getTrianglePoints(d.trianglesLegendData.monthlyTrianglesLegendData.isUp)
        )
        .attr('transform', (d) ->
          x = 10
          if d.trianglesLegendData.monthlyTrianglesLegendData.isUp is true
            y = 8
          else
            y = 12
          return 'translate('+ x + ',' + y + ')'
        )
        .attr('fill', (d) ->
          if d.trianglesLegendData.monthlyTrianglesLegendData.isUp is true
            return '#009933'
          else
            return '#CC0000'
        )

    drawMonthlyTriangleLegendWord: (legend, data) ->
      that = this
      legend.selectAll('monthlyTriangleLegend').data(data)
        .enter().append('svg:path')
        .attr(
          'd', (d) -> that.getMonthlyTrianglePath(d.trianglesLegendData.monthlyTrianglesLegendData.isUp)
        )
        .attr('transform', (d) ->
          x = 10
          if d.trianglesLegendData.monthlyTrianglesLegendData.isUp is true
            y = 8
          else
            y = 12
          return 'translate('+ x + ',' + y + ')'
        )
        .attr('fill', '#FFFFFF')

    drawMonthlyTriangleLegendText: (legend, data) ->
      that = this
      legend.selectAll('monthlyTriangleLegend').data(data)
        .enter().append('svg:text')
        .attr('font-family': 'Courier')
        .attr('font-size': 12)
        .attr('transform': 'translate(35, 22)')
        .attr('text-rendering': 'geometric-precision')
        .text((d)-> d.trianglesLegendData.monthlyTrianglesLegendData.value)

    drawWeeklyTriangleLegendPolygon: (legend, data) ->
      that = this
      legend.selectAll('weeklyTriangleLegend').data(data)
        .enter().append('svg:polygon')
        .attr(
          'points', (d) -> that.getTrianglePoints(d.trianglesLegendData.weeklyTrianglesLegendData.isUp)
        )
        .attr('transform', (d) ->
          x = 10
          if d.trianglesLegendData.weeklyTrianglesLegendData.isUp is true
            y = 28
          else
            y = 31
          return 'translate('+ x + ',' + y + ')'
        )
        .attr('fill', (d) ->
          if d.trianglesLegendData.weeklyTrianglesLegendData.isUp is true
            return '#009933'
          else
            return '#CC0000'
        )

    drawWeeklyTriangleLegendWord: (legend, data) ->
      that = this
      legend.selectAll('weeklyTriangleLegend').data(data)
        .enter().append('svg:path')
        .attr(
          'd', (d) -> that.getWeeklyTrianglePath(d.trianglesLegendData.weeklyTrianglesLegendData.isUp)
        )
        .attr('transform', (d) ->
          x = 10
          if d.trianglesLegendData.weeklyTrianglesLegendData.isUp is true
            y = 28
          else
            y = 31
          return 'translate('+ x + ',' + y + ')'
        )
        .attr('fill', '#FFFFFF')

    drawWeeklyTriangleLegendText: (legend, data) ->
      that = this
      legend.selectAll('weeklyTriangleLegend').data(data)
        .enter().append('svg:text')
        .attr('font-family': 'Courier')
        .attr('font-size': 12)
        .attr('transform': 'translate(35, 42)')
        .attr('text-rendering': 'geometric-precision')
        .text((d)-> d.trianglesLegendData.weeklyTrianglesLegendData.value)

    drawDailyTriangleLegendPolygon: (legend, data) ->
      that = this
      legend.selectAll('dailyTriangleLegend').data(data)
        .enter().append('svg:polygon')
        .attr(
          'points', (d) -> that.getTrianglePoints(d.trianglesLegendData.dailyTrianglesLegendData.isUp)
        )
        .attr('transform', (d) ->
          x = 10
          if d.trianglesLegendData.dailyTrianglesLegendData.isUp is true
            y = 48
          else
            y = 52
          return 'translate('+ x + ',' + y + ')'
        )
        .attr('fill', (d) ->
          if d.trianglesLegendData.dailyTrianglesLegendData.isUp is true
            return '#009933'
          else
            return '#CC0000'
        )

    drawDailyTriangleLegendWord: (legend, data) ->
      that = this
      legend.selectAll('dailyTriangleLegend').data(data)
        .enter().append('svg:path')
        .attr(
          'd', (d) -> that.getDailyTrianglePath(d.trianglesLegendData.dailyTrianglesLegendData.isUp)
        )
        .attr('transform', (d) ->
          x = 10
          if d.trianglesLegendData.dailyTrianglesLegendData.isUp is true
            y = 48
          else
            y = 52
          return 'translate('+ x + ',' + y + ')'
        )
        .attr('fill', '#FFFFFF')

    drawDailyTriangleLegendText: (legend, data) ->
      that = this
      legend.selectAll('dailyTriangleLegend').data(data)
        .enter().append('svg:text')
        .attr('font-family': 'Courier')
        .attr('font-size': 12)
        .attr('transform': 'translate(35, 62)')
        .attr('text-rendering': 'geometric-precision')
        .text((d)-> d.trianglesLegendData.dailyTrianglesLegendData.value)

    drawTraingleLegendDivider: (legend, data) ->
      legend.selectAll('dividerTriangleLegend').data(data)
        .enter().append('svg:line')
        .attr(
          x1: 5
          x2: 105
          y1: 70
          y2: 70
          stroke: '#DDDDDD'
        )

    drawTriangleLegendScoreLabel: (legend, data) ->
      legend.selectAll('scoreTriangleLegend').data(data)
        .enter().append('svg:text')
        .attr('font-family': 'Courier')
        .attr('font-size': 14)
        .attr('transform': 'translate(10, 85)')
        .attr('text-rendering': 'geometric-precision')
        .attr('font-weight', 'bolder')
        .text('Score')

    drawTriangleLegendScoreData: (legend, data) ->
      legend.selectAll('scoreTriangleLegend').data(data)
        .enter().append('svg:text')
        .attr('font-family': 'Courier')
        .attr('font-size': 14)
        .attr('transform': 'translate(55, 85)')
        .attr('text-rendering': 'geometric-precision')
        .attr('font-weight', 'bolder')
        .attr('fill': (d) ->
          if d.trianglesLegendData.scoreLegendData.isUp is true
            return '#43A943'
          else
            return '#CA2F2F'
        )
        .text((d) ->
          if d.trianglesLegendData.scoreLegendData.isUp is true
            return '+' + d.trianglesLegendData.scoreLegendData.value
          else
            return d.trianglesLegendData.scoreLegendData.value
        )

# ----


# src/utils/trianglesTooltip.coffee
    drawTriangleTooltip: (svg, axes, data) ->
      that = this

      tooltip = svg.select('.content').selectAll('.trianglesTooltip')
        .data(data)
        .enter().append('g')
        .attr('class', 'trianglesTooltip')

    drawTriangleTooltipRectangle: (tooltip, data) ->
      tooltip.selectAll('trianglesTooltipRect').data(data).enter().append('svg:rect')
      .attr(
          x: 0
          y: 0
          width: 100
          height: 100
          fill: '#F5F5F5'
        )
# ----
  }
])

# ----
