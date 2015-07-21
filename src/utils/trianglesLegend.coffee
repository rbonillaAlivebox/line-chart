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
