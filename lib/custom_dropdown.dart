library custom_dropdown;

import 'package:flutter/material.dart';

typedef SelectedItemBuilder<T> = Widget Function(T? value);

typedef OnTapFieldSingle<T> = Function(void Function(T? value) onItemSelect);

typedef OnTapFieldMultiple<T> = Function(
    void Function(List<T>? value) onItemSelect);

typedef ValueAsString<T> = String Function(T?);

typedef Validator<T> = String? Function(T?);

typedef MultiSelectionValidator<T> = String? Function(List<T>?);

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

  final String labelText;

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
    required this.labelText,
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
    required this.labelText,
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
  final ValueNotifier<List<T>?> _mutlipleItemsNotifier = ValueNotifier([]);
  final ValueNotifier<bool> _focusNotifer = ValueNotifier(false);

  T? get getSingleItem => _singleItemNotifier.value;

  List<T>? get getMutipleItems => _mutlipleItemsNotifier.value;

  @override
  void initState() {
    initLoads();
    super.initState();
  }

  initLoads() {
    if (widget.selectedItem != null) {
      _singleItemNotifier.value = widget.selectedItem;
    }
    if (widget.selectedItems != null) {
      _mutlipleItemsNotifier.value = List.from(widget.selectedItems!);
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
                                    _mutlipleItemsNotifier.value = [];
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
