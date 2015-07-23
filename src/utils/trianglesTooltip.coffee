    drawTriangleTooltip: (svg, axes, data) ->
      that = this

      data = data.filter (s) -> s.type is 'trianglesLegend'
      if data.length == 0 or data[0].trianglesLegendData is null or data[0].trianglesLegendData is undefined
        return this

      svg.append('g')
        .attr('class', 'trianglesTooltip')
        .attr('transform', 'translate(0, 0)')
        .attr('opacity', 0)
        .data(data)
        .enter().append('g')
        .on('mouseout', (d) -> that.triangleMouseOutHandler(svg))

      tooltip = svg.select('.trianglesTooltip').selectAll('trianglesTooltip')
      #tooltip = svg.select('.content').selectAll('.trianglesTooltip')
        .data(data)
        .enter().append('g')

      this.drawTriangleTooltipRectangle(tooltip, data)
      this.drawTriangleTooltipPositiveLine(tooltip, data)
      this.drawTriangleTooltipNegativeLine(tooltip, data)
      this.drawTriangleTooltipDateText(tooltip, data)
      this.drawTriangleTooltipDataText(tooltip, data)

    drawTriangleTooltipRectangle: (tooltip, data) ->
      tooltip.selectAll('trianglesTooltipRect').data(data).enter().append('svg:rect')
        .attr(
          x: 0
          y: 0
          width: 100
          height: 45
          fill: '#F5F5F5'
        )

    drawTriangleTooltipPositiveLine: (tooltip, data) ->
      tooltip.selectAll('trianglesTooltipPositiveLine').data(data)
        .enter().append('svg:line')
        .attr('class', 'trianglesTooltipPositiveLine')
        .attr('opacity', 0)
        .attr(
          x1: 0
          y1: 0
          x2: 100
          y2: 0
          stroke: '#009933'
        )
        .attr('stroke-width', 4)

    drawTriangleTooltipNegativeLine: (tooltip, data) ->
      tooltip.selectAll('trianglesTooltipNegativeLine').data(data)
        .enter().append('svg:line')
        .attr('class', 'trianglesTooltipNegativeLine')
        .attr('opacity', 0)
        .attr(
          x1: 0
          y1: 44
          x2: 100
          y2: 44
          stroke: '#CC0000'
        )
        .attr('stroke-width', 4)

    drawTriangleTooltipDateText: (tooltip, data) ->
      tooltip.selectAll('trianglesTooltipDateText').data(data)
        .enter().append('svg:text')
        .attr('class', 'trianglesTooltipDateText')
        .attr('font-family': 'Courier')
        .attr('font-size': 12)
        .attr('transform': 'translate(32, 17)')
        .attr('text-rendering': 'geometric-precision')
        .text(' ')

    drawTriangleTooltipDataText: (tooltip, data) ->
      tooltip.selectAll('trianglesTooltipDataText').data(data)
        .enter().append('svg:text')
        .attr('class', 'trianglesTooltipDataText')
        .attr('font-family': 'Courier')
        .attr('font-size': 12)
        .attr('transform': 'translate(12, 35)')
        .attr('text-rendering': 'geometric-precision')
        .text('')

    triangleMouseOverHandler: (svg, axes, data) ->
      tooltip = svg.select('.trianglesTooltip')

      tooltipPositiveLine = svg.select('.trianglesTooltipPositiveLine')
      tooltipNegativeLine = svg.select('.trianglesTooltipNegativeLine')
      if data.isUp is true
        tooltipPositiveLine.attr('opacity', 1)
        tooltipNegativeLine.attr('opacity', 0)
      else
        tooltipPositiveLine.attr('opacity', 0)
        tooltipNegativeLine.attr('opacity', 1)

      x = axes.xScale(data.x) - 50
      if data.chartType is 'Line'
        if data.isUp is true
          y = axes.y2Scale(data.closeValue) + 19
        else
          y = axes.y2Scale(data.closeValue) - 61
      else
        if data.isUp is true
          y = axes.y2Scale(data.lowValue) + 18
        else
          y = axes.y2Scale(data.highValue) - 61
      tooltip.attr('opacity', 1).attr('transform', 'translate(' + x + ', ' + y + ')')

      dateText = svg.select('.trianglesTooltipDateText')
      dateText.text(data.dateFormattedValue)

      dataText = svg.select('.trianglesTooltipDataText')
      dataText.text(data.triangleValue)

    triangleMouseOutHandler: (svg) ->
      tooltip = svg.select('.trianglesTooltip')
      tooltip.attr('opacity', 0)
