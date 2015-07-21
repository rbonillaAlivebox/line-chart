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
