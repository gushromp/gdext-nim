import gdext
import gdextgen/classes/gdResourceLoader

type PropTestEnum* = enum
  PropTestEnum1, PropTestEnum2, PropTestEnum3

type PropTestNode* = ref object of Node
  icon*: gdref Texture2D
  PropTestEnum_with_export*: PropTestEnum
  string_with_export*: string = "with export"
  string_with_export_placeholder*: string
  string_with_export_dir*: string = "res://nim"
  string_with_export_global_dir*: string = "/dev"
  string_with_export_file*: string = "res://nim/bootstrap.nim"
  string_with_export_global_file*: string = "/dev/null"
  int_with_export_enum*: int
  string_with_export_enum*: string = "Alpha"
  int_with_export_flags*: int
  int_with_export_flags_some_layers*: int
  float_with_export_exp_easing*: float = 2
  string_with_export_multiline*: string = """
MULTILINE-TEXT MULTILINE-TEXT MULTILINE-TEXT
MULTILINE-TEXT MULTILINE-TEXT MULTILINE-TEXT
MULTILINE-TEXT MULTILINE-TEXT MULTILINE-TEXT
MULTILINE-TEXT MULTILINE-TEXT MULTILINE-TEXT"""
  StringArray_with_export_multiline*: TypedArray[String]
  PackedStringArray_with_export_multiline*: PackedStringArray
  NodePath_with_export_node_path*: NodePath
  string_with_export_storage*: string = "with export_storage"
  int_with_export_strict_range*: int = 20
  int_with_export_range*: int = 20
  radians_with_export_range_as_degrees*: float = PI/4
  color_with_export*: Color = color(1, 1, 1, 0.5)
  color_with_export_no_alpha*: Color = color(1, 1, 1)

method init(self: PropTestNode) =
  self.icon = ResourceLoader.load("res://icon.png") as gdref Texture2D
  self.StringArray_with_export_multiline = typedArray[String](1)
  self.PackedStringArray_with_export_multiline = packedStringArray()
  assert self.PackedStringArray_with_export_multiline.resize(1) == 0

`@export_category`PropTestNode, "Export Test"

`@export` icon,
    proc (self: PropTestNode): gdref Texture2D = self.icon,
    proc (self: PropTestNode; value: gdref Texture2D) = self.icon = value

PropTestNode.registerEnum PropTestEnum
`@export`"PropTestEnum_with_export",
    proc (self: PropTestNode): PropTestEnum = self.PropTestEnum_with_export,
    proc (self: PropTestNode; value: PropTestEnum) = self.PropTestEnum_with_export = value

`@export`"string_with_export",
    proc (self: PropTestNode): string = self.string_with_export,
    proc (self: PropTestNode; value: string) = self.string_with_export = value

proc get_string_with_export_through_proc(self: PropTestNode): string {.gdsync.} =
  self.string_with_export
proc set_string_with_export_through_proc(self: PropTestNode; value: string) {.gdsync.} =
  self.string_with_export = value
`@export`string_with_export_through_proc,
    get_string_with_export_through_proc,
    set_string_with_export_through_proc

`@export_placeholder`string_with_export_placeholder,
    proc (self: PropTestNode): string = self.string_with_export_placeholder,
    proc (self: PropTestNode; value: string) = self.string_with_export_placeholder = value,
    "placeholder here..."

`@export_group`PropTestNode, filesystem

`@export_subgroup`ProptestNode, local
`@export_dir`"string_with_export_dir",
    proc (self: PropTestNode): string = self.string_with_export_dir,
    proc (self: PropTestNode; value: string) = self.string_with_export_dir = value
`@export_file`"string_with_export_file",
    proc (self: PropTestNode): string = self.string_with_export_file,
    proc (self: PropTestNode; value: string) = self.string_with_export_file = value

`@export_subgroup`ProptestNode, "global"
`@export_global_dir`"string_with_export_global_dir",
    proc (self: PropTestNode): string = self.string_with_export_global_dir,
    proc (self: PropTestNode; value: string) = self.string_with_export_global_dir = value
`@export_global_file`"string_with_export_global_file",
    proc (self: PropTestNode): string = self.string_with_export_global_file,
    proc (self: PropTestNode; value: string) = self.string_with_export_global_file = value

`@export_group`PropTestNode, ""

`@export`"color_with_export",
    proc (self: PropTestNode): Color = self.color_with_export,
    proc (self: PropTestNode; value: Color) = self.color_with_export = value
`@export_color_no_alpha`"color_with_export_no_alpha",
    proc (self: PropTestNode): Color = self.color_with_export_no_alpha,
    proc (self: PropTestNode; value: Color) = self.color_with_export_no_alpha = value

`@export_enum`"int_with_export_enum",
    proc (self: PropTestNode): int = self.int_with_export_enum,
    proc (self: PropTestNode; value: int) = self.int_with_export_enum = value,
    "Alpha", "Beta:10", "Gamma"
`@export_enum`"string_with_export_enum",
    proc (self: PropTestNode): string = self.string_with_export_enum,
    proc (self: PropTestNode; value: string) = self.string_with_export_enum = value,
    "Alpha", "Beta", "Gamma"

`@export_flags`"int_with_export_flags",
    proc (self: PropTestNode): int = self.int_with_export_flags,
    proc (self: PropTestNode; value: int) = self.int_with_export_flags = value,
    "Alpha", "Beta", "Gamma"

proc int_with_export_flags_some_layers(self: PropTestNode): int {.gdsync, name: "get_int_with_export_flags_some_layers".} =
  self.int_with_export_flags_some_layers
proc `int_with_export_flags_some_layers=`(self: PropTestNode; value: int) {.gdsync, name: "set_int_with_export_flags_some_layers".} =
  self.int_with_export_flags_some_layers = value

`@export_flags_2d_navigation`"int_with_export_flags_2d_navigation",
    int_with_export_flags_some_layers,
    `int_with_export_flags_some_layers=`
`@export_flags_2d_physics`"int_with_export_flags_2d_physics",
    int_with_export_flags_some_layers,
    `int_with_export_flags_some_layers=`
`@export_flags_2d_render`"int_with_export_flags_2d_render",
    int_with_export_flags_some_layers,
    `int_with_export_flags_some_layers=`
`@export_flags_3d_navigation`"int_with_export_flags_3d_navigation",
    int_with_export_flags_some_layers,
    `int_with_export_flags_some_layers=`
`@export_flags_3d_physics`"int_with_export_flags_3d_physics",
    int_with_export_flags_some_layers,
    `int_with_export_flags_some_layers=`
`@export_flags_3d_render`"int_with_export_flags_3d_render",
    int_with_export_flags_some_layers,
    `int_with_export_flags_some_layers=`
`@export_flags_avoidance`"int_with_export_flags_avoidance",
    int_with_export_flags_some_layers,
    `int_with_export_flags_some_layers=`

proc float_with_export_exp_easing(self: PropTestNode): float {.gdsync, name: "get_float_with_export_exp_easing".} =
  self.float_with_export_exp_easing
proc `float_with_export_exp_easing=`(self: PropTestNode; value: float) {.gdsync, name: "set_float_with_export_exp_easing".} =
  self.float_with_export_exp_easing = value

`@export_exp_easing`"float_with_export_exp_easing",
    float_with_export_exp_easing,
    `float_with_export_exp_easing=`
`@export_exp_easing`"float_with_export_exp_easing_attenuation",
    float_with_export_exp_easing,
    `float_with_export_exp_easing=`,
    attenuation
`@export_exp_easing`"float_with_export_exp_easing_positive_only",
    float_with_export_exp_easing,
    `float_with_export_exp_easing=`,
    positive_only

`@export_multiline`"string_with_export_multiline",
    proc (self: PropTestNode): string = self.string_with_export_multiline,
    proc (self: PropTestNode; value: string) = self.string_with_export_multiline = value
# Currently not works,
`@export_multiline`"StringArray_with_export_multiline",
    proc (self: PropTestNode): TypedArray[String] = self.StringArray_with_export_multiline,
    proc (self: PropTestNode; value: TypedArray[String]) = self.StringArray_with_export_multiline = value
`@export_multiline`"PackedStringArray_with_export_multiline",
    proc (self: PropTestNode): PackedStringArray = self.PackedStringArray_with_export_multiline,
    proc (self: PropTestNode; value: PackedStringArray) = self.PackedStringArray_with_export_multiline = value

`@export_node_path`"NodePath_with_export_node_path",
    proc (self: PropTestNode): NodePath = self.NodePath_with_export_node_path,
    proc (self: PropTestNode; value: NodePath) = self.NodePath_with_export_node_path = value,
    "Sprite2D"
`@export_node_path`"NodePath_with_export_node_path_typedesc",
    proc (self: PropTestNode): NodePath = self.NodePath_with_export_node_path,
    proc (self: PropTestNode; value: NodePath) = self.NodePath_with_export_node_path = value,
    Sprite2D

`@export_range`"int_with_export_strict_range",
    proc (self: PropTestNode): int = self.int_with_export_strict_range,
    proc (self: PropTestNode; value: int) = self.int_with_export_strict_range = value,
    10, 100
`@export_range`"int_with_export_range",
    proc (self: PropTestNode): int = self.int_with_export_range,
    proc (self: PropTestNode; value: int) = self.int_with_export_range = value,
    10, 100, 5, or_less, or_greater

`@export_range`"radians_with_export_range_as_degrees",
    proc (self: PropTestNode): float = self.radians_with_export_range_as_degrees,
    proc (self: PropTestNode; value: float) = self.radians_with_export_range_as_degrees = value,
    0, 360, radians_as_degrees

`@export_storage`"string_with_export_storage",
    proc (self: PropTestNode): string = self.string_with_export_storage,
    proc (self: PropTestNode; value: string) = self.string_with_export_storage = value
