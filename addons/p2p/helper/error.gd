var _msg = ""
var _code = -1

func _init(msg:String,code:int=-1):
	_msg = msg
	_code = code

func _to_string() -> String:
	if _code > 0:
		return "(%d)%s" % [_code,_msg]
	return _msg

