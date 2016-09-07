var update = function() {
  $.getJSON("./info.json", function (json) {
    console.log(json);
    $(".data").remove()

    json.forEach(function(e) {
      console.log(e);
      var date = new Date(e.Timestamp)
      $('#UsageTable tr:last').after('<tr class="data"><td>' + e.Name +
      '</td><td>' + date.toTimeString() +
      '</td><td>' + e.CPU +
      '</td><td>' + e.Network +
      '</td><td>' + e.Memory + '</td></tr>'
      );
    })

  })
}

update();
$.ajaxSetup({ cache: false });
setInterval(update, 1000);
