; ModuleID = 'bpftrace'
source_filename = "bpftrace"
target datalayout = "e-m:e-p:64:64-i64:64-i128:128-n32:64-S128"
target triple = "bpf-pc-linux"

%"struct map_t" = type { ptr, ptr }
%"struct map_t.0" = type { ptr, ptr, ptr, ptr }
%exit_t = type <{ i64, i8 }>

@LICENSE = global [4 x i8] c"GPL\00", section "license"
@ringbuf = dso_local global %"struct map_t" zeroinitializer, section ".maps", !dbg !0
@event_loss_counter = dso_local global %"struct map_t.0" zeroinitializer, section ".maps", !dbg !16

; Function Attrs: nounwind
declare i64 @llvm.bpf.pseudo(i64 %0, i64 %1) #0

define i64 @kprobe_f_1(ptr %0) section "s_kprobe_f_1" !dbg !39 {
entry:
  %key = alloca i32, align 4
  %exit = alloca %exit_t, align 8
  %n = alloca i32, align 4
  %i = alloca i32, align 4
  %arraycmp.result = alloca i1, align 1
  %v2 = alloca i32, align 4
  %v1 = alloca i32, align 4
  %"$b" = alloca i64, align 8
  call void @llvm.lifetime.start.p0(i64 -1, ptr %"$b")
  store i64 0, ptr %"$b", align 8
  %"$a" = alloca i64, align 8
  call void @llvm.lifetime.start.p0(i64 -1, ptr %"$a")
  store i64 0, ptr %"$a", align 8
  %1 = call ptr @llvm.preserve.static.offset(ptr %0)
  %2 = getelementptr i64, ptr %1, i64 14
  %arg0 = load volatile i64, ptr %2, align 8
  %3 = inttoptr i64 %arg0 to ptr
  %4 = call ptr @llvm.preserve.static.offset(ptr %3)
  %5 = getelementptr i8, ptr %4, i64 0
  %6 = ptrtoint ptr %5 to i64
  store i64 %6, ptr %"$a", align 8
  %7 = call ptr @llvm.preserve.static.offset(ptr %0)
  %8 = getelementptr i64, ptr %7, i64 14
  %arg01 = load volatile i64, ptr %8, align 8
  %9 = inttoptr i64 %arg01 to ptr
  %10 = call ptr @llvm.preserve.static.offset(ptr %9)
  %11 = getelementptr i8, ptr %10, i64 0
  %12 = ptrtoint ptr %11 to i64
  store i64 %12, ptr %"$b", align 8
  %13 = load i64, ptr %"$a", align 8
  %14 = load i64, ptr %"$b", align 8
  call void @llvm.lifetime.start.p0(i64 -1, ptr %v1)
  call void @llvm.lifetime.start.p0(i64 -1, ptr %v2)
  call void @llvm.lifetime.start.p0(i64 -1, ptr %arraycmp.result)
  store i1 true, ptr %arraycmp.result, align 1
  %15 = inttoptr i64 %13 to ptr
  %16 = inttoptr i64 %14 to ptr
  call void @llvm.lifetime.start.p0(i64 -1, ptr %i)
  call void @llvm.lifetime.start.p0(i64 -1, ptr %n)
  store i32 0, ptr %i, align 4
  store i32 4, ptr %n, align 4
  br label %while_cond

if_body:                                          ; preds = %arraycmp.done
  call void @llvm.lifetime.start.p0(i64 -1, ptr %exit)
  %17 = getelementptr %exit_t, ptr %exit, i64 0, i32 0
  store i64 30000, ptr %17, align 8
  %18 = getelementptr %exit_t, ptr %exit, i64 0, i32 1
  store i8 0, ptr %18, align 1
  %ringbuf_output = call i64 inttoptr (i64 130 to ptr)(ptr @ringbuf, ptr %exit, i64 9, i64 0)
  %ringbuf_loss = icmp slt i64 %ringbuf_output, 0
  br i1 %ringbuf_loss, label %event_loss_counter, label %counter_merge

if_end:                                           ; preds = %deadcode, %arraycmp.done
  ret i64 0

while_cond:                                       ; preds = %arraycmp.loop, %entry
  %19 = load i32, ptr %n, align 4
  %20 = load i32, ptr %i, align 4
  %size_check = icmp slt i32 %20, %19
  br i1 %size_check, label %while_body, label %arraycmp.done, !llvm.loop !46

while_body:                                       ; preds = %while_cond
  %21 = load i32, ptr %i, align 4
  %22 = getelementptr [4 x i32], ptr %15, i32 0, i32 %21
  %probe_read_kernel = call i64 inttoptr (i64 113 to ptr)(ptr %v1, i32 4, ptr %22)
  %23 = load i32, ptr %v1, align 4
  %24 = load i32, ptr %i, align 4
  %25 = getelementptr [4 x i32], ptr %16, i32 0, i32 %24
  %probe_read_kernel2 = call i64 inttoptr (i64 113 to ptr)(ptr %v2, i32 4, ptr %25)
  %26 = load i32, ptr %v2, align 4
  %arraycmp.cmp = icmp ne i32 %23, %26
  br i1 %arraycmp.cmp, label %arraycmp.false, label %arraycmp.loop

arraycmp.false:                                   ; preds = %while_body
  store i1 false, ptr %arraycmp.result, align 1
  br label %arraycmp.done

arraycmp.done:                                    ; preds = %arraycmp.false, %while_cond
  %27 = load i1, ptr %arraycmp.result, align 1
  call void @llvm.lifetime.end.p0(i64 -1, ptr %arraycmp.result)
  call void @llvm.lifetime.end.p0(i64 -1, ptr %v1)
  call void @llvm.lifetime.end.p0(i64 -1, ptr %v2)
  %28 = zext i1 %27 to i64
  %true_cond = icmp ne i64 %28, 0
  br i1 %true_cond, label %if_body, label %if_end

arraycmp.loop:                                    ; preds = %while_body
  %29 = load i32, ptr %i, align 4
  %30 = add i32 %29, 1
  store i32 %30, ptr %i, align 4
  br label %while_cond

event_loss_counter:                               ; preds = %if_body
  call void @llvm.lifetime.start.p0(i64 -1, ptr %key)
  store i32 0, ptr %key, align 4
  %lookup_elem = call ptr inttoptr (i64 1 to ptr)(ptr @event_loss_counter, ptr %key)
  %map_lookup_cond = icmp ne ptr %lookup_elem, null
  br i1 %map_lookup_cond, label %lookup_success, label %lookup_failure

counter_merge:                                    ; preds = %lookup_merge, %if_body
  call void @llvm.lifetime.end.p0(i64 -1, ptr %exit)
  ret i64 0

lookup_success:                                   ; preds = %event_loss_counter
  %31 = atomicrmw add ptr %lookup_elem, i64 1 seq_cst, align 8
  br label %lookup_merge

lookup_failure:                                   ; preds = %event_loss_counter
  br label %lookup_merge

lookup_merge:                                     ; preds = %lookup_failure, %lookup_success
  call void @llvm.lifetime.end.p0(i64 -1, ptr %key)
  br label %counter_merge

deadcode:                                         ; No predecessors!
  br label %if_end
}

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare ptr @llvm.preserve.static.offset(ptr readnone %0) #1

; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg %0, ptr nocapture %1) #2

; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg %0, ptr nocapture %1) #2

attributes #0 = { nounwind }
attributes #1 = { nocallback nofree nosync nounwind speculatable willreturn memory(none) }
attributes #2 = { nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }

!llvm.dbg.cu = !{!36}
!llvm.module.flags = !{!38}

!0 = !DIGlobalVariableExpression(var: !1, expr: !DIExpression())
!1 = distinct !DIGlobalVariable(name: "ringbuf", linkageName: "global", scope: !2, file: !2, type: !3, isLocal: false, isDefinition: true)
!2 = !DIFile(filename: "bpftrace.bpf.o", directory: ".")
!3 = !DICompositeType(tag: DW_TAG_structure_type, scope: !2, file: !2, size: 128, elements: !4)
!4 = !{!5, !11}
!5 = !DIDerivedType(tag: DW_TAG_member, name: "type", scope: !2, file: !2, baseType: !6, size: 64)
!6 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !7, size: 64)
!7 = !DICompositeType(tag: DW_TAG_array_type, baseType: !8, size: 864, elements: !9)
!8 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!9 = !{!10}
!10 = !DISubrange(count: 27, lowerBound: 0)
!11 = !DIDerivedType(tag: DW_TAG_member, name: "max_entries", scope: !2, file: !2, baseType: !12, size: 64, offset: 64)
!12 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !13, size: 64)
!13 = !DICompositeType(tag: DW_TAG_array_type, baseType: !8, size: 8388608, elements: !14)
!14 = !{!15}
!15 = !DISubrange(count: 262144, lowerBound: 0)
!16 = !DIGlobalVariableExpression(var: !17, expr: !DIExpression())
!17 = distinct !DIGlobalVariable(name: "event_loss_counter", linkageName: "global", scope: !2, file: !2, type: !18, isLocal: false, isDefinition: true)
!18 = !DICompositeType(tag: DW_TAG_structure_type, scope: !2, file: !2, size: 256, elements: !19)
!19 = !{!20, !25, !30, !33}
!20 = !DIDerivedType(tag: DW_TAG_member, name: "type", scope: !2, file: !2, baseType: !21, size: 64)
!21 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !22, size: 64)
!22 = !DICompositeType(tag: DW_TAG_array_type, baseType: !8, size: 64, elements: !23)
!23 = !{!24}
!24 = !DISubrange(count: 2, lowerBound: 0)
!25 = !DIDerivedType(tag: DW_TAG_member, name: "max_entries", scope: !2, file: !2, baseType: !26, size: 64, offset: 64)
!26 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !27, size: 64)
!27 = !DICompositeType(tag: DW_TAG_array_type, baseType: !8, size: 32, elements: !28)
!28 = !{!29}
!29 = !DISubrange(count: 1, lowerBound: 0)
!30 = !DIDerivedType(tag: DW_TAG_member, name: "key", scope: !2, file: !2, baseType: !31, size: 64, offset: 128)
!31 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !32, size: 64)
!32 = !DIBasicType(name: "int32", size: 32, encoding: DW_ATE_signed)
!33 = !DIDerivedType(tag: DW_TAG_member, name: "value", scope: !2, file: !2, baseType: !34, size: 64, offset: 192)
!34 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !35, size: 64)
!35 = !DIBasicType(name: "int64", size: 64, encoding: DW_ATE_signed)
!36 = distinct !DICompileUnit(language: DW_LANG_C, file: !2, producer: "bpftrace", isOptimized: false, runtimeVersion: 0, emissionKind: LineTablesOnly, globals: !37)
!37 = !{!0, !16}
!38 = !{i32 2, !"Debug Info Version", i32 3}
!39 = distinct !DISubprogram(name: "kprobe_f_1", linkageName: "kprobe_f_1", scope: !2, file: !2, type: !40, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition, unit: !36, retainedNodes: !44)
!40 = !DISubroutineType(types: !41)
!41 = !{!35, !42}
!42 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !43, size: 64)
!43 = !DIBasicType(name: "int8", size: 8, encoding: DW_ATE_signed)
!44 = !{!45}
!45 = !DILocalVariable(name: "ctx", arg: 1, scope: !39, file: !2, type: !42)
!46 = distinct !{!46, !47}
!47 = !{!"llvm.loop.unroll.disable"}
