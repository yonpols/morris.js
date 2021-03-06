describe 'Morris.Line', ->

  it 'should raise an error when the placeholder element is not found', ->
    my_data = [{x: 1, y: 1}, {x: 2, y: 2}]
    fn = ->
      Morris.Line(
        element: "thisplacedoesnotexist"
        data: my_data
        xkey: 'x'
        ykeys: ['y']
        labels: ['dontcare']
      )
    fn.should.throw(/Graph container element not found/)

  it 'should make point styles customizable', ->
    my_data = [{x: 1, y: 1}, {x: 2, y: 2}]
    red = '#ff0000'
    blue = '#0000ff'
    chart = Morris.Line
      element: 'graph'
      data: my_data
      xkey: 'x'
      ykeys: ['y']
      labels: ['dontcare']
      pointStrokeColors: [red, blue]
      pointWidths: [1, 2]
      pointFillColors: [null, red]
    chart.strokeWidthForSeries(0).should.equal 1
    chart.strokeForSeries(0).should.equal red
    chart.strokeWidthForSeries(1).should.equal 2
    chart.strokeForSeries(1).should.equal blue
    (null == chart.pointFillColorForSeries(0)).should.be
    (chart.pointFillColorForSeries(0) || chart.colorForSeries(0)).should.equal chart.colorForSeries(0)
    chart.pointFillColorForSeries(1).should.equal red

  describe 'generating column labels', ->

    it 'should use user-supplied x value strings by default', ->
      chart = Morris.Line
        element: 'graph'
        data: [{x: '2012 Q1', y: 1}, {x: '2012 Q2', y: 1}]
        xkey: 'x'
        ykeys: ['y']
        labels: ['dontcare']
      chart.data.map((x) -> x.label).should == ['2012 Q1', '2012 Q2']

    it 'should use a default format for timestamp x-values', ->
      d1 = new Date(2012, 0, 1)
      d2 = new Date(2012, 0, 2)
      chart = Morris.Line
        element: 'graph'
        data: [{x: d1.getTime(), y: 1}, {x: d2.getTime(), y: 1}]
        xkey: 'x'
        ykeys: ['y']
        labels: ['dontcare']
      chart.data.map((x) -> x.label).should == [d2.toString(), d1.toString()]

    it 'should use user-defined formatters', ->
      d = new Date(2012, 0, 1)
      chart = Morris.Line
        element: 'graph'
        data: [{x: d.getTime(), y: 1}, {x: '2012-01-02', y: 1}]
        xkey: 'x'
        ykeys: ['y']
        labels: ['dontcare']
        dateFormat: (d) ->
          x = new Date(d)
          "#{x.getYear()}/#{x.getMonth()+1}/#{x.getDay()}"
      chart.data.map((x) -> x.label).should == ['2012/1/1', '2012/1/2']

  describe 'rendering lines', ->
    beforeEach ->
      @defaults =
        element: 'graph'
        data: [{x:0, y:1, z:0}, {x:1, y:0, z:1}, {x:2, y:1, z:0}, {x:3, y:0, z:1}, {x:4, y:1, z:0}]
        xkey: 'x'
        ykeys: ['y', 'z']
        labels: ['y', 'z']
        lineColors: ['#abcdef', '#fedcba']
        smooth: true
        continuousLine: false

    shouldHavePath = (regex, color = '#abcdef') ->
      # Matches an SVG path element within the rendered chart.
      #
      # Sneakily uses line colors to differentiate between paths within
      # the chart.
      $('#graph').find("path[stroke='#{color}']").attr('d').should.match regex

    it 'should generate smooth lines when options.smooth is true', ->
      Morris.Line @defaults
      shouldHavePath /M[\d\.]+,[\d\.]+(C[\d\.]+(,[\d\.]+){5}){4}/

    it 'should generate jagged lines when options.smooth is false', ->
      Morris.Line $.extend(@defaults, smooth: false)
      shouldHavePath /M[\d\.]+,[\d\.]+(L[\d\.]+,[\d\.]+){4}/

    it 'should generate smooth/jagged lines according to the value for each series when options.smooth is an array', ->
      Morris.Line $.extend(@defaults, smooth: ['y'])
      shouldHavePath /M[\d\.]+,[\d\.]+(C[\d\.]+(,[\d\.]+){5}){4}/, '#abcdef'
      shouldHavePath /M[\d\.]+,[\d\.]+(L[\d\.]+,[\d\.]+){4}/, '#fedcba'

    it 'should ignore undefined values', ->
      @defaults.data[2].y = undefined
      Morris.Line @defaults
      shouldHavePath /M[\d\.]+,[\d\.]+(C[\d\.]+(,[\d\.]+){5}){3}/

    it 'should ignore null values when options.continuousLine is true', ->
      @defaults.data[2].y = null
      Morris.Line $.extend(@defaults, continuousLine: true)
      shouldHavePath /M[\d\.]+,[\d\.]+(C[\d\.]+(,[\d\.]+){5}){3}/

    it 'should break the line at null values when options.continuousLine is false', ->
      @defaults.data[2].y = null
      Morris.Line @defaults
      shouldHavePath /(M[\d\.]+,[\d\.]+C[\d\.]+(,[\d\.]+){5}){2}/

  describe '#createPath', ->

    it 'should generate a smooth line', ->
      testData = [{x: 0, y: 10}, {x: 10, y: 0}, {x: 20, y: 10}]
      path = Morris.Line.createPath(testData, true, 0)
      path.should.equal 'M0,10C2.5,7.5,7.5,0,10,0C12.5,0,17.5,7.5,20,10'

    it 'should generate a jagged line', ->
      testData = [{x: 0, y: 10}, {x: 10, y: 0}, {x: 20, y: 10}]
      path = Morris.Line.createPath(testData, false, 0)
      path.should.equal 'M0,10L10,0L20,10'

    it 'should prevent paths from descending below the bottom of the chart', ->
      testData = [{x: 0, y: 20}, {x: 10, y: 10}, {x: 20, y: 30}]
      path = Morris.Line.createPath(testData, true, 10)
      path.should.equal 'M0,20C2.5,17.5,7.5,10,10,10C12.5,11.25,17.5,25,20,30'

    it 'should break the line at null values', ->
      testData = [{x: 0, y: 10}, {x: 10, y: 0}, {x: 20, y: null}, {x: 30, y: 10}, {x: 40, y: 0}]
      path = Morris.Line.createPath(testData, true, 0)
      path.should.equal 'M0,10C2.5,7.5,7.5,2.5,10,0M30,10C32.5,7.5,37.5,2.5,40,0'

    it 'should ignore leading and trailing null values', ->
      testData = [{x: 0, y: null}, {x: 10, y: 10}, {x: 20, y: 0}, {x: 30, y: 10}, {x: 40, y: null}]
      path = Morris.Line.createPath(testData, true, 0)
      path.should.equal 'M10,10C12.5,7.5,17.5,0,20,0C22.5,0,27.5,7.5,30,10'
