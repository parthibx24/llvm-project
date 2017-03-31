; RUN: llc -march=amdgcn -verify-machineinstrs < %s | FileCheck -check-prefix=GCN -check-prefix=SI %s
; RUN: llc -march=amdgcn -mcpu=fiji -mattr=-flat-for-global -verify-machineinstrs < %s | FileCheck -check-prefix=GCN -check-prefix=VI %s

; GCN-LABEL: {{^}}fadd_f16
; GCN: buffer_load_ushort v[[A_F16:[0-9]+]]
; GCN: buffer_load_ushort v[[B_F16:[0-9]+]]
; SI:  v_cvt_f32_f16_e32 v[[A_F32:[0-9]+]], v[[A_F16]]
; SI:  v_cvt_f32_f16_e32 v[[B_F32:[0-9]+]], v[[B_F16]]
; SI:  v_add_f32_e32 v[[R_F32:[0-9]+]], v[[B_F32]], v[[A_F32]]
; SI:  v_cvt_f16_f32_e32 v[[R_F16:[0-9]+]], v[[R_F32]]
; VI:  v_add_f16_e32 v[[R_F16:[0-9]+]], v[[B_F16]], v[[A_F16]]
; GCN: buffer_store_short v[[R_F16]]
; GCN: s_endpgm
define amdgpu_kernel void @fadd_f16(
    half addrspace(1)* %r,
    half addrspace(1)* %a,
    half addrspace(1)* %b) {
entry:
  %a.val = load half, half addrspace(1)* %a
  %b.val = load half, half addrspace(1)* %b
  %r.val = fadd half %a.val, %b.val
  store half %r.val, half addrspace(1)* %r
  ret void
}

; GCN-LABEL: {{^}}fadd_f16_imm_a
; GCN: buffer_load_ushort v[[B_F16:[0-9]+]]
; SI:  v_cvt_f32_f16_e32 v[[B_F32:[0-9]+]], v[[B_F16]]
; SI:  v_add_f32_e32 v[[R_F32:[0-9]+]], 1.0, v[[B_F32]]
; SI:  v_cvt_f16_f32_e32 v[[R_F16:[0-9]+]], v[[R_F32]]
; VI:  v_add_f16_e32 v[[R_F16:[0-9]+]], 1.0, v[[B_F16]]
; GCN: buffer_store_short v[[R_F16]]
; GCN: s_endpgm
define amdgpu_kernel void @fadd_f16_imm_a(
    half addrspace(1)* %r,
    half addrspace(1)* %b) {
entry:
  %b.val = load half, half addrspace(1)* %b
  %r.val = fadd half 1.0, %b.val
  store half %r.val, half addrspace(1)* %r
  ret void
}

; GCN-LABEL: {{^}}fadd_f16_imm_b
; GCN: buffer_load_ushort v[[A_F16:[0-9]+]]
; SI:  v_cvt_f32_f16_e32 v[[A_F32:[0-9]+]], v[[A_F16]]
; SI:  v_add_f32_e32 v[[R_F32:[0-9]+]], 2.0, v[[A_F32]]
; SI:  v_cvt_f16_f32_e32 v[[R_F16:[0-9]+]], v[[R_F32]]
; VI:  v_add_f16_e32 v[[R_F16:[0-9]+]], 2.0, v[[A_F16]]
; GCN: buffer_store_short v[[R_F16]]
; GCN: s_endpgm
define amdgpu_kernel void @fadd_f16_imm_b(
    half addrspace(1)* %r,
    half addrspace(1)* %a) {
entry:
  %a.val = load half, half addrspace(1)* %a
  %r.val = fadd half %a.val, 2.0
  store half %r.val, half addrspace(1)* %r
  ret void
}

; GCN-LABEL: {{^}}fadd_v2f16:
; GCN: buffer_load_dword v[[A_V2_F16:[0-9]+]]
; GCN: buffer_load_dword v[[B_V2_F16:[0-9]+]]

; SI:  v_cvt_f32_f16_e32 v[[A_F32_0:[0-9]+]], v[[A_V2_F16]]
; SI: v_lshrrev_b32_e32 v[[A_F16_1:[0-9]+]], 16, v[[A_V2_F16]]
; SI:  v_cvt_f32_f16_e32 v[[B_F32_0:[0-9]+]], v[[B_V2_F16]]
; SI: v_lshrrev_b32_e32 v[[B_F16_1:[0-9]+]], 16, v[[B_V2_F16]]

; SI-DAG:  v_cvt_f32_f16_e32 v[[A_F32_1:[0-9]+]], v[[A_F16_1]]
; SI-DAG:  v_cvt_f32_f16_e32 v[[B_F32_1:[0-9]+]], v[[B_F16_1]]
; SI:  v_add_f32_e32 v[[R_F32_0:[0-9]+]], v[[B_F32_0]], v[[A_F32_0]]
; SI:  v_add_f32_e32 v[[R_F32_1:[0-9]+]], v[[B_F32_1]], v[[A_F32_1]]
; SI-DAG:  v_cvt_f16_f32_e32 v[[R_F16_0:[0-9]+]], v[[R_F32_0]]
; SI-DAG:  v_cvt_f16_f32_e32 v[[R_F16_1:[0-9]+]], v[[R_F32_1]]

; VI-DAG: v_lshrrev_b32_e32 v[[A_F16_1:[0-9]+]], 16, v[[A_V2_F16]]
; VI-DAG: v_lshrrev_b32_e32 v[[B_F16_1:[0-9]+]], 16, v[[B_V2_F16]]
; VI-DAG:  v_add_f16_e32 v[[R_F16_0:[0-9]+]], v[[B_V2_F16]], v[[A_V2_F16]]
; VI-DAG:  v_add_f16_e32 v[[R_F16_1:[0-9]+]], v[[B_F16_1]], v[[A_F16_1]]
; GCN-DAG: v_lshlrev_b32_e32 v[[R_F16_HI:[0-9]+]], 16, v[[R_F16_1]]
; GCN: v_or_b32_e32 v[[R_V2_F16:[0-9]+]], v[[R_F16_HI]], v[[R_F16_0]]
; GCN: buffer_store_dword v[[R_V2_F16]]
; GCN: s_endpgm
define amdgpu_kernel void @fadd_v2f16(
    <2 x half> addrspace(1)* %r,
    <2 x half> addrspace(1)* %a,
    <2 x half> addrspace(1)* %b) {
entry:
  %a.val = load <2 x half>, <2 x half> addrspace(1)* %a
  %b.val = load <2 x half>, <2 x half> addrspace(1)* %b
  %r.val = fadd <2 x half> %a.val, %b.val
  store <2 x half> %r.val, <2 x half> addrspace(1)* %r
  ret void
}

; GCN-LABEL: {{^}}fadd_v2f16_imm_a:
; GCN: buffer_load_dword v[[B_V2_F16:[0-9]+]]
; SI:  v_cvt_f32_f16_e32 v[[B_F32_0:[0-9]+]], v[[B_V2_F16]]
; GCN: v_lshrrev_b32_e32 v[[B_F16_1:[0-9]+]], 16, v[[B_V2_F16]]
; SI:  v_cvt_f32_f16_e32 v[[B_F32_1:[0-9]+]], v[[B_F16_1]]
; SI:  v_add_f32_e32 v[[R_F32_0:[0-9]+]], 1.0, v[[B_F32_0]]
; SI:  v_cvt_f16_f32_e32 v[[R_F16_0:[0-9]+]], v[[R_F32_0]]
; SI:  v_add_f32_e32 v[[R_F32_1:[0-9]+]], 2.0, v[[B_F32_1]]
; SI:  v_cvt_f16_f32_e32 v[[R_F16_1:[0-9]+]], v[[R_F32_1]]

; VI-DAG:  v_add_f16_e32 v[[R_F16_0:[0-9]+]], 1.0, v[[B_V2_F16]]
; VI-DAG:  v_add_f16_e32 v[[R_F16_1:[0-9]+]], 2.0, v[[B_F16_1]]
; GCN-DAG: v_lshlrev_b32_e32 v[[R_F16_HI:[0-9]+]], 16, v[[R_F16_1]]
; GCN: v_or_b32_e32 v[[R_V2_F16:[0-9]+]], v[[R_F16_HI]], v[[R_F16_0]]
; GCN: buffer_store_dword v[[R_V2_F16]]
; GCN: s_endpgm
define amdgpu_kernel void @fadd_v2f16_imm_a(
    <2 x half> addrspace(1)* %r,
    <2 x half> addrspace(1)* %b) {
entry:
  %b.val = load <2 x half>, <2 x half> addrspace(1)* %b
  %r.val = fadd <2 x half> <half 1.0, half 2.0>, %b.val
  store <2 x half> %r.val, <2 x half> addrspace(1)* %r
  ret void
}

; GCN-LABEL: {{^}}fadd_v2f16_imm_b:
; GCN: buffer_load_dword v[[A_V2_F16:[0-9]+]]
; SI:  v_cvt_f32_f16_e32 v[[A_F32_0:[0-9]+]], v[[A_V2_F16]]
; GCN: v_lshrrev_b32_e32 v[[A_F16_1:[0-9]+]], 16, v[[A_V2_F16]]
; SI:  v_cvt_f32_f16_e32 v[[A_F32_1:[0-9]+]], v[[A_F16_1]]
; SI:  v_add_f32_e32 v[[R_F32_0:[0-9]+]], 2.0, v[[A_F32_0]]
; SI:  v_cvt_f16_f32_e32 v[[R_F16_0:[0-9]+]], v[[R_F32_0]]
; SI:  v_add_f32_e32 v[[R_F32_1:[0-9]+]], 1.0, v[[A_F32_1]]
; SI:  v_cvt_f16_f32_e32 v[[R_F16_1:[0-9]+]], v[[R_F32_1]]
; VI-DAG:  v_add_f16_e32 v[[R_F16_0:[0-9]+]], 2.0, v[[A_V2_F16]]
; VI-DAG:  v_add_f16_e32 v[[R_F16_1:[0-9]+]], 1.0, v[[A_F16_1]]
; GCN-DAG: v_lshlrev_b32_e32 v[[R_F16_HI:[0-9]+]], 16, v[[R_F16_1]]
; GCN: v_or_b32_e32 v[[R_V2_F16:[0-9]+]], v[[R_F16_HI]], v[[R_F16_0]]
; GCN: buffer_store_dword v[[R_V2_F16]]
; GCN: s_endpgm
define amdgpu_kernel void @fadd_v2f16_imm_b(
    <2 x half> addrspace(1)* %r,
    <2 x half> addrspace(1)* %a) {
entry:
  %a.val = load <2 x half>, <2 x half> addrspace(1)* %a
  %r.val = fadd <2 x half> %a.val, <half 2.0, half 1.0>
  store <2 x half> %r.val, <2 x half> addrspace(1)* %r
  ret void
}
