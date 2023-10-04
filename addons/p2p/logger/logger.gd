@tool
extends Node

class_name NetLog

enum LogLevel {
	DEBUG,
	INFO,
	WARN,
	ERROR,
	FATAL,
}

static var CURRENT_LOG_LEVEL=LogLevel.INFO
static var write_logs:bool = false
static var log_path:String = "res://game.log"
var _config

var _prefix=""
var _default_args={}

static var _file

func _ready() -> void:
	name = "logger"

func _set_loglevel(level:String):
	logger("setting log level",{"level":level},LogLevel.INFO)
	match level.to_lower():
		"debug":
			CURRENT_LOG_LEVEL = LogLevel.DEBUG
		"info":
			CURRENT_LOG_LEVEL = LogLevel.INFO
		"warn":
			CURRENT_LOG_LEVEL = LogLevel.WARN
		"error":
			CURRENT_LOG_LEVEL = LogLevel.ERROR
		"fatal":
			CURRENT_LOG_LEVEL = LogLevel.FATAL

static func logger(message:String,values,log_level=LogLevel.INFO,tree:SceneTree=null):
	if CURRENT_LOG_LEVEL > log_level :
		return
	var log_msg_format = "{level} [{time}]{prefix} {message} "

	var now = Time.get_datetime_dict_from_system(true)

	var msg = log_msg_format.format(
		{
			"prefix":"",
			"message":message,
			"time":"{day}/{month}/{year} {hour}:{minute}:{second}".format(now),
			"level":LogLevel.keys()[log_level]
		})


	match typeof(values):
		TYPE_ARRAY:
			if values.size() > 0:
				msg += "["
				for k in values:
					msg += "{k},".format({"k":JSON.stringify(k)})
				msg = msg.left(msg.length()-1)+"]"
		TYPE_DICTIONARY:
			if values.size() > 0:
				msg += "{"
				for k in values:
					if typeof(values[k]) == TYPE_OBJECT && values[k] != null:
						msg += '"{k}":{v},'.format({"k":k,"v":JSON.stringify(JsonData.to_dict(values[k],false))})
					else:
						msg += '"{k}":{v},'.format({"k":k,"v":JSON.stringify(values[k])})
				msg = msg.left(msg.length()-1)+"}"
		TYPE_PACKED_BYTE_ARRAY:
			if values == null:
				msg += JSON.stringify(null)
			else:
				msg += JSON.stringify(JsonData.unmarshal_bytes_to_dict(values))
		TYPE_OBJECT:
			if values == null:
				msg += JSON.stringify(null)
			else:
				msg += JSON.stringify(JsonData.to_dict(values,false))
		TYPE_NIL:
			msg += JSON.stringify(null)
		_:
			msg += JSON.stringify(values)
	if OS.get_main_thread_id() != OS.get_thread_caller_id() and log_level == LogLevel.DEBUG:
		print("[%d]Cannot retrieve debug info outside the main thread:\n\t%s" % [OS.get_thread_caller_id(),msg])
		return
	_write_logs(msg)
	match log_level:
		LogLevel.DEBUG:
			print(msg)
			print_stack()
		LogLevel.INFO:
			print(msg)
		LogLevel.WARN:
			print(msg)
			push_warning(msg)
			print_stack()
		LogLevel.ERROR:
			push_error(msg)
			printerr(msg)
			print_stack()

		LogLevel.FATAL:
			push_error(msg)
			printerr(msg)
			print_stack()
			if tree != null:
				tree.quit()
		_:
			print(msg)

static func debug(message:String,values={}):
	logger(message,values,LogLevel.DEBUG)

static func warn(message:String,values={}):
	logger(message,values,LogLevel.WARN)

static func error(message:String,values={}):
	logger(message,values,LogLevel.ERROR)

static func fatal(tree:SceneTree,message:String,values={}):
	logger(message,values,LogLevel.FATAL,tree)

static func info(message:String,values={}):
	logger(message,values)

static func _write_logs(message:String):
	if !write_logs:
		return
	if _file == null:
		_file = FileAccess.open(log_path,FileAccess.WRITE)
	_file.store_line(message)
	pass


