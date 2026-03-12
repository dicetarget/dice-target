enum UiOp { add, sub, mul, div }

String uiOpSymbol(UiOp op) => switch (op) {
  UiOp.add => '+',
  UiOp.sub => '−',
  UiOp.mul => '×',
  UiOp.div => '÷',
};
