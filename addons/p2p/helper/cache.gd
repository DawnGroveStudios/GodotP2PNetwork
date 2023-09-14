extends Node

@export var default_expiration_sec=5
@export var default_clean_sec=5
@export var max_items_in_cache=10000
var _cache={}
var _cache_expiration={}

var _cache_miss = 0
func size() -> int:
	return _cache.size()

func cache_miss() -> int:
	var miss = _cache_miss
	_cache_miss = 0
	return miss

func clear():
	_cache.clear()
	_cache_expiration.clear()

func get_data(key:String,update_expires:int=-1):
	if _cache.has(key):
		if! _cache_expiration.has(key):
			return _cache[key]
		var current_time = Time.get_unix_time_from_datetime_dict(Time.get_datetime_dict_from_system(true))
		var expired_time = _cache_expiration[key]
		if current_time > expired_time:
			remove(key)
		else:
			if update_expires > 0:
				_cache_expiration[key] = _get_expire(update_expires)
			return _cache[key]
	_cache_miss += 1
	return null

func add_data(key:String,data,expires:int=default_expiration_sec) ->bool:
	if _cache.has(key):
		return false
	return set_data(key,data,expires)

func set_data(key,data,expires:int=default_expiration_sec) ->bool:
	if _cache.size() > max_items_in_cache:
		NetLog.warn("failed inserting into cache, too many items",
		{
			"key":key,
			"cache_size":_cache.size()
		})
		return false
	_cache[key] = data
	if expires == -1:
		return true
	_cache_expiration[key] = _get_expire(expires)
	return true

func refresh_expires(key,expires:int=default_expiration_sec) ->bool :
	if !_cache_expiration.has(key):
		return false
	_cache_expiration[key] = _get_expire(expires)
	return true

func _ready():
	var t = Timer.new()
	t.wait_time = default_clean_sec
	t.autostart=true
	t.timeout.connect(_clean)
	add_child(t)

func remove(key:String):
	if _cache.has(key):
		_cache.erase(key)
	if _cache_expiration.has(key):
		_cache_expiration.erase(key)

func _clean():
	var current_time = Time.get_unix_time_from_datetime_dict(Time.get_datetime_dict_from_system(true))
	var keys_to_remove = []
	for k in _cache_expiration:
		var expired_time = _cache_expiration[k]
		if current_time > expired_time:
			keys_to_remove.append(k)
	for k in keys_to_remove:
		remove(k)

func _get_expire(offset:int) -> int:
	var current_time = Time.get_unix_time_from_datetime_dict(Time.get_datetime_dict_from_system(true))
	return current_time + offset
