"use strict";
var day_dict = {};
day_dict[0] = "Sunday";
day_dict[1] = "Monday";
day_dict[2] = "Tuesday";
day_dict[3] = "Wednesday";
day_dict[4] = "Thursday";
day_dict[5] = "Saturday";
day_dict[6] = "Sunday";

function SendDateToServer( msg )
{
	$.Msg("Received Event")
	var day_string = ""
	var now= new Date();
	var h= now.getHours();
	var m= now.getMinutes(); 
	var s= now.getSeconds();
	var date_day= now.getDate();
	var month= now.getMonth(); 
	var year= now.getFullYear();

	if(date_day<10) date_day= '0'+date_day;
	if(month<10) month= '0'+month;
	if(m<10) m= '0'+m;
	if(s<10) s= '0'+s;
	var date_string = date_day + '/' + month + '/' + year + ' --- ' + h + ':' + m + ':' + s;
	day_string = day_dict[now.getDay()]

	$.Msg("Date SENDING to Server ! : " + date_string + "  " + day_string);
	GameEvents.SendCustomGameEventToServer( "POST_DATE", 
		{ "date" : date_string, 
		"day": day_string }
	);
	$.Msg("Date Sent to Server ! : " + date_string + "  " + day_string);
}

(function()
{
    GameEvents.Subscribe( "GET_DATE", SendDateToServer);
})();