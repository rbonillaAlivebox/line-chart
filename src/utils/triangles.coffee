    drawTriangles: (svg, axes, data, columnWidth, options, handlers, dimensions) ->
      this.drawDailyTriangles()
      return this

    drawDailyTriangles: (svg, axes, data) ->
      that = this

      data = data.filter (s) -> s.type is 'dailyTriangles'

      if data.length == 0
        return this

      triangleGroup = svg.select('.content').selectAll('.dailyTrianglesGroup')
        .data(data)
        .enter().append('g')
        .attr('class', (s) -> 'dailyTrianglesGroup series_' + s.index)

      triangleGroup.selectAll('open').data((d) -> d.values)
        .enter().append('svg:polygon')
        .attr(
          'points', (d) -> that.getPositiveTrianglePoints()
        )

    getPositiveTrianglePoints: () ->
      points = '15.529,15.529 15.529,15.059 0.941,15.059 0.941,0.941 15.059,0.941 15.059,15.529 15.529,15.529 15.529,' +
        '15.059 15.529,15.529 16,15.529 16,0 0,0 0,16 16,16 16,15.529'
      return points