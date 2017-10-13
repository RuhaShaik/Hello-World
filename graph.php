<html>
<head>
<script type="text/javascript" src="https://www.gstatic.com/charts/loader.js"></script>
<script src="https://code.highcharts.com/highcharts.js"></script>
<script src="https://code.highcharts.com/modules/series-label.js"></script>
<script src="https://code.highcharts.com/modules/exporting.js"></script>
<script>
   google.charts.load('current', {'packages':['line', 'corechart']});
      google.charts.setOnLoadCallback(drawChart);

    function drawChart() {

      var button = document.getElementById('change-chart');
      var chartDiv = document.getElementById('chart_div');

      var data = new google.visualization.DataTable();
      data.addColumn('date', 'Month');
      data.addColumn('number', "Average Temperature");
      data.addColumn('number', "Average Hours of Daylight");
      data.addColumn('number', "newdata");

      data.addRows([
        [new Date(2014, 0),  -.5,  5.7, 2.3],
        [new Date(2014, 1),   .4,  8.7, 4.5],
        [new Date(2014, 2),   .5,   12, 6.2],
        [new Date(2014, 3),  2.9, 15.3, 12.2],
        [new Date(2014, 4),  6.3, 18.6, 34],
        [new Date(2014, 5),    9, 20.9, 1.2],
        [new Date(2014, 6), 10.6, 19.8, 7.9],
        [new Date(2014, 7), 10.3, 16.6, 4.5],
        [new Date(2014, 8),  7.4, 13.3, 3.4],
        [new Date(2014, 9),  4.4,  9.9, 67.7],
        [new Date(2014, 10), 1.1,  6.6, 45],
        [new Date(2014, 11), -.2,  4.5, 23]
      ]);

      var materialOptions = {
        chart: {
          title: 'Average Temperatures and Daylight in Iceland Throughout the Year normal'
        },
        width: 900,
        height: 500,
        series: {
          // Gives each series an axis name that matches the Y-axis below.
          0: {axis: 'Temps'},
          1: {axis: 'Daylight'},
		  2: {axis: 'newdata'}
        },
        axes: {
          // Adds labels to each axis; they don't have to match the axis names.
          y: {
            Temps: {label: 'Temps (Celsius)'},
            Daylight: {label: 'Daylight'},
			newdata: {label:'newdata'}
          }	 
        }
		
      };

      var classicOptions = {
        title: 'Average Temperatures and Daylight in Iceland ',
        width: 900,
        height: 500,
        // Gives each series an axis that matches the vAxes number below.
        series: {
          0: {targetAxisIndex: 0},
          1: {targetAxisIndex: 1},
		  2: {targetAxisIndex: 2},
        },
        vAxes: {
          // Adds titles to each axis.
          0: {title: 'Temps (Celsius)'},
          1: {title: 'Daylight'},
		  2: {title: 'newdata'}
        },
        hAxis: {
          ticks: [
				new Date(2014, 0), new Date(2014, 1), new Date(2014, 2), new Date(2014, 3),
                  new Date(2014, 4),  new Date(2014, 5), new Date(2014, 6), new Date(2014, 7),
                  new Date(2014, 8), new Date(2014, 9), new Date(2014, 10), new Date(2014, 11)
                 ]
        },
        vAxis: {
          viewWindow: {
            max: 30
          }
        }
      };

      function drawMaterialChart() {
        var materialChart = new google.charts.Line(chartDiv);
        materialChart.draw(data, materialOptions);
        button.innerText = 'Change to Classic';
        button.onclick = drawClassicChart;
      }

      function drawClassicChart() {
        var classicChart = new google.visualization.LineChart(chartDiv);
        classicChart.draw(data, classicOptions);
        button.innerText = 'Change to Material';
        button.onclick = drawMaterialChart;
      }
      drawMaterialChart();
    }
  </script>
  
    
</head>
<body>
 
	 <button id="change-chart">Change to Classic</button>
  <br><br>
  <div id="chart_div"></div>


</body>
</html>