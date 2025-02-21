// RUN: torch-mlir-opt -torch-decompose-complex-ops -split-input-file %s | FileCheck %s

// CHECK-LABEL:   func @matmul_no_decompose
// CHECK:           torch.aten.matmul %arg0, %arg1 : !torch.vtensor<[?,?,?,?,?],f32>, !torch.vtensor<[?,?,?],f32> -> !torch.tensor
func @matmul_no_decompose(%arg0: !torch.vtensor<[?,?,?,?,?],f32>, %arg1: !torch.vtensor<[?,?,?],f32>) -> !torch.tensor {
  %0 = torch.aten.matmul %arg0, %arg1 : !torch.vtensor<[?,?,?,?,?],f32>, !torch.vtensor<[?,?,?],f32> -> !torch.tensor
  return %0 : !torch.tensor
}


// -----

// CHECK-LABEL:   func @matmul_decompose_2d
// CHECK:           torch.aten.mm %arg0, %arg1 : !torch.vtensor<[?,?],f32>, !torch.vtensor<[?,?],f32> -> !torch.tensor
func @matmul_decompose_2d(%arg0: !torch.vtensor<[?,?],f32>, %arg1: !torch.vtensor<[?,?],f32>) -> !torch.tensor {
  %0 = torch.aten.matmul %arg0, %arg1 : !torch.vtensor<[?,?],f32>, !torch.vtensor<[?,?],f32> -> !torch.tensor
  return %0 : !torch.tensor
}

// -----
// CHECK-LABEL:   func @matmul_decompose_3d(
// CHECK:           torch.aten.bmm %arg0, %arg1 : !torch.vtensor<[?,?,?],f32>, !torch.vtensor<[?,?,?],f32> -> !torch.tensor
func @matmul_decompose_3d(%arg0: !torch.vtensor<[?,?,?],f32>, %arg1: !torch.vtensor<[?,?,?],f32>) -> !torch.tensor {
  %0 = torch.aten.matmul %arg0, %arg1 : !torch.vtensor<[?,?,?],f32>, !torch.vtensor<[?,?,?],f32> -> !torch.tensor
  return %0 : !torch.tensor
}

// -----
// CHECK-LABEL:   func @torch.aten.softmax.int(
// CHECK-SAME:                                 %[[T:.*]]: !torch.tensor<[2,3],f32>,
// CHECK-SAME:                                 %[[DIM:.*]]: !torch.int) -> !torch.tensor<[2,3],f32> {
// CHECK:           %[[DTYPE:.*]] = torch.constant.none
// CHECK:           %[[KEEP_DIM0:.*]] = torch.constant.bool true
// CHECK:           %[[VAL:.*]], %[[IND:.*]] = torch.aten.max.dim %[[T]], %[[DIM]], %[[KEEP_DIM0]] :
// CHECK-SAME:                 !torch.tensor<[2,3],f32>, !torch.int, !torch.bool -> !torch.tensor<[?,?],f32>, !torch.tensor<[?,?],si64>
// CHECK:           %[[FLOAT1:.*]] = torch.constant.float 1.000000e+00
// CHECK:           %[[SUB:.*]] = torch.aten.sub.Tensor %[[T]], %[[VAL]], %[[FLOAT1]] : !torch.tensor<[2,3],f32>,
// CHECK-SAME:          !torch.tensor<[?,?],f32>, !torch.float -> !torch.tensor<[2,3],f32>
// CHECK:           %[[EXP:.*]] = torch.aten.exp %[[SUB]] : !torch.tensor<[2,3],f32> -> !torch.tensor<[2,3],f32>
// CHECK:           %[[DIM_LIST:.*]] = torch.prim.ListConstruct %[[DIM]] : (!torch.int) -> !torch.list<!torch.int>
// CHECK:           %[[KEEP_DIM:.*]] = torch.constant.bool true
// CHECK:           %[[SUM_DTYPE:.*]] = torch.constant.none
// CHECK:           %[[SUM:.*]] = torch.aten.sum.dim_IntList %[[EXP]], %[[DIM_LIST]], %[[KEEP_DIM]], %[[SUM_DTYPE]] :
// CHECK-SAME:          !torch.tensor<[2,3],f32>, !torch.list<!torch.int>, !torch.bool, !torch.none -> !torch.tensor<[?,?],f32>
// CHECK:           %[[SOFTMAX:.*]] = torch.aten.div.Tensor %[[EXP]], %[[SUM]] : !torch.tensor<[2,3],f32>, !torch.tensor<[?,?],f32> -> !torch.tensor<[2,3],f32>
// CHECK:           %[[RET:.*]] = torch.tensor_static_info_cast %[[SOFTMAX]] : !torch.tensor<[2,3],f32> to !torch.tensor<[2,3],f32>
// CHECK:           return %[[RET]] : !torch.tensor<[2,3],f32>
func @torch.aten.softmax.int(%t: !torch.tensor<[2,3],f32>, %dim: !torch.int) -> !torch.tensor<[2,3],f32> {
  %dtype = torch.constant.none
  %ret = torch.aten.softmax.int %t, %dim, %dtype: !torch.tensor<[2,3],f32>, !torch.int, !torch.none -> !torch.tensor<[2,3],f32>
  return %ret : !torch.tensor<[2,3],f32>
}


// -----
// CHECK-LABEL:   func @torch.aten.softmax.int$cst_dim(
// CHECK-SAME:                                         %[[T:.*]]: !torch.tensor<[2,3],f32>) -> !torch.tensor<[2,3],f32> {
// CHECK:           %[[DTYPE:.*]] = torch.constant.none
// CHECK:           %[[DIM:.*]] = torch.constant.int 1
// CHECK:           %[[TRU:.*]] = torch.constant.bool true
// CHECK:           %[[VAL:.*]], %[[IND:.*]] = torch.aten.max.dim %[[T]], %[[DIM]], %[[TRU]] : !torch.tensor<[2,3],f32>, !torch.int, !torch.bool ->
// CHECK-SAME:              !torch.tensor<[2,1],f32>, !torch.tensor<[2,1],si64>
// CHECK:           %[[FLOAT1:.*]] = torch.constant.float 1.000000e+00
// CHECK:           %[[SUB:.*]] = torch.aten.sub.Tensor %[[T]], %[[VAL]], %[[FLOAT1]] : !torch.tensor<[2,3],f32>,
// CHECK-SAME:          !torch.tensor<[2,1],f32>, !torch.float -> !torch.tensor<[2,3],f32>
// CHECK:           %[[EXP:.*]] = torch.aten.exp %[[SUB]] : !torch.tensor<[2,3],f32> -> !torch.tensor<[2,3],f32>
// CHECK:           %[[DIM_LIST:.*]] = torch.prim.ListConstruct %[[DIM]] : (!torch.int) -> !torch.list<!torch.int>
// CHECK:           %[[KEEP_DIM:.*]] = torch.constant.bool true
// CHECK:           %[[SUM_DTYPE:.*]] = torch.constant.none
// CHECK:           %[[SUM:.*]] = torch.aten.sum.dim_IntList %[[EXP]], %[[DIM_LIST]], %[[KEEP_DIM]], %[[SUM_DTYPE]] :
// CHECK-SAME           !torch.tensor<[2,3],f32>, !torch.list<!torch.int>, !torch.bool, !torch.none -> !torch.tensor<[2,1],f32>
// CHECK:           %[[SOFTMAX:.*]] = torch.aten.div.Tensor %[[EXP]], %[[SUM]] : !torch.tensor<[2,3],f32>, !torch.tensor<[2,1],f32> -> !torch.tensor<[2,3],f32>
// CHECK:           %[[RET:.*]] = torch.tensor_static_info_cast %[[SOFTMAX]] : !torch.tensor<[2,3],f32> to !torch.tensor<[2,3],f32>
// CHECK:           return %[[RET]] : !torch.tensor<[2,3],f32>
func @torch.aten.softmax.int$cst_dim(%t: !torch.tensor<[2,3],f32>) -> !torch.tensor<[2,3],f32> {
  %none = torch.constant.none
  %dim = torch.constant.int 1
  %ret = torch.aten.softmax.int %t, %dim, %none : !torch.tensor<[2,3],f32>, !torch.int, !torch.none -> !torch.tensor<[2,3],f32>
  return %ret : !torch.tensor<[2,3],f32>
}

// -----
// CHECK-LABEL:   func @torch.aten.softmax.int$dyn_shape(
// CHECK-SAME:                                           %[[T:.*]]: !torch.tensor<[?,?],f32>) -> !torch.tensor<[?,?],f32> {
// CHECK:           %[[DTYPE:.*]] = torch.constant.none
// CHECK:           %[[DIM:.*]] = torch.constant.int 1
// CHECK:           %[[TRU:.*]] = torch.constant.bool true
// CHECK:           %[[VAL:.*]], %[[IND:.*]] = torch.aten.max.dim %[[T]], %[[DIM]], %[[TRU]] : !torch.tensor<[?,?],f32>, !torch.int, !torch.bool ->
// CHECK-SAME:          !torch.tensor<[?,1],f32>, !torch.tensor<[?,1],si64>
// CHECK:           %[[FLOAT1:.*]] = torch.constant.float 1.000000e+00
// CHECK:           %[[SUB:.*]] = torch.aten.sub.Tensor %[[T]], %[[VAL]], %[[FLOAT1]] : !torch.tensor<[?,?],f32>,
// CHECK-SAME:          !torch.tensor<[?,1],f32>, !torch.float -> !torch.tensor<[?,?],f32>
// CHECK:           %[[EXP:.*]] = torch.aten.exp %[[SUB]] : !torch.tensor<[?,?],f32> -> !torch.tensor<[?,?],f32>
// CHECK:           %[[DIM_LIST:.*]] = torch.prim.ListConstruct %[[DIM]] : (!torch.int) -> !torch.list<!torch.int>
// CHECK:           %[[KEEP_DIM:.*]] = torch.constant.bool true
// CHECK:           %[[SUM_DTYPE:.*]] = torch.constant.none
// CHECK:           %[[SUM:.*]] = torch.aten.sum.dim_IntList %[[EXP]], %[[DIM_LIST]], %[[KEEP_DIM]], %[[SUM_DTYPE]] :
// CHECK-SAME:          !torch.tensor<[?,?],f32>, !torch.list<!torch.int>, !torch.bool, !torch.none -> !torch.tensor<[?,1],f32>
// CHECK:           %[[SOFTMAX:.*]] = torch.aten.div.Tensor %[[EXP]], %[[SUM]] : !torch.tensor<[?,?],f32>, !torch.tensor<[?,1],f32> -> !torch.tensor<[?,?],f32>
// CHECK:           %[[RET:.*]] = torch.tensor_static_info_cast %[[SOFTMAX]] : !torch.tensor<[?,?],f32> to !torch.tensor<[?,?],f32>
// CHECK:           return %[[RET]] : !torch.tensor<[?,?],f32>
func @torch.aten.softmax.int$dyn_shape(%t: !torch.tensor<[?,?],f32>) -> !torch.tensor<[?,?],f32> {
  %none = torch.constant.none
  %dim = torch.constant.int 1
  %ret = torch.aten.softmax.int %t, %dim, %none : !torch.tensor<[?,?],f32>, !torch.int, !torch.none -> !torch.tensor<[?,?],f32>
  return %ret : !torch.tensor<[?,?],f32>
}

// -----
// CHECK-LABEL:   func @torch.aten.softmax.int$unknown_shape(
// CHECK-SAME:                                               %[[T:.*]]: !torch.tensor<*,f32>) -> !torch.tensor<*,f32> {
// CHECK:           %[[DTYPE:.*]] = torch.constant.none
// CHECK:           %[[DIM:.*]] = torch.constant.int 1
// CHECK:           %[[TRU:.*]] = torch.constant.bool true
// CHECK:           %[[VAL:.*]], %[[IND:.*]] = torch.aten.max.dim %[[T]], %[[DIM]], %[[TRU]] : !torch.tensor<*,f32>, !torch.int, !torch.bool
// CHECK-SAME:          -> !torch.tensor<*,f32>, !torch.tensor<*,si64>
// CHECK:           %[[FLOAT1:.*]] = torch.constant.float 1.000000e+00
// CHECK:           %[[SUB:.*]] = torch.aten.sub.Tensor %[[T]], %[[VAL]], %[[FLOAT1]] : !torch.tensor<*,f32>, !torch.tensor<*,f32>,
// CHECK-SAME:          !torch.float -> !torch.tensor<*,f32>
// CHECK:           %[[EXP:.*]] = torch.aten.exp %[[SUB]] : !torch.tensor<*,f32> -> !torch.tensor<*,f32>
// CHECK:           %[[DIM_LIST:.*]] = torch.prim.ListConstruct %[[DIM]] : (!torch.int) -> !torch.list<!torch.int>
// CHECK:           %[[KEEP_DIM:.*]] = torch.constant.bool true
// CHECK:           %[[SUM_DTYPE:.*]] = torch.constant.none
// CHECK:           %[[SUM:.*]] = torch.aten.sum.dim_IntList %[[EXP]], %[[DIM_LIST]], %[[KEEP_DIM]], %[[SUM_DTYPE]] :
// CHECK-SAME:          !torch.tensor<*,f32>, !torch.list<!torch.int>, !torch.bool, !torch.none -> !torch.tensor<*,f32>
// CHECK:           %[[SOFTMAX:.*]] = torch.aten.div.Tensor %[[EXP]], %[[SUM]] : !torch.tensor<*,f32>, !torch.tensor<*,f32> -> !torch.tensor<*,f32>
// CHECK:           %[[RET:.*]] = torch.tensor_static_info_cast %[[SOFTMAX]] : !torch.tensor<*,f32> to !torch.tensor<*,f32>
// CHECK:           return %[[RET]] : !torch.tensor<*,f32>
func @torch.aten.softmax.int$unknown_shape(%t: !torch.tensor<*,f32>) -> !torch.tensor<*,f32> {
  %none = torch.constant.none
  %dim = torch.constant.int 1
  %ret = torch.aten.softmax.int %t, %dim, %none : !torch.tensor<*,f32>, !torch.int, !torch.none -> !torch.tensor<*,f32>
  return %ret : !torch.tensor<*,f32>
}

// -----
// CHECK-LABEL:   func @torch.aten.size(
// CHECK-SAME:                         %[[T:.*]]: !torch.vtensor<[?,3],f32>) -> !torch.list<!torch.int> {
// CHECK:           %[[CST0:.*]] = torch.constant.int 0
// CHECK:           %[[DIM0:.*]] = torch.aten.size.int %[[T]], %[[CST0]] : !torch.vtensor<[?,3],f32>, !torch.int -> !torch.int
// CHECK:           %[[CST1:.*]] = torch.constant.int 1
// CHECK:           %[[DIM1:.*]] = torch.aten.size.int %[[T]], %[[CST1]] : !torch.vtensor<[?,3],f32>, !torch.int -> !torch.int
// CHECK:           %[[SIZE:.*]] = torch.prim.ListConstruct %[[DIM0]], %[[DIM1]] : (!torch.int, !torch.int) -> !torch.list<!torch.int>
// CHECK:           return %[[SIZE]] : !torch.list<!torch.int>
func @torch.aten.size(%arg0: !torch.vtensor<[?,3],f32>) -> !torch.list<!torch.int> {
  %0 = torch.aten.size %arg0 : !torch.vtensor<[?,3],f32> -> !torch.list<!torch.int>
  return %0 : !torch.list<!torch.int>
}

// -----
// CHECK-LABEL:   func @torch.aten.arange() -> !torch.vtensor<[?],si64> {
// CHECK:           %[[CST5:.*]] = torch.constant.int 5
// CHECK:           %[[CSTN:.*]] = torch.constant.none
// CHECK:           %[[CST0:.*]] = torch.constant.int 0
// CHECK:           %[[CST1:.*]] = torch.constant.int 1
// CHECK:           %[[RESULT:.*]] = torch.aten.arange.start_step %[[CST0]], %[[CST5]], %[[CST1]], %[[CSTN]], %[[CSTN]], %[[CSTN]], %[[CSTN]] :
// CHECK-SAME:          !torch.int, !torch.int, !torch.int, !torch.none, !torch.none, !torch.none, !torch.none -> !torch.vtensor<[?],si64>
// CHECK:           return %[[RESULT]] : !torch.vtensor<[?],si64>
func @torch.aten.arange() -> !torch.vtensor<[?],si64> {
  %int5 = torch.constant.int 5
  %none = torch.constant.none
  %0 = torch.aten.arange %int5, %none, %none, %none, %none : !torch.int, !torch.none, !torch.none, !torch.none, !torch.none -> !torch.vtensor<[?],si64>
  return %0 : !torch.vtensor<[?],si64>
}

// -----
// CHECK-LABEL:   func @torch.aten.arange.start() -> !torch.vtensor<[?],si64> {
// CHECK:           %[[CST10:.*]] = torch.constant.int 10
// CHECK:           %[[CST0:.*]] = torch.constant.int 0
// CHECK:           %[[CSTN:.*]] = torch.constant.none
// CHECK:           %[[CST1:.*]] = torch.constant.int 1
// CHECK:           %[[RESULT:.*]] = torch.aten.arange.start_step %[[CST0]], %[[CST10]], %[[CST1]], %[[CSTN]], %[[CSTN]], %[[CSTN]], %[[CSTN]] :
// CHECK-SAME:          !torch.int, !torch.int, !torch.int, !torch.none, !torch.none, !torch.none, !torch.none -> !torch.vtensor<[?],si64>
// CHECK:           return %[[RESULT]] : !torch.vtensor<[?],si64>
func @torch.aten.arange.start() -> !torch.vtensor<[?],si64> {
  %int10 = torch.constant.int 10
  %int0 = torch.constant.int 0
  %none = torch.constant.none
  %0 = torch.aten.arange.start %int0, %int10, %none, %none, %none, %none : !torch.int, !torch.int, !torch.none, !torch.none, !torch.none, !torch.none -> !torch.vtensor<[?],si64>
  return %0 : !torch.vtensor<[?],si64>
}

// -----
// CHECK-LABEL:   func @torch.aten.argmax(
// CHECK-SAME:      %[[INP:.*]]: !torch.vtensor<[?,?],f32>) -> !torch.vtensor<[1,?],si64> {
// CHECK:           %[[CST0:.*]] = torch.constant.int 0
// CHECK:           %[[TRUE:.*]] = torch.constant.bool true
// CHECK:           %[[VAL:.*]], %[[IND:.*]] = torch.aten.max.dim %[[INP]], %[[CST0]], %[[TRUE]] :
// CHECK-SAME:        !torch.vtensor<[?,?],f32>, !torch.int, !torch.bool -> !torch.vtensor<[1,?],f32>, !torch.vtensor<[1,?],si64>
// CHECK:           return %[[IND]] : !torch.vtensor<[1,?],si64>
func @torch.aten.argmax(%arg0: !torch.vtensor<[?,?],f32>) -> !torch.vtensor<[1,?],si64> {
  %int0 = torch.constant.int 0
  %true = torch.constant.bool true
  %0 = torch.aten.argmax %arg0, %int0, %true : !torch.vtensor<[?,?],f32>, !torch.int, !torch.bool -> !torch.vtensor<[1,?],si64>
  return %0 : !torch.vtensor<[1,?],si64>
}

// -----
// CHECK-LABEL:   func @torch.aten.argmax$reduceall(
// CHECK-SAME:      %[[INP:.*]]: !torch.vtensor<[?,?],f32>) -> !torch.vtensor<[],si64> {
// CHECK:           %[[NONE:.*]] = torch.constant.none
// CHECK:           %[[FALSE:.*]] = torch.constant.bool false
// CHECK:           %[[CST0:.*]] = torch.constant.int 0
// CHECK:           %[[CST1:.*]] = torch.constant.int 1
// CHECK:           %[[FLATTEN:.*]] = torch.aten.flatten.using_ints %[[INP]], %[[CST0]], %[[CST1]] :
// CHECK-SAME:         !torch.vtensor<[?,?],f32>, !torch.int, !torch.int -> !torch.vtensor<[?],f32>
// CHECK:           %[[VAL:.*]], %[[IND:.*]] = torch.aten.max.dim %[[FLATTEN]], %[[CST0]], %[[FALSE]] :
// CHECK-SAME:         !torch.vtensor<[?],f32>, !torch.int, !torch.bool -> !torch.vtensor<[],f32>, !torch.vtensor<[],si64>
// CHECK:           return %[[IND]] : !torch.vtensor<[],si64>
func @torch.aten.argmax$reduceall(%arg0: !torch.vtensor<[?,?],f32>) -> !torch.vtensor<[],si64> {
  %none = torch.constant.none
  %false = torch.constant.bool false
  %0 = torch.aten.argmax %arg0, %none, %false : !torch.vtensor<[?,?],f32>, !torch.none, !torch.bool -> !torch.vtensor<[],si64>
  return %0 : !torch.vtensor<[],si64>
}

// -----
// CHECK-LABEL:   func @torch.aten.square(
// CHECK-SAME:                            %[[INPUT:.*]]: !torch.vtensor<[?,?,?],f32>) -> !torch.vtensor<[?,?,?],f32> {
// CHECK:           %[[SQUARE:.*]] = torch.aten.mul.Tensor %[[INPUT]], %[[INPUT]] :
// CHECK-SAME:         !torch.vtensor<[?,?,?],f32>, !torch.vtensor<[?,?,?],f32> -> !torch.vtensor<[?,?,?],f32>
// CHECK:           return %[[SQUARE]] : !torch.vtensor<[?,?,?],f32>
func @torch.aten.square(%arg0: !torch.vtensor<[?,?,?],f32>) -> !torch.vtensor<[?,?,?],f32> {
  %0 = torch.aten.square %arg0 : !torch.vtensor<[?,?,?],f32> -> !torch.vtensor<[?,?,?],f32>
  return %0 : !torch.vtensor<[?,?,?],f32>
}

// -----
// CHECK-LABEL:   func @torch.aten.var$unbiased(
// CHECK-SAME:                                  %[[INPUT:.*]]: !torch.vtensor<[?,?,?],f32>) -> !torch.vtensor<[],f32> {
// CHECK:           %[[UNBIASED:.*]] = torch.constant.bool true
// CHECK:           %[[DTYPE:.*]] = torch.constant.none
// CHECK:           %[[SUM:.*]] = torch.aten.sum %[[INPUT]], %[[DTYPE]] : !torch.vtensor<[?,?,?],f32>, !torch.none -> !torch.vtensor<[],f32>
// CHECK:           %[[NUM_ELEMENTS:.*]] = torch.aten.numel %[[INPUT]] : !torch.vtensor<[?,?,?],f32> -> !torch.int
// CHECK:           %[[MEAN:.*]] = torch.aten.div.Scalar %[[SUM]], %[[NUM_ELEMENTS]] : !torch.vtensor<[],f32>, !torch.int -> !torch.vtensor<[],f32>
// CHECK:           %[[ALPHA:.*]] = torch.constant.float 1.000000e+00
// CHECK:           %[[SUB_MEAN:.*]] = torch.aten.sub.Tensor %[[INPUT]], %[[MEAN]], %[[ALPHA]] : !torch.vtensor<[?,?,?],f32>, !torch.vtensor<[],f32>, !torch.float -> !torch.vtensor<[?,?,?],f32>
// CHECK:           %[[SUB_MEAN_SQUARE:.*]] = torch.aten.mul.Tensor %[[SUB_MEAN]], %[[SUB_MEAN]] : !torch.vtensor<[?,?,?],f32>, !torch.vtensor<[?,?,?],f32> -> !torch.vtensor<[?,?,?],f32>
// CHECK:           %[[SUB_MEAN_SQUARE_SUM:.*]] = torch.aten.sum %[[SUB_MEAN_SQUARE]], %[[DTYPE]] : !torch.vtensor<[?,?,?],f32>, !torch.none -> !torch.vtensor<[],f32>
// CHECK:           %[[SUB_MEAN_SQUARE_NUM_ELEMENTS:.*]] = torch.aten.numel %[[SUB_MEAN_SQUARE]] : !torch.vtensor<[?,?,?],f32> -> !torch.int
// CHECK:           %[[CST1:.*]] = torch.constant.int 1
// CHECK:           %[[NUM_ELEMENTS_SUB1:.*]] = torch.aten.sub.int %[[SUB_MEAN_SQUARE_NUM_ELEMENTS]], %[[CST1]] : !torch.int, !torch.int -> !torch.int
// CHECK:           %[[UNBIASED_VAR:.*]] = torch.aten.div.Scalar %[[SUB_MEAN_SQUARE_SUM]], %[[NUM_ELEMENTS_SUB1]] : !torch.vtensor<[],f32>, !torch.int -> !torch.vtensor<[],f32>
// CHECK:           return %[[UNBIASED_VAR]] : !torch.vtensor<[],f32>
func @torch.aten.var$unbiased(%arg0: !torch.vtensor<[?,?,?],f32>) -> !torch.vtensor<[],f32> {
  %true = torch.constant.bool true
  %0 = torch.aten.var %arg0, %true: !torch.vtensor<[?,?,?],f32>, !torch.bool -> !torch.vtensor<[],f32>
  return %0 : !torch.vtensor<[],f32>
}

// -----
// CHECK-LABEL:   func @torch.aten.var$biased(
// CHECK-SAME:                         %[[INPUT:.*]]: !torch.vtensor<[?,?,?],f32>) -> !torch.vtensor<[],f32> {
// CHECK:           %[[UNBIASED:.*]] = torch.constant.bool false
// CHECK:           %[[DTYPE:.*]] = torch.constant.none
// CHECK:           %[[SUM:.*]] = torch.aten.sum %[[INPUT]], %[[DTYPE]] : !torch.vtensor<[?,?,?],f32>, !torch.none -> !torch.vtensor<[],f32>
// CHECK:           %[[NUM_ELEMENTS:.*]] = torch.aten.numel %[[INPUT]] : !torch.vtensor<[?,?,?],f32> -> !torch.int
// CHECK:           %[[MEAN:.*]] = torch.aten.div.Scalar %[[SUM]], %[[NUM_ELEMENTS]] : !torch.vtensor<[],f32>, !torch.int -> !torch.vtensor<[],f32>
// CHECK:           %[[ALPHA:.*]] = torch.constant.float 1.000000e+00
// CHECK:           %[[SUB_MEAN:.*]] = torch.aten.sub.Tensor %[[INPUT]], %[[MEAN]], %[[ALPHA]] : !torch.vtensor<[?,?,?],f32>, !torch.vtensor<[],f32>, !torch.float -> !torch.vtensor<[?,?,?],f32>
// CHECK:           %[[SUB_MEAN_SQUARE:.*]] = torch.aten.mul.Tensor %[[SUB_MEAN]], %[[SUB_MEAN]] : !torch.vtensor<[?,?,?],f32>, !torch.vtensor<[?,?,?],f32> -> !torch.vtensor<[?,?,?],f32>
// CHECK:           %[[SUB_MEAN_SQUARE_SUM:.*]] = torch.aten.sum %[[SUB_MEAN_SQUARE]], %[[DTYPE]] : !torch.vtensor<[?,?,?],f32>, !torch.none -> !torch.vtensor<[],f32>
// CHECK:           %[[SUB_MEAN_SQUARE_NUM_ELEMENTS:.*]] = torch.aten.numel %[[SUB_MEAN_SQUARE]] : !torch.vtensor<[?,?,?],f32> -> !torch.int
// CHECK:           %[[BIASED_VAR:.*]] = torch.aten.div.Scalar %[[SUB_MEAN_SQUARE_SUM]], %[[SUB_MEAN_SQUARE_NUM_ELEMENTS]] : !torch.vtensor<[],f32>, !torch.int -> !torch.vtensor<[],f32>
// CHECK:           return %[[BIASED_VAR]] : !torch.vtensor<[],f32>
func @torch.aten.var$biased(%arg0: !torch.vtensor<[?,?,?],f32>) -> !torch.vtensor<[],f32> {
  %false = torch.constant.bool false
  %0 = torch.aten.var %arg0, %false: !torch.vtensor<[?,?,?],f32>, !torch.bool -> !torch.vtensor<[],f32>
  return %0 : !torch.vtensor<[],f32>
}

// -----
// CHECK-LABEL:   func @torch.aten.std$unbiased(
// CHECK-SAME:                                  %[[INPUT:.*]]: !torch.vtensor<[?,?,?],f32>) -> !torch.vtensor<[],f32> {
// CHECK:           %[[UNBIASED:.*]] = torch.constant.bool true
// CHECK:           %[[DTYPE:.*]] = torch.constant.none
// CHECK:           %[[SUM:.*]] = torch.aten.sum %[[INPUT]], %[[DTYPE]] : !torch.vtensor<[?,?,?],f32>, !torch.none -> !torch.vtensor<[],f32>
// CHECK:           %[[NUM_ELEMENTS:.*]] = torch.aten.numel %[[INPUT]] : !torch.vtensor<[?,?,?],f32> -> !torch.int
// CHECK:           %[[MEAN:.*]] = torch.aten.div.Scalar %[[SUM]], %[[NUM_ELEMENTS]] : !torch.vtensor<[],f32>, !torch.int -> !torch.vtensor<[],f32>
// CHECK:           %[[ALPHA:.*]] = torch.constant.float 1.000000e+00
// CHECK:           %[[SUB_MEAN:.*]] = torch.aten.sub.Tensor %[[INPUT]], %[[MEAN]], %[[ALPHA]] : !torch.vtensor<[?,?,?],f32>, !torch.vtensor<[],f32>, !torch.float -> !torch.vtensor<[?,?,?],f32>
// CHECK:           %[[SUB_MEAN_SQUARE:.*]] = torch.aten.mul.Tensor %[[SUB_MEAN]], %[[SUB_MEAN]] : !torch.vtensor<[?,?,?],f32>, !torch.vtensor<[?,?,?],f32> -> !torch.vtensor<[?,?,?],f32>
// CHECK:           %[[SUB_MEAN_SQUARE_SUM:.*]] = torch.aten.sum %[[SUB_MEAN_SQUARE]], %[[DTYPE]] : !torch.vtensor<[?,?,?],f32>, !torch.none -> !torch.vtensor<[],f32>
// CHECK:           %[[SUB_MEAN_SQUARE_NUM_ELEMENTS:.*]] = torch.aten.numel %[[SUB_MEAN_SQUARE]] : !torch.vtensor<[?,?,?],f32> -> !torch.int
// CHECK:           %[[CST1:.*]] = torch.constant.int 1
// CHECK:           %[[NUM_ELEMENTS_SUB1:.*]] = torch.aten.sub.int %[[SUB_MEAN_SQUARE_NUM_ELEMENTS]], %[[CST1]] : !torch.int, !torch.int -> !torch.int
// CHECK:           %[[UNBIASED_VAR:.*]] = torch.aten.div.Scalar %[[SUB_MEAN_SQUARE_SUM]], %[[NUM_ELEMENTS_SUB1]] : !torch.vtensor<[],f32>, !torch.int -> !torch.vtensor<[],f32>
// CHECK:           %[[UNBIASED_STD:.*]] = torch.aten.sqrt %[[UNBIASED_VAR]] : !torch.vtensor<[],f32> -> !torch.vtensor<[],f32>
// CHECK:           return %[[UNBIASED_STD]] : !torch.vtensor<[],f32>
func @torch.aten.std$unbiased(%arg0: !torch.vtensor<[?,?,?],f32>) -> !torch.vtensor<[],f32> {
  %true = torch.constant.bool true
  %0 = torch.aten.std %arg0, %true: !torch.vtensor<[?,?,?],f32>, !torch.bool -> !torch.vtensor<[],f32>
  return %0 : !torch.vtensor<[],f32>
}

// -----
// CHECK-LABEL:   func @torch.aten.std$biased(
// CHECK-SAME:                         %[[INPUT:.*]]: !torch.vtensor<[?,?,?],f32>) -> !torch.vtensor<[],f32> {
// CHECK:           %[[UNBIASED:.*]] = torch.constant.bool false
// CHECK:           %[[DTYPE:.*]] = torch.constant.none
// CHECK:           %[[SUM:.*]] = torch.aten.sum %[[INPUT]], %[[DTYPE]] : !torch.vtensor<[?,?,?],f32>, !torch.none -> !torch.vtensor<[],f32>
// CHECK:           %[[NUM_ELEMENTS:.*]] = torch.aten.numel %[[INPUT]] : !torch.vtensor<[?,?,?],f32> -> !torch.int
// CHECK:           %[[MEAN:.*]] = torch.aten.div.Scalar %[[SUM]], %[[NUM_ELEMENTS]] : !torch.vtensor<[],f32>, !torch.int -> !torch.vtensor<[],f32>
// CHECK:           %[[ALPHA:.*]] = torch.constant.float 1.000000e+00
// CHECK:           %[[SUB_MEAN:.*]] = torch.aten.sub.Tensor %[[INPUT]], %[[MEAN]], %[[ALPHA]] : !torch.vtensor<[?,?,?],f32>, !torch.vtensor<[],f32>, !torch.float -> !torch.vtensor<[?,?,?],f32>
// CHECK:           %[[SUB_MEAN_SQUARE:.*]] = torch.aten.mul.Tensor %[[SUB_MEAN]], %[[SUB_MEAN]] : !torch.vtensor<[?,?,?],f32>, !torch.vtensor<[?,?,?],f32> -> !torch.vtensor<[?,?,?],f32>
// CHECK:           %[[SUB_MEAN_SQUARE_SUM:.*]] = torch.aten.sum %[[SUB_MEAN_SQUARE]], %[[DTYPE]] : !torch.vtensor<[?,?,?],f32>, !torch.none -> !torch.vtensor<[],f32>
// CHECK:           %[[SUB_MEAN_SQUARE_NUM_ELEMENTS:.*]] = torch.aten.numel %[[SUB_MEAN_SQUARE]] : !torch.vtensor<[?,?,?],f32> -> !torch.int
// CHECK:           %[[BIASED_VAR:.*]] = torch.aten.div.Scalar %[[SUB_MEAN_SQUARE_SUM]], %[[SUB_MEAN_SQUARE_NUM_ELEMENTS]] : !torch.vtensor<[],f32>, !torch.int -> !torch.vtensor<[],f32>
// CHECK:           %[[BIASED_STD:.*]] = torch.aten.sqrt %[[BIASED_VAR]] : !torch.vtensor<[],f32> -> !torch.vtensor<[],f32>
// CHECK:           return %[[BIASED_STD]] : !torch.vtensor<[],f32>
func @torch.aten.std$biased(%arg0: !torch.vtensor<[?,?,?],f32>) -> !torch.vtensor<[],f32> {
  %false = torch.constant.bool false
  %0 = torch.aten.std %arg0, %false: !torch.vtensor<[?,?,?],f32>, !torch.bool -> !torch.vtensor<[],f32>
  return %0 : !torch.vtensor<[],f32>
}

// -----
// CHECK-LABEL:   func @torch.aten._unsafe_view$static
// CHECK-SAME:      (%[[ARG0:.*]]: !torch.vtensor<[1,512,32],f32>)
// CHECK:           %[[LIST:.*]] = torch.prim.ListConstruct
// CHECK-NOT:       torch.aten._unsafe_view
// CHECK-NEXT:      %[[RES:.*]] = torch.aten.view %[[ARG0]], %[[LIST]]
// CHECK-NEXT:      return
func @torch.aten._unsafe_view$static(%arg0: !torch.vtensor<[1,512,32],f32>) -> !torch.vtensor<[1,2,256,32],f32> {
  %c1 = torch.constant.int 1
  %c2 = torch.constant.int 2
  %c256 = torch.constant.int 256
  %c32 = torch.constant.int 32
  %0 = torch.prim.ListConstruct %c1, %c2, %c256, %c32 : (!torch.int, !torch.int, !torch.int, !torch.int) -> !torch.list<!torch.int>
  %1 = torch.aten._unsafe_view %arg0, %0 : !torch.vtensor<[1,512,32],f32>, !torch.list<!torch.int> -> !torch.vtensor<[1,2,256,32],f32>
  return %1 : !torch.vtensor<[1,2,256,32],f32>
}

// -----
// CHECK-LABEL:   func @torch.aten._unsafe_view$dynamic
// CHECK-SAME:      (%[[ARG0:.*]]: !torch.vtensor<[?,?,?],f32>)
// CHECK:           %[[LIST:.*]] = torch.prim.ListConstruct
// CHECK-NOT:       torch.aten._unsafe_view
// CHECK-NEXT:      %[[RES:.*]] = torch.aten.view %[[ARG0]], %[[LIST]]
// CHECK-NEXT:      return
func @torch.aten._unsafe_view$dynamic(%arg0: !torch.vtensor<[?,?,?],f32>) -> !torch.vtensor<[512,32],f32> {
  %c256 = torch.constant.int 512
  %c32 = torch.constant.int 32
  %0 = torch.prim.ListConstruct %c256, %c32 : (!torch.int, !torch.int) -> !torch.list<!torch.int>
  %1 = torch.aten._unsafe_view %arg0, %0 : !torch.vtensor<[?,?,?],f32>, !torch.list<!torch.int> -> !torch.vtensor<[512,32],f32>
  return %1 : !torch.vtensor<[512,32],f32>
}

// -----
// CHECK-LABEL:   func @torch.aten._log_softmax(
// CHECK-SAME:               %[[INP:.*]]: !torch.vtensor<[?,?,?],f32>) -> !torch.vtensor<[?,?,?],f32> {
// CHECK:           %[[INT0:.*]] = torch.constant.int 0
// CHECK:           %[[FALSE:.*]] = torch.constant.bool false
// CHECK:           %[[TRUE:.*]] = torch.constant.bool true
// CHECK:           %[[VAL:.*]], %[[IND:.*]] = torch.aten.max.dim %[[INP]], %[[INT0]], %[[TRUE]] :
// CHECK-SAME:         !torch.vtensor<[?,?,?],f32>, !torch.int, !torch.bool -> !torch.vtensor<[1,?,?],f32>, !torch.vtensor<[1,?,?],si64>
// CHECK:           %[[FLOAT1:.*]] = torch.constant.float 1.000000e+00
// CHECK:           %[[SUB:.*]] = torch.aten.sub.Tensor %[[INP]], %[[VAL]], %[[FLOAT1]] : !torch.vtensor<[?,?,?],f32>, !torch.vtensor<[1,?,?],f32>, !torch.float -> !torch.vtensor<[?,?,?],f32>
// CHECK:           %[[EXP:.*]] = torch.aten.exp %[[SUB]] : !torch.vtensor<[?,?,?],f32> -> !torch.vtensor<[?,?,?],f32>
// CHECK:           %[[PRIM:.*]] = torch.prim.ListConstruct %[[INT0]] : (!torch.int) -> !torch.list<!torch.int>
// CHECK:           %[[TRU:.*]] = torch.constant.bool true
// CHECK:           %[[NONE:.*]] = torch.constant.none
// CHECK:           %[[SUM_DIM:.*]] = torch.aten.sum.dim_IntList %[[EXP]], %[[PRIM]], %[[TRU]], %[[NONE]] :
// CHECK-SAME:      !torch.vtensor<[?,?,?],f32>, !torch.list<!torch.int>, !torch.bool, !torch.none -> !torch.vtensor<[1,?,?],f32>
// CHECK:           %[[LOG:.*]] = torch.aten.log %[[SUM_DIM]] : !torch.vtensor<[1,?,?],f32> -> !torch.vtensor<[1,?,?],f32>
// CHECK:           %[[FLOAT_1:.*]] = torch.constant.float 1.000000e+00
// CHECK:           %[[SUB1:.*]] = torch.aten.sub.Tensor %[[SUB]], %[[LOG]], %[[FLOAT_1]] : !torch.vtensor<[?,?,?],f32>, 
// CHECK-SAME:      !torch.vtensor<[1,?,?],f32>, !torch.float -> !torch.vtensor<[?,?,?],f32>
// CHECK:           return %[[SUB1]] : !torch.vtensor<[?,?,?],f32>
func @torch.aten._log_softmax(%arg0: !torch.vtensor<[?,?,?],f32> loc(unknown)) -> !torch.vtensor<[?,?,?],f32> {
  %int0 = torch.constant.int 0
  %false = torch.constant.bool false
  %0 = torch.aten._log_softmax %arg0, %int0, %false : !torch.vtensor<[?,?,?],f32>, !torch.int, !torch.bool -> !torch.vtensor<[?,?,?],f32>
  return %0 : !torch.vtensor<[?,?,?],f32>
}

// -----
// CHECK-LABEL:   func @torch.aten.bernoulli
// CHECK-SAME:               (%[[INP:.*]]: !torch.vtensor<[?,?,?],f32>) -> !torch.vtensor {
// CHECK:           %[[NONE:.*]] = torch.constant.none
// CHECK:           %[[INT6:.*]] = torch.constant.int 6
// CHECK:           %[[FLOAT0_5:.*]] = torch.constant.float 5.000000e-01
// CHECK:           %[[FLOAT0:.*]] = torch.constant.float 0.000000e+00
// CHECK:           %[[FLOAT1:.*]] = torch.constant.float 1.000000e+00
// CHECK:           %[[FALSE:.*]] = torch.constant.bool false
// CHECK:           %[[NONE0:.*]] = torch.constant.none
// CHECK:           %[[UNF:.*]] = torch.pseudo.aten.uniform %[[INP]], %[[FLOAT0]], %[[FLOAT1]], %[[NONE0]] :
// CHECK-SAME:          !torch.vtensor<[?,?,?],f32>, !torch.float, !torch.float, !torch.none -> !torch.vtensor<[?,?,?],f32>
// CHECK:           %[[GT:.*]] = torch.aten.lt.Scalar %[[UNF]], %[[FLOAT0_5]] : !torch.vtensor<[?,?,?],f32>, !torch.float -> !torch.vtensor<[?,?,?],i1>
// CHECK:           %[[TODTYPE:.*]] = torch.aten.to.dtype %[[GT]], %[[INT6]], %[[FALSE]], %[[FALSE]], %[[NONE0]] :
// CHECK-SAME:        !torch.vtensor<[?,?,?],i1>, !torch.int, !torch.bool, !torch.bool, !torch.none -> !torch.vtensor<[?,?,?],f32>
// CHECK:           %[[CAST:.*]] = torch.tensor_static_info_cast %[[TODTYPE]] : !torch.vtensor<[?,?,?],f32> to !torch.vtensor
// CHECK:           return %[[CAST]] : !torch.vtensor
func @torch.aten.bernoulli(%arg0: !torch.vtensor<[?,?,?],f32>) -> !torch.vtensor {
    %none = torch.constant.none
    %0 = torch.aten.bernoulli %arg0, %none : !torch.vtensor<[?,?,?],f32>, !torch.none -> !torch.vtensor<[?,?,?],f32>
    %1 = torch.tensor_static_info_cast %0 : !torch.vtensor<[?,?,?],f32> to !torch.vtensor
    return %1 : !torch.vtensor
}

// -----
// CHECK-LABEL:   func @torch.aten.select.int(
// CHECK-SAME:                          %[[T:.*]]: !torch.vtensor<[?,?],si64>) -> !torch.vtensor<[?],si64> {
// CHECK:           %[[CST0:.*]] = torch.constant.int 0
// CHECK:           %[[CST1:.*]] = torch.constant.int 1
// CHECK:           %[[END:.*]] = torch.aten.add.int %[[CST0]], %[[CST1]] : !torch.int, !torch.int -> !torch.int
// CHECK:           %[[SLICE:.*]] = torch.aten.slice.Tensor %[[T]], %[[CST0]], %[[CST0]], %[[END]], %[[CST1]] :
// CHECK-SAME:        !torch.vtensor<[?,?],si64>, !torch.int, !torch.int, !torch.int, !torch.int -> !torch.vtensor<[1,?],si64>
// CHECK:           %[[SELECT:.*]] = torch.aten.squeeze.dim %[[SLICE]], %[[CST0]] :
// CHECK-SAME:        !torch.vtensor<[1,?],si64>, !torch.int -> !torch.vtensor<[?],si64>
// CHECK:           return %[[SELECT]] : !torch.vtensor<[?],si64>
func @torch.aten.select.int(%arg0: !torch.vtensor<[?,?],si64>) -> !torch.vtensor<[?],si64> {
  %int0 = torch.constant.int 0
  %0 = torch.aten.select.int %arg0, %int0, %int0 : !torch.vtensor<[?,?],si64>, !torch.int, !torch.int -> !torch.vtensor<[?],si64>
  return %0 : !torch.vtensor<[?],si64>
}

// -----
// CHECK-LABEL:   func @torch.aten.hardsigmoid(
// CHECK-SAME:               %[[ARG:.*]]: !torch.vtensor<[?,?],f32>) -> !torch.vtensor<[?,?],f32> {
// CHECK:           %[[INT1:.*]] = torch.constant.int 1
// CHECK:           %[[INT3:.*]] = torch.constant.int 3
// CHECK:           %[[INT6:.*]] = torch.constant.int 6
// CHECK:           %[[ADD3:.*]] = torch.aten.add.Scalar %[[ARG]], %[[INT3]], %[[INT1]] : !torch.vtensor<[?,?],f32>, !torch.int, !torch.int -> !torch.vtensor<[?,?],f32>
// CHECK:           %[[OUT:.*]] = torch.aten.div.Scalar %[[ADD3]], %[[INT6]] : !torch.vtensor<[?,?],f32>, !torch.int -> !torch.vtensor<[?,?],f32>
// CHECK:           %[[NONE:.*]] = torch.constant.none
// CHECK:           %[[IND0:.*]] = torch.constant.int 0
// CHECK:           %[[DIM0:.*]] = torch.aten.size.int %[[ARG]], %[[IND0]] : !torch.vtensor<[?,?],f32>, !torch.int -> !torch.int
// CHECK:           %[[IND1:.*]] = torch.constant.int 1
// CHECK:           %[[DIM1:.*]] = torch.aten.size.int %[[ARG]], %[[IND1]] : !torch.vtensor<[?,?],f32>, !torch.int -> !torch.int
// CHECK:           %[[SIZES:.*]] = torch.prim.ListConstruct %[[DIM0]], %[[DIM1]] : (!torch.int, !torch.int) -> !torch.list<!torch.int>
// CHECK:           %[[EMPTY:.*]] = torch.aten.empty.memory_format %[[SIZES]], %[[NONE]], %[[NONE]], %[[NONE]], %[[NONE]], %[[NONE]] : !torch.list<!torch.int>, !torch.none, !torch.none, !torch.none, !torch.none, !torch.none -> !torch.vtensor<[?,?],f32>
// CHECK:           %[[FILL0:.*]] = torch.constant.int 0
// CHECK:           %[[ZERO:.*]] = torch.pseudo.aten.fill.Scalar %[[EMPTY]], %[[FILL0]] : !torch.vtensor<[?,?],f32>, !torch.int -> !torch.vtensor<[?,?],f32>
// CHECK:           %[[IND0_2:.*]] = torch.constant.int 0
// CHECK:           %[[DIM0_2:.*]] = torch.aten.size.int %[[ARG]], %[[IND0_2]] : !torch.vtensor<[?,?],f32>, !torch.int -> !torch.int
// CHECK:           %[[IND1_2:.*]] = torch.constant.int 1
// CHECK:           %[[DIM1_2:.*]] = torch.aten.size.int %[[ARG]], %[[IND1_2]] : !torch.vtensor<[?,?],f32>, !torch.int -> !torch.int
// CHECK:           %[[SIZES_2:.*]] = torch.prim.ListConstruct %[[DIM0_2]], %[[DIM1_2]] : (!torch.int, !torch.int) -> !torch.list<!torch.int>
// CHECK:           %[[EMPTY_2:.*]] = torch.aten.empty.memory_format %[[SIZES_2]], %[[NONE]], %[[NONE]], %[[NONE]], %[[NONE]], %[[NONE]] : !torch.list<!torch.int>, !torch.none, !torch.none, !torch.none, !torch.none, !torch.none -> !torch.vtensor<[?,?],f32>
// CHECK:           %[[FILL1:.*]] = torch.constant.int 1
// CHECK:           %[[ONE:.*]] = torch.pseudo.aten.fill.Scalar %[[EMPTY_2]], %[[FILL1]] : !torch.vtensor<[?,?],f32>, !torch.int -> !torch.vtensor<[?,?],f32>
// CHECK:           %[[MIN:.*]] = torch.aten.minimum %[[ONE]], %[[OUT]] : !torch.vtensor<[?,?],f32>, !torch.vtensor<[?,?],f32> -> !torch.vtensor<[?,?],f32>
// CHECK:           %[[RES:.*]] = torch.aten.maximum %[[ZERO]], %[[MIN]] : !torch.vtensor<[?,?],f32>, !torch.vtensor<[?,?],f32> -> !torch.vtensor<[?,?],f32>
// CHECK:           return %[[RES]] : !torch.vtensor<[?,?],f32>
func @torch.aten.hardsigmoid(%arg0: !torch.vtensor<[?,?],f32>) -> !torch.vtensor<[?,?],f32> {
  %0 = torch.aten.hardsigmoid %arg0 : !torch.vtensor<[?,?],f32> -> !torch.vtensor<[?,?],f32>
  return %0 : !torch.vtensor<[?,?],f32>
}

// -----
// CHECK-LABEL:   func @torch.aten.batch_norm(
// CHECK-SAME:                                %[[INPUT:.*]]: !torch.vtensor<[?,?,?,?],f32>,
// CHECK-SAME:                                %[[WEIGHT:.*]]: !torch.vtensor<[?],f32>, %[[BIAS:.*]]: !torch.vtensor<[?],f32>, %[[RMEAN:.*]]: !torch.vtensor<[?],f32>, %[[RVAR:.*]]: !torch.vtensor<[?],f32>) -> !torch.vtensor<[?,?,?,?],f32> {
// CHECK:           %[[EPS:.*]] = torch.constant.float 1.000000e-05
// CHECK:           %[[MOM:.*]] = torch.constant.float 1.000000e-01
// CHECK:           %[[FALSE:.*]] = torch.constant.bool false
// CHECK:           %[[INT0:.*]] = torch.constant.int 0
// CHECK:           %[[INT1:.*]] = torch.constant.int 1
// CHECK:           %[[INPUT_DIM1:.*]] = torch.aten.size.int %[[INPUT]], %[[INT1]] : !torch.vtensor<[?,?,?,?],f32>, !torch.int -> !torch.int
// CHECK:           %[[RMEAN_DIM0:.*]] = torch.aten.size.int %[[RMEAN]], %[[INT0]] : !torch.vtensor<[?],f32>, !torch.int -> !torch.int
// CHECK:           %[[PRED_MEAN:.*]] = torch.aten.eq.int %[[RMEAN_DIM0]], %[[INPUT_DIM1]] : !torch.int, !torch.int -> !torch.bool
// CHECK:           torch.runtime.assert %[[PRED_MEAN]], "size of the 0th dimension must be equal to the number of features"
// CHECK:           %[[RVAR_DIM0:.*]] = torch.aten.size.int %[[RVAR]], %[[INT0]] : !torch.vtensor<[?],f32>, !torch.int -> !torch.int
// CHECK:           %[[PRED_VAR:.*]] = torch.aten.eq.int %[[RVAR_DIM0]], %[[INPUT_DIM1]] : !torch.int, !torch.int -> !torch.bool
// CHECK:           torch.runtime.assert %[[PRED_VAR]], "size of the 0th dimension must be equal to the number of features"
// CHECK:           %[[SIZE_LIST:.*]] = torch.prim.ListConstruct %[[INT1]], %[[INPUT_DIM1]], %[[INT1]], %[[INT1]] : (!torch.int, !torch.int, !torch.int, !torch.int) -> !torch.list<!torch.int>
// CHECK:           %[[RMEAN_VIEW:.*]] = torch.aten.view %[[RMEAN]], %[[SIZE_LIST]] : !torch.vtensor<[?],f32>, !torch.list<!torch.int> -> !torch.vtensor<[1,?,1,1],f32>
// CHECK:           %[[RVAR_VIEW:.*]] = torch.aten.view %[[RVAR]], %[[SIZE_LIST]] : !torch.vtensor<[?],f32>, !torch.list<!torch.int> -> !torch.vtensor<[1,?,1,1],f32>
// CHECK:           %[[X_SUB_MEAN:.*]] = torch.aten.sub.Tensor %[[INPUT]], %[[RMEAN_VIEW]], %[[INT1]] : !torch.vtensor<[?,?,?,?],f32>, !torch.vtensor<[1,?,1,1],f32>, !torch.int -> !torch.vtensor<[?,?,?,?],f32>
// CHECK:           %[[VAR_EPS:.*]] = torch.aten.add.Scalar %[[RVAR_VIEW]], %[[EPS]], %[[INT1]] : !torch.vtensor<[1,?,1,1],f32>, !torch.float, !torch.int -> !torch.vtensor<[1,?,1,1],f32>
// CHECK:           %[[SQRT_VAR_EPS:.*]] = torch.aten.rsqrt %[[VAR_EPS]] : !torch.vtensor<[1,?,1,1],f32> -> !torch.vtensor<[1,?,1,1],f32>
// CHECK:           %[[NORM_INPUT:.*]] = torch.aten.mul.Tensor %[[X_SUB_MEAN]], %[[SQRT_VAR_EPS]] : !torch.vtensor<[?,?,?,?],f32>, !torch.vtensor<[1,?,1,1],f32> -> !torch.vtensor<[?,?,?,?],f32>
// CHECK:           %[[WEIGHT_DIM0:.*]] = torch.aten.size.int %[[WEIGHT]], %[[INT0]] : !torch.vtensor<[?],f32>, !torch.int -> !torch.int
// CHECK:           %[[PRED_WEIGHT:.*]] = torch.aten.eq.int %[[WEIGHT_DIM0]], %[[INPUT_DIM1]] : !torch.int, !torch.int -> !torch.bool
// CHECK:           torch.runtime.assert %[[PRED_WEIGHT]], "size of the 0th dimension must be equal to the number of features"
// CHECK:           %[[WEIGHT_VIEW:.*]] = torch.aten.view %[[WEIGHT]], %[[SIZE_LIST]] : !torch.vtensor<[?],f32>, !torch.list<!torch.int> -> !torch.vtensor<[1,?,1,1],f32>
// CHECK:           %[[SCALED_INPUT:.*]] = torch.aten.mul.Tensor %[[NORM_INPUT]], %[[WEIGHT_VIEW]] : !torch.vtensor<[?,?,?,?],f32>, !torch.vtensor<[1,?,1,1],f32> -> !torch.vtensor<[?,?,?,?],f32>
// CHECK:           %[[BIAS_DIM0:.*]] = torch.aten.size.int %[[BIAS]], %[[INT0]] : !torch.vtensor<[?],f32>, !torch.int -> !torch.int
// CHECK:           %[[PRED_BIAS:.*]] = torch.aten.eq.int %[[BIAS_DIM0]], %[[INPUT_DIM1]] : !torch.int, !torch.int -> !torch.bool
// CHECK:           torch.runtime.assert %[[PRED_BIAS]], "size of the 0th dimension must be equal to the number of features"
// CHECK:           %[[BIAS_VIEW:.*]] = torch.aten.view %[[BIAS]], %[[SIZE_LIST]] : !torch.vtensor<[?],f32>, !torch.list<!torch.int> -> !torch.vtensor<[1,?,1,1],f32>
// CHECK:           %[[OUTPUT:.*]] = torch.aten.add.Tensor %[[SCALED_INPUT]], %[[BIAS_VIEW]], %[[INT1]] : !torch.vtensor<[?,?,?,?],f32>, !torch.vtensor<[1,?,1,1],f32>, !torch.int -> !torch.vtensor<[?,?,?,?],f32>
// CHECK:           %[[ZERO_LIST:.*]] = torch.prim.ListConstruct %[[INT0]] : (!torch.int) -> !torch.list<!torch.int>
// CHECK:           %[[NONE:.*]] = torch.constant.none
// CHECK:           %[[MEAN_OUT:.*]] = torch.aten.empty.memory_format %[[ZERO_LIST]], %[[NONE]], %[[NONE]], %[[NONE]], %[[NONE]], %[[NONE]] : !torch.list<!torch.int>, !torch.none, !torch.none, !torch.none, !torch.none, !torch.none -> !torch.vtensor<[0],f32>
// CHECK:           %[[INV_STD_OUT:.*]] = torch.aten.empty.memory_format %[[ZERO_LIST]], %[[NONE]], %[[NONE]], %[[NONE]], %[[NONE]], %[[NONE]] : !torch.list<!torch.int>, !torch.none, !torch.none, !torch.none, !torch.none, !torch.none -> !torch.vtensor<[0],f32>
// CHECK:           return %[[OUTPUT]] : !torch.vtensor<[?,?,?,?],f32>
func @torch.aten.batch_norm(%arg0: !torch.vtensor<[?,?,?,?],f32>, %arg1: !torch.vtensor<[?],f32>, %arg2: !torch.vtensor<[?],f32>, %arg3: !torch.vtensor<[?],f32>, %arg4: !torch.vtensor<[?],f32>) -> !torch.vtensor<[?,?,?,?],f32> {
  %float1.000000e-05 = torch.constant.float 1.000000e-05
  %float1.000000e-01 = torch.constant.float 1.000000e-01
  %false = torch.constant.bool false
  %0 = torch.aten.batch_norm %arg0, %arg1, %arg2, %arg3, %arg4, %false, %float1.000000e-01, %float1.000000e-05, %false : !torch.vtensor<[?,?,?,?],f32>, !torch.vtensor<[?],f32>, !torch.vtensor<[?],f32>, !torch.vtensor<[?],f32>, !torch.vtensor<[?],f32>, !torch.bool, !torch.float, !torch.float, !torch.bool -> !torch.vtensor<[?,?,?,?],f32>
  return %0 : !torch.vtensor<[?,?,?,?],f32>
}
