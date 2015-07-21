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
