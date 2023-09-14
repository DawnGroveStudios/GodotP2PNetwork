extends Node

class_name ThreadingUtil
var _running_threads:Array[Thread]
var _max_threads=500

var _mutexs:Dictionary
var _mutex:Mutex = Mutex.new()

func _ready():
	var thread_cleaner = Timer.new()
	thread_cleaner.wait_time = 2.0
	thread_cleaner.autostart = true
	thread_cleaner.one_shot = false

	thread_cleaner.timeout.connect(_clean_threads)
	add_child(thread_cleaner)
	thread_cleaner.start()
	NetLog.info("starting thread cleaner thread",{"left":_running_threads.size()})

static func wait_for_threads(threads:Array[Thread]):
	for t in threads:
		if !t.is_alive():
			return
		t.wait_to_finish()

func run(callable:Callable) ->bool:
	if _running_threads.size() >= _max_threads:
		NetLog.warn("too many threads running",{"max":_max_threads,"running":_running_threads.size()})
		return false
	var t = Thread.new()
	t.start(callable)
	_running_threads.append(t)
	return true

func _clean_threads():
	for index in range(_running_threads.size()):
		if index >= _running_threads.size() :
			continue
		var current_thread = _running_threads[index]
		if current_thread.is_alive() || current_thread.is_queued_for_deletion():
			continue
		_running_threads.remove_at(index)

func size() ->int:
	return _running_threads.size()

func mutex_size() ->int:
	return _mutexs.size()

func lock_mutex(name="default"):
	_mutex.lock()
	if !_mutexs.has(name):
		_mutexs[name] = Mutex.new()
	_mutexs.get(name).lock()
	_mutex.unlock()

func unlock_mutex(name="default"):
	_mutex.lock()
	if !_mutexs.has(name):
		_mutex.unlock()
		return
	_mutexs.get(name).unlock()
	_mutexs.erase(name)
	_mutex.unlock()

func _exit_tree():
	ThreadingUtil.wait_for_threads(_running_threads)
