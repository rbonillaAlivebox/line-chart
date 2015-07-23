    drawIntraday: (svg, axes, data, options, handlers, dimensions) ->
      that = this
      data = data.filter (s) -> s.type is 'intraday'

      if data.length == 0
        return this

      intradayChart = svg.select('.content').selectAll('intradayGroup')
      .data(data)
      .enter().append('g')
      .attr('class', 'intradayGroup')

      intradayChart.selectAll('line.stem').data((d) -> d.intradayData)
      .enter().append('svg:line')
      .attr('class', (d) -> 'stem')
      .attr(
        x1: (d) -> axes.xScale(d.x1)
        x2: (d) -> axes.xScale(d.x2)
        y1: (d) -> axes.y2Scale(d.y1)
        y2: (d) -> axes.y2Scale(d.y2)
      )
      .attr('stroke', '#FF0000')

      return this
