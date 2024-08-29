extends GodotSideTester

var signal_arg0_executed = false
var signal_arg1_executed = false


# Called when the node enters the scene tree for the first time.
func _ready():
	test_helloworld()
	test_int_value()
	test_float_value()
	test_func()
	test_grobal_func()

func test_helloworld():
	assert(helloworld() == "Hello, World!")

func test_int_value():
	assert(get_int_value() == 0)
	set_int_value(10)
	assert(get_int_value() == 10)
	int_value = 20
	assert(int_value == 20)

func test_float_value():
	assert(get_float_value() == 0)
	set_float_value(10)
	assert(get_float_value() == 10)
	float_value = 20
	assert(float_value == 20)

func test_func():
	var tester = get_parent().get_node("TesterNIM")

	tester.arg0_noret()
	assert(tester.arg0_noret_result == "arg0_noret()")

	tester.arg1_noret(tester.arg1_ret(tester.arg0_ret()))
	assert(tester.arg1_noret_result == "arg1_noret(arg1_ret(arg0_ret()))")

	assert(tester.default_value_simple() == "default_value_simple(default)")
	assert(tester.default_value_simple("custom") == "default_value_simple(custom)")

	assert(tester.default_value_complex("a", "b") == "default_value_complex(a b default value)")
	assert(tester.default_value_complex("a", "b", "c") == "default_value_complex(a b c value)")
	assert(tester.default_value_complex("a", "b", "c", "d") == "default_value_complex(a b c d)")

func test_grobal_func():
	nim.signal_arg0.connect(_on_nim_signal_arg0)
	nim.signal_arg1.connect(_on_nim_signal_arg1)
	nim.arg0_noret()
	nim.arg1_noret(nim.arg1_ret(nim.arg0_ret()))
	nim.signal_arg0.emit()
	nim.signal_arg1.emit("signal")

	nim.exec_checks_use_api_from_toplevel()
	assert(signal_arg0_executed and signal_arg1_executed)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _on_tester_nim_custom_signal(value):
	assert(value == 10)

func _on_nim_signal_arg0():
	signal_arg0_executed = true
func _on_nim_signal_arg1(what):
	assert(what == "signal")
	signal_arg1_executed = true
