// RUN: torch-mlir-opt -split-input-file -allow-unregistered-dialect %s -torch-maximize-value-semantics | FileCheck %s

// CHECK-LABEL:   func @torch.copy.tensor$basic(
// CHECK-SAME:                                  %[[ARG0:.*]]: !torch.vtensor) -> (!torch.vtensor, !torch.vtensor) {
// CHECK:           return %[[ARG0]], %[[ARG0]] : !torch.vtensor, !torch.vtensor
func @torch.copy.tensor$basic(%arg0: !torch.vtensor) -> (!torch.vtensor, !torch.vtensor) {
  %0 = torch.copy.to_tensor %arg0 : !torch.tensor
  %1 = torch.copy.to_vtensor %0 : !torch.vtensor
  %2 = torch.copy.to_vtensor %0 : !torch.vtensor
  return %1, %2 : !torch.vtensor, !torch.vtensor
}

// CHECK-LABEL:   func @one_mutation_in_a_block(
// CHECK-SAME:                                  %[[ARG0:.*]]: !torch.vtensor,
// CHECK-SAME:                                  %[[ARG1:.*]]: !torch.vtensor) -> (!torch.vtensor, !torch.vtensor) {
// CHECK:           return %[[ARG0]], %[[ARG1]] : !torch.vtensor, !torch.vtensor
func @one_mutation_in_a_block(%arg0: !torch.vtensor, %arg1: !torch.vtensor) -> (!torch.vtensor, !torch.vtensor) {
  %0 = torch.copy.to_tensor %arg0 : !torch.tensor
  %equal_to_arg0 = torch.copy.to_vtensor %0 : !torch.vtensor
  torch.overwrite.tensor %arg1 overwrites %0 : !torch.vtensor, !torch.tensor
  %equal_to_arg1 = torch.copy.to_vtensor %0 : !torch.vtensor
  return %equal_to_arg0, %equal_to_arg1 : !torch.vtensor, !torch.vtensor
}

// CHECK-LABEL:   func @multiple_mutations_in_a_block(
// CHECK-SAME:                                        %[[ARG0:.*]]: !torch.vtensor, %[[ARG1:.*]]: !torch.vtensor,
// CHECK-SAME:                                        %[[ARG2:.*]]: !torch.vtensor) -> (!torch.vtensor, !torch.vtensor, !torch.vtensor, !torch.vtensor) {
// CHECK:           return %[[ARG0]], %[[ARG1]], %[[ARG1]], %[[ARG2]] : !torch.vtensor, !torch.vtensor, !torch.vtensor, !torch.vtensor
func @multiple_mutations_in_a_block(%arg0: !torch.vtensor, %arg1: !torch.vtensor, %arg2: !torch.vtensor) -> (!torch.vtensor, !torch.vtensor, !torch.vtensor, !torch.vtensor) {
  // The mutable tensor we are overwriting.
  %tensor = torch.copy.to_tensor %arg0 : !torch.tensor

  // The original value.
  %equal_to_arg0 = torch.copy.to_vtensor %tensor : !torch.vtensor

  // Overwrite with %arg1
  torch.overwrite.tensor %arg1 overwrites %tensor : !torch.vtensor, !torch.tensor
  %equal_to_arg1 = torch.copy.to_vtensor %tensor : !torch.vtensor
  %equal_to_arg1_again = torch.copy.to_vtensor %tensor : !torch.vtensor

  // Overwrite with %arg2
  torch.overwrite.tensor %arg2 overwrites %tensor : !torch.vtensor, !torch.tensor
  %equal_to_arg2 = torch.copy.to_vtensor %tensor : !torch.vtensor

  return %equal_to_arg0, %equal_to_arg1, %equal_to_arg1_again, %equal_to_arg2 : !torch.vtensor, !torch.vtensor, !torch.vtensor, !torch.vtensor
}

// CHECK-LABEL:   func @unmodeled_mutation(
// CHECK:           torch.overwrite.tensor
func @unmodeled_mutation(%arg0: !torch.vtensor, %arg1: !torch.vtensor) -> !torch.vtensor {
  %0 = torch.copy.to_tensor %arg0 : !torch.tensor
  torch.overwrite.tensor %arg1 overwrites %0 : !torch.vtensor, !torch.tensor
  "some.op"(%0) : (!torch.tensor) -> ()
  %result = torch.copy.to_vtensor %0 : !torch.vtensor
  return %result : !torch.vtensor
}

// CHECK-LABEL:   func @mutation_with_tensor_of_different_type(
// CHECK-SAME:                                                 %[[T_0:.*]]: !torch.vtensor<[2],f32>,
// CHECK-SAME:                                                 %[[T_1:.*]]: !torch.vtensor<[?],f32>) -> !torch.vtensor<[2],f32> {
// CHECK:           %[[ONE:.*]] = torch.constant.int 1
// CHECK:           %[[ADD:.*]] = torch.aten.add.Tensor %[[T_0]], %[[T_1]], %[[ONE]] : !torch.vtensor<[2],f32>, !torch.vtensor<[?],f32>, !torch.int -> !torch.vtensor<[?],f32>
// CHECK:           %[[STATIC_CAST:.*]] = torch.tensor_static_info_cast %[[ADD]] : !torch.vtensor<[?],f32> to !torch.vtensor<[2],f32>
// CHECK:           return %[[STATIC_CAST]] : !torch.vtensor<[2],f32>
func @mutation_with_tensor_of_different_type(%t0: !torch.vtensor<[2],f32>, %t1: !torch.vtensor<[?],f32>) -> !torch.vtensor<[2],f32> {
  %one = torch.constant.int 1
  %t0_copy = torch.copy.to_tensor %t0 : !torch.tensor<[2],f32>
  %add = torch.aten.add.Tensor %t0, %t1, %one : !torch.vtensor<[2],f32>, !torch.vtensor<[?],f32>, !torch.int -> !torch.vtensor<[?],f32>
  torch.overwrite.tensor %add overwrites %t0_copy : !torch.vtensor<[?],f32>, !torch.tensor<[2],f32>
  %t0_value_copy = torch.copy.to_vtensor %t0_copy : !torch.vtensor<[2],f32>
  return %t0_value_copy : !torch.vtensor<[2],f32>
}

// We don't yet handle nontrivial cases involving control flow.
// CHECK-LABEL:   func @unimplemented_control_flow(
// CHECK:           torch.copy.to_vtensor
func @unimplemented_control_flow(%arg0: !torch.vtensor, %arg1: !torch.vtensor, %cond: !torch.bool) -> (!torch.vtensor, !torch.vtensor) {
  %tensor = torch.copy.to_tensor %arg0 : !torch.tensor
  %equal_to_arg0 = torch.copy.to_vtensor %tensor : !torch.vtensor
  torch.prim.If %cond -> () {
    torch.overwrite.tensor %arg1 overwrites %tensor : !torch.vtensor, !torch.tensor
    torch.prim.If.yield
  } else {
    torch.prim.If.yield
  }
  %equal_to_arg1 = torch.copy.to_vtensor %tensor : !torch.vtensor
  return %equal_to_arg0, %equal_to_arg1 : !torch.vtensor, !torch.vtensor
}

// CHECK-LABEL:   func @viewlike$basic_unsqueeze(
// CHECK-SAME:                                   %[[ARG:.*]]: !torch.vtensor) -> !torch.vtensor {
// CHECK:           %[[INT0:.*]] = torch.constant.int 0
// CHECK:           %[[UNSQUEEZE:.*]] = torch.aten.unsqueeze %[[ARG]], %[[INT0]] : !torch.vtensor, !torch.int -> !torch.vtensor
// CHECK:           return %[[UNSQUEEZE]] : !torch.vtensor
func @viewlike$basic_unsqueeze(%arg0: !torch.vtensor) -> !torch.vtensor {
  %int0 = torch.constant.int 0
  %0 = torch.copy.to_tensor %arg0 : !torch.tensor
  %1 = torch.aten.unsqueeze %0, %int0 : !torch.tensor, !torch.int -> !torch.tensor
  %2 = torch.copy.to_vtensor %1 : !torch.vtensor
  return %2 : !torch.vtensor
}

// CHECK-LABEL:   func @viewlike$basic_flatten(
// CHECK-SAME:                                 %[[ARG:.*]]: !torch.vtensor) -> !torch.vtensor {
// CHECK:           %[[INT0:.*]] = torch.constant.int 0
// CHECK:           %[[INTM1:.*]] = torch.constant.int -1
// CHECK:           %[[FLATTEN:.*]] = torch.aten.flatten.using_ints %[[ARG]], %[[INT0]], %[[INTM1]] : !torch.vtensor, !torch.int, !torch.int -> !torch.vtensor
// CHECK:           return %[[FLATTEN]] : !torch.vtensor
func @viewlike$basic_flatten(%arg0: !torch.vtensor) -> !torch.vtensor {
  %start = torch.constant.int 0
  %end = torch.constant.int -1
  %0 = torch.copy.to_tensor %arg0 : !torch.tensor
  %1 = torch.aten.flatten.using_ints %0, %start, %end : !torch.tensor, !torch.int, !torch.int -> !torch.tensor
  %2 = torch.copy.to_vtensor %1 : !torch.vtensor
  return %2 : !torch.vtensor
}

// CHECK-LABEL:   func @viewlike$transitive(
// CHECK-SAME:                              %[[ARG:.*]]: !torch.vtensor) -> !torch.vtensor {
// CHECK:           %[[INT0:.*]] = torch.constant.int 0
// CHECK:           %[[UNSQUEEZE0:.*]] = torch.aten.unsqueeze %[[ARG]], %[[INT0]] : !torch.vtensor, !torch.int -> !torch.vtensor
// CHECK:           %[[UNSQUEEZE1:.*]] = torch.aten.unsqueeze %[[UNSQUEEZE0]], %[[INT0]] : !torch.vtensor, !torch.int -> !torch.vtensor
// CHECK:           return %[[UNSQUEEZE1]] : !torch.vtensor
func @viewlike$transitive(%arg0: !torch.vtensor) -> !torch.vtensor {
  %int0 = torch.constant.int 0
  %0 = torch.copy.to_tensor %arg0 : !torch.tensor
  %1 = torch.aten.unsqueeze %0, %int0 : !torch.tensor, !torch.int -> !torch.tensor
  %2 = torch.aten.unsqueeze %1, %int0 : !torch.tensor, !torch.int -> !torch.tensor
  %3 = torch.copy.to_vtensor %2 : !torch.vtensor
  return %3 : !torch.vtensor
}

// CHECK-LABEL:   func @viewlike$transitive_tree(
// CHECK-SAME:                                   %[[ARG:.*]]: !torch.vtensor) -> (!torch.vtensor, !torch.vtensor) {
// CHECK:           %[[INT0:.*]] = torch.constant.int 0
// CHECK:           %[[UNSQUEEZE0:.*]] = torch.aten.unsqueeze %[[ARG]], %[[INT0]] : !torch.vtensor, !torch.int -> !torch.vtensor
// CHECK:           %[[RET0:.*]] = torch.aten.unsqueeze %[[UNSQUEEZE0]], %[[INT0]] : !torch.vtensor, !torch.int -> !torch.vtensor
// CHECK:           %[[RET1:.*]] = torch.aten.unsqueeze %[[UNSQUEEZE0]], %[[INT0]] : !torch.vtensor, !torch.int -> !torch.vtensor
// CHECK:           return %[[RET0]], %[[RET1]] : !torch.vtensor, !torch.vtensor
func @viewlike$transitive_tree(%arg0: !torch.vtensor) -> (!torch.vtensor, !torch.vtensor) {
  %int0 = torch.constant.int 0
  %0 = torch.copy.to_tensor %arg0 : !torch.tensor
  // %1 has two users.
  %1 = torch.aten.unsqueeze %0, %int0 : !torch.tensor, !torch.int -> !torch.tensor

  %2 = torch.aten.unsqueeze %1, %int0 : !torch.tensor, !torch.int -> !torch.tensor
  %3 = torch.copy.to_vtensor %2 : !torch.vtensor

  %4 = torch.aten.unsqueeze %1, %int0 : !torch.tensor, !torch.int -> !torch.tensor
  %5 = torch.copy.to_vtensor %4 : !torch.vtensor

  return %3, %5 : !torch.vtensor, !torch.vtensor
}

// CHECK-LABEL:   func @viewlike$unmodeled_op(
// CHECK-SAME:                                %[[ARG:.*]]: !torch.vtensor) -> !torch.vtensor {
// CHECK:           %[[UNSQUEEZE:.*]] = torch.aten.unsqueeze {{.*}} : !torch.tensor, !torch.int -> !torch.tensor
// CHECK:           "some.op"(%[[UNSQUEEZE]]) : (!torch.tensor) -> ()
func @viewlike$unmodeled_op(%arg0: !torch.vtensor) -> !torch.vtensor {
  %int0 = torch.constant.int 0
  %0 = torch.copy.to_tensor %arg0 : !torch.tensor
  %1 = torch.aten.unsqueeze %0, %int0 : !torch.tensor, !torch.int -> !torch.tensor
  "some.op"(%1) : (!torch.tensor) -> ()
  %2 = torch.copy.to_vtensor %1 : !torch.vtensor
  return %2 : !torch.vtensor
}
