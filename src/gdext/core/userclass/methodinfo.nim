import std/sequtils
import std/tables
import gdext/utils/macros

import gdext/dirty/gdextensioninterface
import gdext/core/commandindex
import gdext/core/builtinindex
import gdext/core/typeshift
import gdext/core/exceptions
import gdext/core/methodtools

import propertyinfo

type MiddleExp = object
  name: NimNode
  isStatic: bool
  self_T: NimNode
  result_T: NimNode
  args: seq[tuple[namesym, typesym, default: NimNode]]

proc parseMiddle(procdef: NimNode): MiddleExp =
  result.name = procdef[0]
  if result.name.kind == nnkPostfix: result.name = result.name[1]

  result.self_T = procdef.params[1][1]
  if procdef.hasReturn:
    result.result_T = procdef.params[0]

  result.args = procdef.params.breakArgs.toSeq
    .filterIt(it.index != 0)
    .mapIt((
      it.def.name,
      (if it.def.Type.kind == nnkEmpty: ident"typeof".newCall(it.def.default) else: it.def.Type),
      it.def.default))

  result.is_static = `and`(
    result.self_T.kind == nnkBracketExpr,
    result.self_T[0].eqIdent "typedesc",
  )

template hasResult(middle: MiddleExp): bool = middle.result_T != nil

proc returnValueInfo(middle: MiddleExp): NimNode =
  let retT = middle.result_T
  if middle.hasResult:
    quote do:
      let info = propertyInfo(typedesc `retT`)
      addr info
  else: newNilLit()
proc returnValueMeta(middle: MiddleExp): NimNode =
  let retT = middle.result_T
  if middle.hasResult:
    quote do:
      metadata(typedesc `retT`)
  else: bindSym "MethodArgumentMetadata_None"

proc argumentsInfo(middle: MiddleExp): NimNode =
  if middle.args.len == 0: return newNilLit()

  var info = newNimNode nnkBracket

  for (name, Type, default) in middle.args:
    let name = toStrLit name
    info.add quote do:
      let p_name = stringName `name`
      propertyInfo(typedesc `Type`, addr p_name)

  quote do:
    let info = `info`
    addr info[0]

proc argumentsMeta(middle: MiddleExp): NimNode =
  if middle.args.len == 0: return newNilLit()

  var meta = newNimNode nnkBracket

  for (_, Type, default) in middle.args:
    meta.add quote do:
      metadata(typedesc `Type`)

  quote do:
    let meta = `meta`
    addr meta[0]

proc defaultArgumentCount(middle: MiddleExp): int =
  middle.args.filterIt(it.default.kind != nnkEmpty).len

proc declareDefaultArgumentsArray(middle: MiddleExp; default_arguments: NimNode): NimNode =
  let defaultArgumentsSym = genSym(nskLet, "defaultArguments")
  let defaultArgumentsArray = newNimNode nnkBracket
  let defaultArgumentsAddrArray = newNimNode nnkBracket
  for arg in middle.args:
    if arg.default.kind == nnkEmpty: continue
    defaultArgumentsArray.add ident"variant".newCall arg.default
    defaultArgumentsAddrArray.add bindSym"getPtr".newCall(
      nnkBracketExpr.newTree(defaultArgumentsSym, newLit defaultArgumentsArray.len.pred)
    )
  case defaultArgumentsArray.len
  of 0:
    discard
    quote do:
      let
        `default_arguments`: ClassMethodInfo.default_arguments = nil
  else:
    quote do:
      let
        `defaultArgumentsSym` = `defaultArgumentsArray`
        defaultArgumentsAddr = `defaultArgumentsAddrArray`
        `default_arguments`: ClassMethodInfo.default_arguments = addr defaultArgumentsAddr[0]

proc callFunc(middle: MiddleExp): NimNode =
  let p_instance = ident"p_instance"
  let p_args = ident"p_args"
  let p_argument_count = ident"p_argument_count"
  let r_return = ident"r_return"

  let self_T = middle.self_T

  let call = middle.name.newCall()
  let options = newStmtList()

  if middle.is_static:
    call.add middle.self_T
  else:
    call.add quote do: cast[`self_T`](`p_instance`)

  for i, (name, Type, default) in middle.args:
    let i_lit = newlit i

    if default.kind == nnkEmpty:
      call.add quote do: cast[ptr Variant](`p_args`[`i_lit`])[].get(typedesc `Type`)
    else:
      let n = gensym(nskLet, $name)
      options.add quote do:
        let `n` =
          if `p_argument_count` > `i_lit`:
            cast[ptr Variant](`p_args`[`i_lit`])[].get(typedesc `Type`)
          else: `default`
      call.add n

  let body =
    if middle.hasResult:
      quote do:
        errproof:
          `options`
          let result = variant `call`
          interface_Variant_newCopy(`r_return`, addr result)
    else:
      quote do:
        errproof:
          `options`
          let result = variant(); `call`
          interface_Variant_newCopy(`r_return`, addr result)

  result = quote do:
    proc(method_userdata: pointer; `p_instance`: ClassInstancePtr; `p_args`: ptr UncheckedArray[ConstVariantPtr]; `p_argument_count`: Int; `r_return`: VariantPtr; r_error: ptr CallError) {.gdcall.} =
      `body`

proc ptrCallFunc(middle: MiddleExp): NimNode =
  let p_instance = ident"p_instance"
  let p_args = ident"p_args"
  let r_ret = ident"r_ret"

  let self_T = middle.self_T

  var call = middle.name.newCall()
  if middle.is_static:
    call.add self_T
  else:
    call.add quote do: cast[`self_T`](`p_instance`)

  for i, (name, Type, default) in middle.args:
    let i_lit = newlit i
    call.add quote do: `p_args`[`i_lit`].decode(typedesc `Type`)

  let body =
    if middle.hasResult:
      quote do:
        errproof:
          `call`.encode(`r_ret`)
    else:
      quote do:
        errproof:
          `call`

  quote do:
    proc(method_userdata: pointer; `p_instance`: ClassInstancePtr; `p_args`: ptr UncheckedArray[ConstTypePtr]; `r_ret`: TypePtr) {.gdcall.} = `body`

proc flags(middle: MiddleExp): NimNode =
  result = newNimNode nnkCurly
  if middle.is_static:
    result.add bindSym"MethodFlag_Static"
  else:
    result.add bindSym"MethodFlag_Normal"


proc classMethodInfo(middle: MiddleExp; gdname: NimNode): NimNode =

  let call_func = middle.callFunc
  let ptrcall_func = middle.ptrCallFunc
  let method_flags = middle.flags

  let has_return_value = newlit middle.hasResult
  let return_value_info = middle.returnValueInfo
  let return_value_metadata = middle.returnValueMeta

  let argument_count = newlit middle.args.len
  let arguments_info = middle.argumentsInfo
  let arguments_metadata = middle.argumentsMeta

  let default_argument_count = middle.defaultArgumentCount
  let default_arguments = genSym(nskLet, "default_arguments")
  let defaultArgumentsArray = middle.declareDefaultArgumentsArray(default_arguments)

  result = quote do:
    let proc_name: StringName = stringName `gdname`
    `defaultArgumentsArray`
    ClassMethodInfo(
      name: addr proc_name,
      call_func: `call_func`,
      ptrcall_func: `ptrcall_func`,
      method_flags: cast[uint32](`method_flags`),

      has_return_value: `has_return_value`,
      return_value_info: `return_value_info`,
      return_value_metadata: `return_value_metadata`,

      argument_count: `argument_count`,
      arguments_info: `arguments_info`,
      arguments_metadata: `arguments_metadata`,

      default_argument_count: uint32 `default_argument_count`,
      default_arguments: `defaultarguments`,
    )

proc classMethodInfo*(procdef: NimNode; gdname: NimNode): NimNode =
  parseMiddle(procdef).classMethodInfo(gdname)