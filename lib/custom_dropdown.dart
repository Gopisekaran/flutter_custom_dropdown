library custom_dropdown;

import 'package:flutter/material.dart';
// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/foundation.dart';

typedef SelectedItemBuilder<T> = Widget Function(T? value);

typedef OnTapFieldSingle<T> = Function(
    T? selectedItem, void Function(T? value) onItemSelect);

typedef OnTapFieldMultiple<T> = Function(
    List<T>? selectedItems, void Function(List<T>? value) onItemSelect);

typedef ValueAsString<T> = String Function(T? value);

typedef Validator<T> = String? Function(T? value);

typedef MultiSelectionValidator<T> = String? Function(List<T>? values);

class GlobalDropdownField<T> extends StatefulWidget {
  /// Set [selectedItem] for setting single Item initial values
  final T? selectedItem;

  /// Set [selectedItems] for setting multiple Item initial values
  final List<T>? selectedItems;

  ///to enable Multiselection so that pop up can return the values as per configuration
  final bool isMultiSelection;

  /// to Build the custom widget to show the selected Item
  final SelectedItemBuilder<T>? selectedFieldBuilder;

  /// For Building muliple selected Items
  final SelectedItemBuilder<List<T>>? selectedItemsFieldBuilder;

  /// Event triggered on tapping text field which callback the function inside
  /// to get the selected value from child widget so that it can be updated in [_selectedItemsNotifier]
  /// So that field's state can be preserved
  final OnTapFieldSingle<T>? onTap;

  final OnTapFieldMultiple<T>? onTapMultiSelection;

  final void Function()? onAddButtonTap;

  /// to clear the value of Selected Item(s) and callback to perfrom additional operations
  final void Function()? onClear;

  final String? labelText;

  final String? hintText;

  /// To compare print generate the default widget
  final ValueAsString<T>? valueAsString;

  final Validator<T>? validator;

  final MultiSelectionValidator<T>? multiSelectValidator;

  final bool enabled;

  final InputDecoration? decoration;

  const GlobalDropdownField({
    super.key,
    this.selectedItem,
    this.selectedFieldBuilder,
    required this.onTap,
    this.onAddButtonTap,
    this.onClear,
    this.labelText,
    this.hintText = '',
    this.validator,
    this.enabled = true,
    this.decoration,
    this.valueAsString,
  })  : onTapMultiSelection = null,
        isMultiSelection = false,
        selectedItemsFieldBuilder = null,
        selectedItems = null,
        multiSelectValidator = null;

  const GlobalDropdownField.multiSelection({
    Key? key,
    required this.onTapMultiSelection,
    this.onAddButtonTap,
    this.onClear,
    this.labelText,
    this.hintText = '',
    this.enabled = true,
    this.decoration,
    this.valueAsString,
    this.selectedItems,
    this.multiSelectValidator,
    this.selectedItemsFieldBuilder,
  })  : onTap = null,
        isMultiSelection = true,
        selectedItem = null,
        selectedFieldBuilder = null,
        validator = null,
        super(key: key);

  @override
  State<GlobalDropdownField<T>> createState() => _GlobalDropdownFieldState<T>();
}

class _GlobalDropdownFieldState<T> extends State<GlobalDropdownField<T>> {
  final ValueNotifier<T?> _singleItemNotifier = ValueNotifier(null);
  final ValueNotifier<List<T>?> _mutlipleItemsNotifier = ValueNotifier(null);
  final ValueNotifier<bool> _focusNotifer = ValueNotifier(false);

  T? get getSingleItem => _singleItemNotifier.value;

  List<T>? get getMutipleItems => _mutlipleItemsNotifier.value;

  @override
  void initState() {
    initLoads();
    super.initState();
  }

  @override
  void didUpdateWidget(GlobalDropdownField<T> oldWidget) {
    if (widget.isMultiSelection) {
      if (!listEquals(oldWidget.selectedItems, widget.selectedItems)) {
        _mutlipleItemsNotifier.value = widget.selectedItems;
      }
    } else {
      if (oldWidget.selectedItem != widget.selectedItem) {
        _singleItemNotifier.value = widget.selectedItem;
      }
    }

    super.didUpdateWidget(oldWidget);
  }

  initLoads() {
    if (widget.selectedItem != null) {
      _singleItemNotifier.value = widget.selectedItem;
    }
    if (widget.selectedItems != null) {
      _mutlipleItemsNotifier.value = widget.selectedItems;
    }
  }

  @override
  Widget build(BuildContext context) {
    return _formField();
  }

  Widget _formField() {
    return widget.isMultiSelection
        ? _formFieldMultiSelection()
        : _formFieldSingleSelection();
  }

  Widget _formFieldMultiSelection() {
    return ValueListenableBuilder<List<T>?>(
        valueListenable: _mutlipleItemsNotifier,
        builder: (BuildContext context, data, widgets) {
          return _ignorePointerWrapper(
            child: InkWell(
              onTap: () {
                widget.onTapMultiSelection!(
                  _mutlipleItemsNotifier.value,
                  (value) {
                    _mutlipleItemsNotifier.value = value!;
                  },
                );
              },
              child: FormField<List<T>>(
                enabled: widget.enabled,
                initialValue: widget.selectedItems,
                validator: widget.multiSelectValidator,
                builder: (FormFieldState<List<T>> state) {
                  return ValueListenableBuilder<bool>(
                      valueListenable: _focusNotifer,
                      builder: (BuildContext context, data, widgets) {
                        if (state.value != getMutipleItems) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            state.didChange(getMutipleItems);
                          });
                        }
                        return InputDecorator(
                          isEmpty: state.value == null,
                          decoration: InputDecoration(
                              errorText: state.errorText,
                              errorStyle: const TextStyle(color: Colors.red)),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: state.value != null
                                    ? widget.selectedFieldBuilder != null
                                        ? widget.selectedItemsFieldBuilder!(
                                            state.value)
                                        : Text(widget.valueAsString != null
                                            ? state.value!
                                                .map((e) =>
                                                    widget.valueAsString!(e))
                                                .toString()
                                            : state.toString())
                                    : const Text("Select Item"),
                              ),
                              if (state.value != null && widget.onClear != null)
                                MaterialButton(
                                  height: 20,
                                  shape: const CircleBorder(),
                                  padding: const EdgeInsets.all(0),
                                  minWidth: 20,
                                  onPressed: () {
                                    _mutlipleItemsNotifier.value = null;
                                    state.didChange(null);
                                    widget.onClear!();
                                  },
                                  child: const Icon(
                                    Icons.close_outlined,
                                    size: 20,
                                  ),
                                )
                            ],
                          ),
                        );
                      });
                },
              ),
            ),
          );
        });
  }

  Widget _ignorePointerWrapper({required Widget child}) {
    return IgnorePointer(
      ignoring: !widget.enabled,
      child: child,
    );
  }

  Widget _formFieldSingleSelection() {
    return ValueListenableBuilder<T?>(
        valueListenable: _singleItemNotifier,
        builder: (BuildContext context, data, widgets) {
          return _ignorePointerWrapper(
            child: InkWell(
              onTap: () {
                widget.onTap!(
                  _singleItemNotifier.value,
                  (value) {
                    _singleItemNotifier.value = value;
                  },
                );
              },
              child: FormField<T>(
                enabled: widget.enabled,
                initialValue: widget.selectedItem,
                validator: widget.validator,
                builder: (FormFieldState<T> state) {
                  return ValueListenableBuilder<bool>(
                      valueListenable: _focusNotifer,
                      builder: (BuildContext context, data, widgets) {
                        if (state.value != getSingleItem) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            state.didChange(getSingleItem);
                          });
                        }
                        return InputDecorator(
                          isEmpty: state.value == null,
                          decoration: InputDecoration(
                              errorText: state.errorText,
                              errorStyle: const TextStyle(color: Colors.red)),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: state.value != null
                                    ? widget.selectedFieldBuilder != null
                                        ? widget
                                            .selectedFieldBuilder!(state.value)
                                        : Text(widget.valueAsString != null
                                            ? widget.valueAsString!(state.value)
                                            : state.toString())
                                    : const Text("Select Item"),
                              ),
                              if (state.value != null && widget.onClear != null)
                                MaterialButton(
                                  height: 20,
                                  shape: const CircleBorder(),
                                  padding: const EdgeInsets.all(0),
                                  minWidth: 20,
                                  onPressed: () {
                                    _singleItemNotifier.value = null;
                                    state.didChange(null);
                                    widget.onClear!();
                                  },
                                  child: const Icon(
                                    Icons.close_outlined,
                                    size: 20,
                                  ),
                                )
                            ],
                          ),
                        );
                      });
                },
              ),
            ),
          );
        });
  }
}

GlobalKey<FormState> loginFormKey = GlobalKey<FormState>();

class DropDownCheck extends StatefulWidget {
  const DropDownCheck({super.key});

  @override
  State<DropDownCheck> createState() => _DropDownCheckState();
}

class _DropDownCheckState extends State<DropDownCheck> {
  DataClass? item =
      DataClass(id: "123", name: "gopi", desc: "desc", active: true);
  List<DataClass>? multiSelection;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Form(
        key: loginFormKey,
        child: SingleChildScrollView(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(40),
                child: GlobalDropdownField<DataClass>(
                  valueAsString: (p0) => p0.toString(),
                  selectedItem: item,
                  onClear: () {
                    setState(() {
                      item = null;
                    });
                  },
                  validator: (p0) {
                    if (p0 == null) {
                      return "enter";
                    }
                    return null;
                  },
                  onTap: (selectedItem, onItemSelect) {
                    showDialog(
                      context: context,
                      barrierDismissible: true,
                      builder: (BuildContext context) {
                        return Dialog(
                          child: SizedBox(
                            height: 300,
                            child: ListView.builder(
                              itemCount: dataClassValues.length,
                              itemBuilder: (context, index) {
                                return ListTile(
                                  leading:
                                      Text(dataClassValues[index].id ?? ''),
                                  onTap: () {
                                    onItemSelect(dataClassValues[index]);
                                    setState(() {
                                      item = dataClassValues[index];
                                    });
                                    Navigator.pop(context);
                                  },
                                  title:
                                      Text(dataClassValues[index].name ?? ''),
                                  subtitle:
                                      Text(dataClassValues[index].desc ?? ''),
                                );
                              },
                            ),
                          ),
                        );
                      },
                    );
                  },
                  labelText: "Hello",
                ),
              ),
              Container(
                padding: const EdgeInsets.all(40),
                child: GlobalDropdownField<DataClass>(
                  valueAsString: (p0) => p0.toString(),
                  selectedItem: item,
                  onClear: () {},
                  validator: (p0) {
                    if (p0 == null) {
                      return "enter";
                    }
                    return null;
                  },
                  onTap: (selectedItem, onItemSelect) {
                    showDialog(
                      context: context,
                      barrierDismissible: true,
                      builder: (BuildContext context) {
                        return Dialog(
                          child: SizedBox(
                            height: 300,
                            child: ListView.builder(
                              itemCount: dataClassValues.length,
                              itemBuilder: (context, index) {
                                return ListTile(
                                  leading:
                                      Text(dataClassValues[index].id ?? ''),
                                  onTap: () {
                                    onItemSelect(dataClassValues[index]);
                                    setState(() {
                                      item = dataClassValues[index];
                                    });
                                    Navigator.pop(context);
                                  },
                                  title:
                                      Text(dataClassValues[index].name ?? ''),
                                  subtitle:
                                      Text(dataClassValues[index].desc ?? ''),
                                );
                              },
                            ),
                          ),
                        );
                      },
                    );
                  },
                  labelText: "Hello",
                ),
              ),
              Container(
                padding: const EdgeInsets.all(40),
                child: GlobalDropdownField<DataClass>(
                  valueAsString: (p0) => p0.toString(),
                  selectedItem: item,
                  onClear: () {},
                  validator: (p0) {
                    if (p0 == null) {
                      return "enter";
                    }
                    return null;
                  },
                  onTap: (selectedItem, onItemSelect) {
                    showDialog(
                      context: context,
                      barrierDismissible: true,
                      builder: (BuildContext context) {
                        return Dialog(
                          child: SizedBox(
                            height: 300,
                            child: ListView.builder(
                              itemCount: dataClassValues.length,
                              itemBuilder: (context, index) {
                                return ListTile(
                                  leading:
                                      Text(dataClassValues[index].id ?? ''),
                                  onTap: () {
                                    onItemSelect(dataClassValues[index]);
                                    setState(() {
                                      item = dataClassValues[index];
                                    });
                                    Navigator.pop(context);
                                  },
                                  title:
                                      Text(dataClassValues[index].name ?? ''),
                                  subtitle:
                                      Text(dataClassValues[index].desc ?? ''),
                                );
                              },
                            ),
                          ),
                        );
                      },
                    );
                  },
                  labelText: "Hello",
                ),
              ),
              Container(
                padding: const EdgeInsets.all(40),
                child: GlobalDropdownField<DataClass>(
                  valueAsString: (p0) => p0.toString(),
                  selectedItem: item,
                  onClear: () {},
                  validator: (p0) {
                    if (p0 == null) {
                      return "enter";
                    }
                    return null;
                  },
                  onTap: (selectedItem, onItemSelect) {
                    showDialog(
                      context: context,
                      barrierDismissible: true,
                      builder: (BuildContext context) {
                        return Dialog(
                          child: SizedBox(
                            height: 300,
                            child: ListView.builder(
                              itemCount: dataClassValues.length,
                              itemBuilder: (context, index) {
                                return ListTile(
                                  leading:
                                      Text(dataClassValues[index].id ?? ''),
                                  onTap: () {
                                    onItemSelect(dataClassValues[index]);
                                    setState(() {
                                      item = dataClassValues[index];
                                    });
                                    Navigator.pop(context);
                                  },
                                  title:
                                      Text(dataClassValues[index].name ?? ''),
                                  subtitle:
                                      Text(dataClassValues[index].desc ?? ''),
                                );
                              },
                            ),
                          ),
                        );
                      },
                    );
                  },
                  labelText: "Hello",
                ),
              ),
              Container(
                padding: const EdgeInsets.all(40),
                child: GlobalDropdownField<DataClass>(
                  valueAsString: (p0) => p0.toString(),
                  selectedItem: item,
                  onClear: () {},
                  validator: (p0) {
                    if (p0 == null) {
                      return "enter";
                    }
                    return null;
                  },
                  onTap: (selectedItem, onItemSelect) {
                    showDialog(
                      context: context,
                      barrierDismissible: true,
                      builder: (BuildContext context) {
                        return Dialog(
                          child: SizedBox(
                            height: 300,
                            child: ListView.builder(
                              itemCount: dataClassValues.length,
                              itemBuilder: (context, index) {
                                return ListTile(
                                  leading:
                                      Text(dataClassValues[index].id ?? ''),
                                  onTap: () {
                                    onItemSelect(dataClassValues[index]);
                                    setState(() {
                                      item = dataClassValues[index];
                                    });
                                    Navigator.pop(context);
                                  },
                                  title:
                                      Text(dataClassValues[index].name ?? ''),
                                  subtitle:
                                      Text(dataClassValues[index].desc ?? ''),
                                );
                              },
                            ),
                          ),
                        );
                      },
                    );
                  },
                  labelText: "Hello",
                ),
              ),
              Container(
                padding: const EdgeInsets.all(40),
                child: GlobalDropdownField<DataClass>(
                  valueAsString: (p0) => p0.toString(),
                  selectedItem: item,
                  onClear: () {},
                  validator: (p0) {
                    if (p0 == null) {
                      return "enter";
                    }
                    return null;
                  },
                  onTap: (selectedItem, onItemSelect) {
                    showDialog(
                      context: context,
                      barrierDismissible: true,
                      builder: (BuildContext context) {
                        return Dialog(
                          child: SizedBox(
                            height: 300,
                            child: ListView.builder(
                              itemCount: dataClassValues.length,
                              itemBuilder: (context, index) {
                                return ListTile(
                                  leading:
                                      Text(dataClassValues[index].id ?? ''),
                                  onTap: () {
                                    onItemSelect(dataClassValues[index]);
                                    setState(() {
                                      item = dataClassValues[index];
                                    });
                                    Navigator.pop(context);
                                  },
                                  title:
                                      Text(dataClassValues[index].name ?? ''),
                                  subtitle:
                                      Text(dataClassValues[index].desc ?? ''),
                                );
                              },
                            ),
                          ),
                        );
                      },
                    );
                  },
                  labelText: "Hello",
                ),
              ),
              Container(
                padding: const EdgeInsets.all(40),
                child: GlobalDropdownField<DataClass>(
                  valueAsString: (p0) => p0.toString(),
                  selectedItem: item,
                  onClear: () {},
                  validator: (p0) {
                    if (p0 == null) {
                      return "enter";
                    }
                    return null;
                  },
                  onTap: (selectedItem, onItemSelect) {
                    showDialog(
                      context: context,
                      barrierDismissible: true,
                      builder: (BuildContext context) {
                        return Dialog(
                          child: SizedBox(
                            height: 300,
                            child: ListView.builder(
                              itemCount: dataClassValues.length,
                              itemBuilder: (context, index) {
                                return ListTile(
                                  leading:
                                      Text(dataClassValues[index].id ?? ''),
                                  onTap: () {
                                    onItemSelect(dataClassValues[index]);
                                    setState(() {
                                      item = dataClassValues[index];
                                    });
                                    Navigator.pop(context);
                                  },
                                  title:
                                      Text(dataClassValues[index].name ?? ''),
                                  subtitle:
                                      Text(dataClassValues[index].desc ?? ''),
                                );
                              },
                            ),
                          ),
                        );
                      },
                    );
                  },
                  labelText: "Hello",
                ),
              ),
              Container(
                padding: const EdgeInsets.all(40),
                child: GlobalDropdownField<DataClass>(
                  valueAsString: (p0) => p0.toString(),
                  selectedItem: item,
                  onClear: () {},
                  validator: (p0) {
                    if (p0 == null) {
                      return "enter";
                    }
                    return null;
                  },
                  onTap: (selectedItem, onItemSelect) {
                    showDialog(
                      context: context,
                      barrierDismissible: true,
                      builder: (BuildContext context) {
                        return Dialog(
                          child: SizedBox(
                            height: 300,
                            child: ListView.builder(
                              itemCount: dataClassValues.length,
                              itemBuilder: (context, index) {
                                return ListTile(
                                  leading:
                                      Text(dataClassValues[index].id ?? ''),
                                  onTap: () {
                                    onItemSelect(dataClassValues[index]);
                                    setState(() {
                                      item = dataClassValues[index];
                                    });
                                    Navigator.pop(context);
                                  },
                                  title:
                                      Text(dataClassValues[index].name ?? ''),
                                  subtitle:
                                      Text(dataClassValues[index].desc ?? ''),
                                );
                              },
                            ),
                          ),
                        );
                      },
                    );
                  },
                  labelText: "Hello",
                ),
              ),
              Container(
                padding: const EdgeInsets.all(40),
                child: GlobalDropdownField<DataClass>.multiSelection(
                  onTapMultiSelection: (selectedItems, onItemSelect) {
                    showDialog(
                      context: context,
                      barrierDismissible: true,
                      builder: (BuildContext context) {
                        return Dialog(
                            child: MultiSelectionPopup(
                                dataList: selectedItems,
                                callback: (data) {
                                  setState(() {
                                    multiSelection = data;
                                  });
                                  onItemSelect(data);
                                }));
                      },
                    );
                  },
                  valueAsString: (p0) => p0.toString(),
                  selectedItems: multiSelection,
                  onClear: () {},
                  multiSelectValidator: (p0) {
                    if (p0 == null || p0.isEmpty) {
                      return "enter";
                    }
                    return null;
                  },
                  labelText: "Hello",
                ),
              ),
              const SizedBox(
                height: 40,
              ),
              TextButton(
                  onPressed: () {
                    setState(() {});
                    loginFormKey.currentState!.validate();
                  },
                  child: const Text("Submit")),
            ],
          ),
        ),
      ),
    );
  }
}

class MultiSelectionPopup extends StatefulWidget {
  final List<DataClass>? dataList;

  final void Function(List<DataClass>?) callback;

  const MultiSelectionPopup({
    Key? key,
    required this.callback,
    required this.dataList,
  }) : super(key: key);

  @override
  State<MultiSelectionPopup> createState() => _MultiSelectionPopupState();
}

class _MultiSelectionPopupState extends State<MultiSelectionPopup> {
  List<DataClass> list = [];

  getIfFound(int index) {
    for (var value in list) {
      if (value == dataClassValues[index]) {
        return true;
      }
    }
    return false;
  }

  @override
  void initState() {
    setState(() {
      list = widget.dataList ?? [];
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 300,
      child: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: dataClassValues.length,
              itemBuilder: (context, index) {
                return Row(
                  children: [
                    Checkbox(
                      onChanged: (value) {
                        if (value!) {
                          var temp = [...list, dataClassValues[index]];
                          setState(() {
                            list = temp;
                          });
                        } else {
                          var temp = [...list];
                          temp.remove(dataClassValues[index]);
                          setState(() {
                            list = temp;
                          });
                        }
                      },
                      value: getIfFound(index),
                    ),
                    Text(dataClassValues[index].name ?? ''),
                  ],
                );
              },
            ),
          ),
          TextButton(
              onPressed: () {
                widget.callback(list.isEmpty ? null : list);
                Navigator.pop(context);
              },
              child: Text("Submit"))
        ],
      ),
    );
  }
}

class DataClass {
  String? name;
  String? id;
  String? desc;
  bool? active;

  DataClass({
    this.name,
    this.id,
    this.desc,
    this.active,
  });

  @override
  bool operator ==(covariant DataClass other) {
    if (identical(this, other)) return true;

    return other.name == name && other.id == id;
  }

  @override
  int get hashCode {
    return name.hashCode ^ id.hashCode ^ desc.hashCode ^ active.hashCode;
  }

  @override
  String toString() {
    return 'name: $name, id: $id, desc: $desc, active: $active';
  }
}

final List<DataClass> dataClassValues = [
  DataClass(id: "1", name: "One", desc: "One Desc", active: true),
  DataClass(id: "2", name: "Two", desc: "Two Desc", active: true),
  DataClass(id: "3", name: "Three", desc: "Three Desc", active: true),
  DataClass(id: "4", name: "Four", desc: "Four Desc", active: true),
  DataClass(id: "5", name: "Five", desc: "Five Desc", active: true),
  DataClass(id: "6", name: "Six", desc: "Six Desc", active: true),
  DataClass(id: "7", name: "Seven", desc: "Seven Desc", active: true),
  DataClass(id: "8", name: "Eight", desc: "Eight Desc", active: true),
  DataClass(id: "9", name: "Nine", desc: "Nine Desc", active: true),
  DataClass(id: "10", name: "Ten", desc: "Ten Desc", active: true),
];
