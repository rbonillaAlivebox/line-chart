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