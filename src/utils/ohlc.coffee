      drawOhlc: (svg, axes, data, columnWidth, options, handlers, dimensions) ->
        that = this
        height = dimensions.height
        width = dimensions.width

        data = data.filter (s) -> s.type is 'ohlc'

        if data.length == 0
          return this

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
              return tmpX - 20
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
              return tmpX + 20
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
