const std = @import("std");

const bx = @import("build_bx.zig");
const bimg = @import("build_bimg.zig");
const bgfx = @import("build_bgfx.zig");

pub fn build(b: *std.Build, target: std.Build.ResolvedTarget, build_mode: std.builtin.Mode) *std.Build.Step.Compile {
    // fcpp
    const fcpp_cxx_options = [_][]const u8{
        "-D__STDC_LIMIT_MACROS",
        "-D__STDC_FORMAT_MACROS",
        "-D__STDC_CONSTANT_MACROS",
        "-DNINCLUDE=64",
        "-DNWORK=65536",
        "-DNBUFF=65536",
        "-DOLD_PREPROCESSOR=0",
        "-fno-sanitize=undefined",
    };

    const fcpp_path = "3rdparty/bgfx/3rdparty/fcpp/";
    const fcpp_lib = b.addStaticLibrary(.{
        .name = "fcpp",
        .target = target,
        .optimize = build_mode,
    });

    const fcpp_lib_files = [_][]const u8{
        "cpp1.c",
        "cpp2.c",
        "cpp3.c",
        "cpp4.c",
        "cpp5.c",
        "cpp6.c",
    };

    fcpp_lib.addIncludePath(b.path(fcpp_path));
    fcpp_lib.addCSourceFiles(.{
        .root = b.path(fcpp_path),
        .files = &fcpp_lib_files,
        .flags = &fcpp_cxx_options,
    });

    fcpp_lib.want_lto = false;
    fcpp_lib.linkSystemLibrary("c++");

    const fcpp_lib_artifact = b.addInstallArtifact(fcpp_lib, .{});
    b.getInstallStep().dependOn(&fcpp_lib_artifact.step);

    //spirv-opt
    const spirv_opt_cxx_options = [_][]const u8{
        "-D__STDC_LIMIT_MACROS",
        "-D__STDC_FORMAT_MACROS",
        "-D__STDC_CONSTANT_MACROS",
        "-fno-sanitize=undefined",
    };

    const spirv_opt_path = "3rdparty/bgfx/3rdparty/spirv-tools/";
    const spirv_opt_lib = b.addStaticLibrary(.{ .name = "spirv-opt", .target = target, .optimize = build_mode });
    spirv_opt_lib.addIncludePath(b.path(spirv_opt_path));
    spirv_opt_lib.addIncludePath(b.path(spirv_opt_path ++ "include"));
    spirv_opt_lib.addIncludePath(b.path(spirv_opt_path ++ "include/generated"));
    spirv_opt_lib.addIncludePath(b.path(spirv_opt_path ++ "source"));
    spirv_opt_lib.addIncludePath(b.path("3rdparty/bgfx/3rdparty/spirv-headers/include"));

    spirv_opt_lib.addCSourceFiles(.{
        .root = b.path(spirv_opt_path),
        .files = &.{
            "source/assembly_grammar.cpp",
            "source/binary.cpp",
            "source/diagnostic.cpp",
            "source/disassemble.cpp",
            "source/enum_string_mapping.cpp",
            "source/ext_inst.cpp",
            "source/extensions.cpp",
            "source/libspirv.cpp",
            "source/name_mapper.cpp",
            "source/opcode.cpp",
            "source/operand.cpp",
            "source/opt/aggressive_dead_code_elim_pass.cpp",
            "source/opt/analyze_live_input_pass.cpp",
            "source/opt/amd_ext_to_khr.cpp",
            "source/opt/basic_block.cpp",
            "source/opt/block_merge_pass.cpp",
            "source/opt/block_merge_util.cpp",
            "source/opt/build_module.cpp",
            "source/opt/ccp_pass.cpp",
            "source/opt/cfg.cpp",
            "source/opt/cfg_cleanup_pass.cpp",
            "source/opt/code_sink.cpp",
            "source/opt/combine_access_chains.cpp",
            "source/opt/compact_ids_pass.cpp",
            "source/opt/composite.cpp",
            "source/opt/const_folding_rules.cpp",
            "source/opt/constants.cpp",
            "source/opt/convert_to_half_pass.cpp",
            "source/opt/convert_to_sampled_image_pass.cpp",
            "source/opt/copy_prop_arrays.cpp",
            "source/opt/dead_branch_elim_pass.cpp",
            "source/opt/dead_insert_elim_pass.cpp",
            "source/opt/dead_variable_elimination.cpp",
            "source/opt/debug_info_manager.cpp",
            "source/opt/decoration_manager.cpp",
            "source/opt/def_use_manager.cpp",
            "source/opt/desc_sroa.cpp",
            "source/opt/desc_sroa_util.cpp",
            "source/opt/dominator_analysis.cpp",
            "source/opt/dominator_tree.cpp",
            "source/opt/eliminate_dead_constant_pass.cpp",
            "source/opt/eliminate_dead_functions_pass.cpp",
            "source/opt/eliminate_dead_functions_util.cpp",
            "source/opt/eliminate_dead_io_components_pass.cpp",
            "source/opt/eliminate_dead_members_pass.cpp",
            "source/opt/eliminate_dead_output_stores_pass.cpp",
            "source/opt/feature_manager.cpp",
            "source/opt/fix_func_call_arguments.cpp",
            "source/opt/fix_storage_class.cpp",
            "source/opt/flatten_decoration_pass.cpp",
            "source/opt/fold.cpp",
            "source/opt/fold_spec_constant_op_and_composite_pass.cpp",
            "source/opt/folding_rules.cpp",
            "source/opt/freeze_spec_constant_value_pass.cpp",
            "source/opt/function.cpp",
            "source/opt/graphics_robust_access_pass.cpp",
            "source/opt/if_conversion.cpp",
            "source/opt/inline_exhaustive_pass.cpp",
            "source/opt/inline_opaque_pass.cpp",
            "source/opt/inline_pass.cpp",
            "source/opt/inst_bindless_check_pass.cpp",
            "source/opt/inst_buff_addr_check_pass.cpp",
            "source/opt/inst_debug_printf_pass.cpp",
            "source/opt/instruction.cpp",
            "source/opt/instruction_list.cpp",
            "source/opt/instrument_pass.cpp",
            "source/opt/interface_var_sroa.cpp",
            "source/opt/ir_context.cpp",
            "source/opt/ir_loader.cpp",
            "source/opt/licm_pass.cpp",
            "source/opt/liveness.cpp",
            "source/opt/local_access_chain_convert_pass.cpp",
            "source/opt/local_redundancy_elimination.cpp",
            "source/opt/local_single_block_elim_pass.cpp",
            "source/opt/local_single_store_elim_pass.cpp",
            "source/opt/loop_dependence.cpp",
            "source/opt/loop_dependence_helpers.cpp",
            "source/opt/loop_descriptor.cpp",
            "source/opt/loop_fission.cpp",
            "source/opt/loop_fusion.cpp",
            "source/opt/loop_fusion_pass.cpp",
            "source/opt/loop_peeling.cpp",
            "source/opt/loop_unroller.cpp",
            "source/opt/loop_unswitch_pass.cpp",
            "source/opt/loop_utils.cpp",
            "source/opt/interp_fixup_pass.cpp",
            "source/opt/mem_pass.cpp",
            "source/opt/merge_return_pass.cpp",
            "source/opt/module.cpp",
            "source/opt/optimizer.cpp",
            "source/opt/pass.cpp",
            "source/opt/pass_manager.cpp",
            "source/opt/pch_source_opt.cpp",
            "source/opt/private_to_local_pass.cpp",
            "source/opt/propagator.cpp",
            "source/opt/reduce_load_size.cpp",
            "source/opt/redundancy_elimination.cpp",
            "source/opt/remove_dontinline_pass.cpp",
            "source/opt/remove_unused_interface_variables_pass.cpp",
            "source/opt/register_pressure.cpp",
            "source/opt/relax_float_ops_pass.cpp",
            "source/opt/remove_duplicates_pass.cpp",
            "source/opt/replace_invalid_opc.cpp",
            "source/opt/replace_desc_array_access_using_var_index.cpp",
            "source/opt/scalar_analysis.cpp",
            "source/opt/scalar_analysis_simplification.cpp",
            "source/opt/scalar_replacement_pass.cpp",
            "source/opt/set_spec_constant_default_value_pass.cpp",
            "source/opt/simplification_pass.cpp",
            "source/opt/spread_volatile_semantics.cpp",
            "source/opt/ssa_rewrite_pass.cpp",
            "source/opt/strength_reduction_pass.cpp",
            "source/opt/strip_debug_info_pass.cpp",
            "source/opt/strip_nonsemantic_info_pass.cpp",
            "source/opt/struct_cfg_analysis.cpp",
            "source/opt/type_manager.cpp",
            "source/opt/types.cpp",
            "source/opt/unify_const_pass.cpp",
            "source/opt/upgrade_memory_model.cpp",
            "source/opt/value_number_table.cpp",
            "source/opt/vector_dce.cpp",
            "source/opt/workaround1209.cpp",
            "source/opt/wrap_opkill.cpp",
            "source/parsed_operand.cpp",
            "source/print.cpp",
            "source/reduce/change_operand_reduction_opportunity.cpp",
            "source/reduce/change_operand_to_undef_reduction_opportunity.cpp",
            "source/reduce/conditional_branch_to_simple_conditional_branch_opportunity_finder.cpp",
            "source/reduce/conditional_branch_to_simple_conditional_branch_reduction_opportunity.cpp",
            "source/reduce/merge_blocks_reduction_opportunity.cpp",
            "source/reduce/merge_blocks_reduction_opportunity_finder.cpp",
            "source/reduce/operand_to_const_reduction_opportunity_finder.cpp",
            "source/reduce/operand_to_dominating_id_reduction_opportunity_finder.cpp",
            "source/reduce/operand_to_undef_reduction_opportunity_finder.cpp",
            "source/reduce/pch_source_reduce.cpp",
            "source/reduce/reducer.cpp",
            "source/reduce/reduction_opportunity.cpp",
            "source/reduce/reduction_pass.cpp",
            "source/reduce/reduction_util.cpp",
            "source/reduce/remove_block_reduction_opportunity.cpp",
            "source/reduce/remove_block_reduction_opportunity_finder.cpp",
            "source/reduce/remove_function_reduction_opportunity.cpp",
            "source/reduce/remove_function_reduction_opportunity_finder.cpp",
            "source/reduce/remove_instruction_reduction_opportunity.cpp",
            "source/reduce/remove_selection_reduction_opportunity.cpp",
            "source/reduce/remove_selection_reduction_opportunity_finder.cpp",
            "source/reduce/remove_unused_instruction_reduction_opportunity_finder.cpp",
            "source/reduce/simple_conditional_branch_to_branch_opportunity_finder.cpp",
            "source/reduce/simple_conditional_branch_to_branch_reduction_opportunity.cpp",
            "source/reduce/structured_loop_to_selection_reduction_opportunity.cpp",
            "source/reduce/structured_loop_to_selection_reduction_opportunity_finder.cpp",
            "source/software_version.cpp",
            "source/spirv_endian.cpp",
            "source/spirv_optimizer_options.cpp",
            "source/spirv_reducer_options.cpp",
            "source/spirv_target_env.cpp",
            "source/spirv_validator_options.cpp",
            "source/table.cpp",
            "source/text.cpp",
            "source/text_handler.cpp",
            "source/util/bit_vector.cpp",
            "source/util/parse_number.cpp",
            "source/util/string_utils.cpp",
            "source/val/basic_block.cpp",
            "source/val/construct.cpp",
            "source/val/function.cpp",
            "source/val/instruction.cpp",
            "source/val/validate.cpp",
            "source/val/validate_adjacency.cpp",
            "source/val/validate_annotation.cpp",
            "source/val/validate_arithmetics.cpp",
            "source/val/validate_atomics.cpp",
            "source/val/validate_barriers.cpp",
            "source/val/validate_bitwise.cpp",
            "source/val/validate_builtins.cpp",
            "source/val/validate_capability.cpp",
            "source/val/validate_cfg.cpp",
            "source/val/validate_composites.cpp",
            "source/val/validate_constants.cpp",
            "source/val/validate_conversion.cpp",
            "source/val/validate_debug.cpp",
            "source/val/validate_decorations.cpp",
            "source/val/validate_derivatives.cpp",
            "source/val/validate_execution_limitations.cpp",
            "source/val/validate_extensions.cpp",
            "source/val/validate_function.cpp",
            "source/val/validate_id.cpp",
            "source/val/validate_image.cpp",
            "source/val/validate_instruction.cpp",
            "source/val/validate_interfaces.cpp",
            "source/val/validate_layout.cpp",
            "source/val/validate_literals.cpp",
            "source/val/validate_logicals.cpp",
            "source/val/validate_memory.cpp",
            "source/val/validate_memory_semantics.cpp",
            "source/val/validate_mesh_shading.cpp",
            "source/val/validate_misc.cpp",
            "source/val/validate_mode_setting.cpp",
            "source/val/validate_non_uniform.cpp",
            "source/val/validate_primitives.cpp",
            "source/val/validate_ray_query.cpp",
            "source/val/validate_ray_tracing.cpp",
            "source/val/validate_ray_tracing_reorder.cpp",
            "source/val/validate_scopes.cpp",
            "source/val/validate_small_type_uses.cpp",
            "source/val/validate_type.cpp",
            "source/val/validation_state.cpp",
        },
        .flags = &spirv_opt_cxx_options,
    });

    spirv_opt_lib.want_lto = false;
    spirv_opt_lib.linkSystemLibrary("c++");

    const spirv_opt_lib_artifact = b.addInstallArtifact(spirv_opt_lib, .{});
    b.getInstallStep().dependOn(&spirv_opt_lib_artifact.step);

    // spriv-cross
    const spirv_cross_cxx_options = [_][]const u8{
        "-D__STDC_LIMIT_MACROS",
        "-D__STDC_FORMAT_MACROS",
        "-D__STDC_CONSTANT_MACROS",
        "-DSPIRV_CROSS_EXCEPTIONS_TO_ASSERTIONS",
        "-fno-sanitize=undefined",
    };

    const spirv_cross_path = "3rdparty/bgfx/3rdparty/spirv-cross/";
    const spirv_cross_lib = b.addStaticLibrary(.{ .name = "spirv-cross", .target = target, .optimize = build_mode });
    spirv_cross_lib.addIncludePath(b.path(spirv_cross_path ++ "include"));
    spirv_cross_lib.addCSourceFiles(.{
        .root = b.path(spirv_cross_path),
        .files = &.{
            "spirv_cfg.cpp",
            "spirv_cpp.cpp",
            "spirv_cross.cpp",
            "spirv_cross_parsed_ir.cpp",
            "spirv_cross_util.cpp",
            "spirv_glsl.cpp",
            "spirv_hlsl.cpp",
            "spirv_msl.cpp",
            "spirv_parser.cpp",
            "spirv_reflect.cpp",
        },
        .flags = &spirv_cross_cxx_options,
    });

    spirv_cross_lib.want_lto = false;
    spirv_cross_lib.linkSystemLibrary("c++");

    const spirv_cross_lib_artifact = b.addInstallArtifact(spirv_cross_lib, .{});
    b.getInstallStep().dependOn(&spirv_cross_lib_artifact.step);

    // glslang
    const glslang_cxx_options = [_][]const u8{
        "-D__STDC_LIMIT_MACROS",
        "-D__STDC_FORMAT_MACROS",
        "-D__STDC_CONSTANT_MACROS",
        "-DENABLE_OPT=1",
        "-DENABLE_HLSL=1",
        "-fno-sanitize=undefined",
    };

    const glslang_path = "3rdparty/bgfx/3rdparty/glslang/";
    const glslang_lib = b.addStaticLibrary(.{ .name = "glslang", .target = target, .optimize = build_mode });
    glslang_lib.addIncludePath(b.path("3rdparty/bgfx/3rdparty"));
    glslang_lib.addIncludePath(b.path(glslang_path));
    glslang_lib.addIncludePath(b.path(glslang_path ++ "include"));
    glslang_lib.addSystemIncludePath(b.path(spirv_opt_path ++ "include"));
    glslang_lib.addSystemIncludePath(b.path(spirv_opt_path ++ "source"));
    glslang_lib.addCSourceFiles(.{
        .root = b.path(glslang_path),
        .files = &.{
            "OGLCompilersDLL/InitializeDll.cpp",
            "SPIRV/GlslangToSpv.cpp",
            "SPIRV/InReadableOrder.cpp",
            "SPIRV/Logger.cpp",
            "SPIRV/SPVRemapper.cpp",
            "SPIRV/SpvBuilder.cpp",
            "SPIRV/SpvPostProcess.cpp",
            "SPIRV/SpvTools.cpp",
            "SPIRV/disassemble.cpp",
            "SPIRV/doc.cpp",
            "glslang/GenericCodeGen/CodeGen.cpp",
            "glslang/GenericCodeGen/Link.cpp",
            "glslang/HLSL/hlslAttributes.cpp",
            "glslang/HLSL/hlslGrammar.cpp",
            "glslang/HLSL/hlslOpMap.cpp",
            "glslang/HLSL/hlslParseHelper.cpp",
            "glslang/HLSL/hlslParseables.cpp",
            "glslang/HLSL/hlslScanContext.cpp",
            "glslang/HLSL/hlslTokenStream.cpp",
            "glslang/MachineIndependent/Constant.cpp",
            "glslang/MachineIndependent/InfoSink.cpp",
            "glslang/MachineIndependent/Initialize.cpp",
            "glslang/MachineIndependent/IntermTraverse.cpp",
            "glslang/MachineIndependent/Intermediate.cpp",
            "glslang/MachineIndependent/ParseContextBase.cpp",
            "glslang/MachineIndependent/ParseHelper.cpp",
            "glslang/MachineIndependent/PoolAlloc.cpp",
            "glslang/MachineIndependent/RemoveTree.cpp",
            "glslang/MachineIndependent/Scan.cpp",
            "glslang/MachineIndependent/ShaderLang.cpp",
            "glslang/MachineIndependent/SymbolTable.cpp",
            "glslang/MachineIndependent/SpirvIntrinsics.cpp",
            "glslang/MachineIndependent/Versions.cpp",
            "glslang/MachineIndependent/attribute.cpp",
            "glslang/MachineIndependent/glslang_tab.cpp",
            "glslang/MachineIndependent/intermOut.cpp",
            "glslang/MachineIndependent/iomapper.cpp",
            "glslang/MachineIndependent/limits.cpp",
            "glslang/MachineIndependent/linkValidate.cpp",
            "glslang/MachineIndependent/parseConst.cpp",
            "glslang/MachineIndependent/preprocessor/Pp.cpp",
            "glslang/MachineIndependent/preprocessor/PpAtom.cpp",
            "glslang/MachineIndependent/preprocessor/PpContext.cpp",
            "glslang/MachineIndependent/preprocessor/PpScanner.cpp",
            "glslang/MachineIndependent/preprocessor/PpTokens.cpp",
            "glslang/MachineIndependent/propagateNoContraction.cpp",
            "glslang/MachineIndependent/reflection.cpp",
        },
        .flags = &glslang_cxx_options,
    });

    if (target.result.os.tag == .windows) {
        glslang_lib.addCSourceFile(.{
            .file = b.path(glslang_path ++ "glslang/OSDependent/Windows/ossource.cpp"),
            .flags = &glslang_cxx_options,
        });
    }
    if (target.result.os.tag == .linux or target.result.os.tag == .macos) {
        glslang_lib.addCSourceFile(.{
            .file = b.path(glslang_path ++ "glslang/OSDependent/Unix/ossource.cpp"),
            .flags = &glslang_cxx_options,
        });
    }

    glslang_lib.want_lto = false;
    glslang_lib.linkSystemLibrary("c++");

    const glslang_lib_artifact = b.addInstallArtifact(glslang_lib, .{});
    b.getInstallStep().dependOn(&glslang_lib_artifact.step);

    // glslang
    const glsl_optimizer_cxx_options = [_][]const u8{
        "-MMD",
        "-MP",
        "-MP",
        "-Wall",
        "-Wextra",
        "-ffast-math",
        "-fomit-frame-pointer",
        "-g",
        "-m64",
        "-std=c++14",
        "-fno-rtti",
        "-fno-exceptions",
        "-D__STDC_LIMIT_MACROS",
        "-D__STDC_FORMAT_MACROS",
        "-D__STDC_CONSTANT_MACROS",
        "-fno-sanitize=undefined",
    };

    const glsl_optimizer_c_options = [_][]const u8{
        "-MMD",
        "-MP",
        "-MP",
        "-Wall",
        "-Wextra",
        "-ffast-math",
        "-fomit-frame-pointer",
        "-g",
        "-m64",
        "-D__STDC_LIMIT_MACROS",
        "-D__STDC_FORMAT_MACROS",
        "-D__STDC_CONSTANT_MACROS",
        "-fno-sanitize=undefined",
    };

    const glsl_optimizer_path = "3rdparty/bgfx/3rdparty/glsl-optimizer/";
    const glsl_optimizer_lib = b.addStaticLibrary(.{ .name = "glsl-optimizer", .target = target, .optimize = build_mode });
    glsl_optimizer_lib.addIncludePath(b.path(glsl_optimizer_path ++ "include"));
    glsl_optimizer_lib.addIncludePath(b.path(glsl_optimizer_path ++ "src"));
    glsl_optimizer_lib.addIncludePath(b.path(glsl_optimizer_path ++ "src/mesa"));
    glsl_optimizer_lib.addIncludePath(b.path(glsl_optimizer_path ++ "src/mapi"));
    glsl_optimizer_lib.addIncludePath(b.path(glsl_optimizer_path ++ "src/glsl"));

    // add C++ files
    glsl_optimizer_lib.addCSourceFiles(.{
        .root = b.path(glsl_optimizer_path),
        .files = &.{
            "src/glsl/ast_array_index.cpp",
            "src/glsl/ast_expr.cpp",
            "src/glsl/ast_function.cpp",
            "src/glsl/ast_to_hir.cpp",
            "src/glsl/ast_type.cpp",
            "src/glsl/builtin_functions.cpp",
            "src/glsl/builtin_types.cpp",
            "src/glsl/builtin_variables.cpp",
            "src/glsl/glsl_lexer.cpp",
            "src/glsl/glsl_optimizer.cpp",
            "src/glsl/glsl_parser.cpp",
            "src/glsl/glsl_parser_extras.cpp",
            "src/glsl/glsl_symbol_table.cpp",
            "src/glsl/glsl_types.cpp",
            "src/glsl/hir_field_selection.cpp",
            "src/glsl/ir.cpp",
            "src/glsl/ir_basic_block.cpp",
            "src/glsl/ir_builder.cpp",
            "src/glsl/ir_clone.cpp",
            "src/glsl/ir_constant_expression.cpp",
            "src/glsl/ir_equals.cpp",
            "src/glsl/ir_expression_flattening.cpp",
            "src/glsl/ir_function.cpp",
            "src/glsl/ir_function_can_inline.cpp",
            "src/glsl/ir_function_detect_recursion.cpp",
            "src/glsl/ir_hierarchical_visitor.cpp",
            "src/glsl/ir_hv_accept.cpp",
            "src/glsl/ir_import_prototypes.cpp",
            "src/glsl/ir_print_glsl_visitor.cpp",
            "src/glsl/ir_print_metal_visitor.cpp",
            "src/glsl/ir_print_visitor.cpp",
            "src/glsl/ir_rvalue_visitor.cpp",
            "src/glsl/ir_stats.cpp",
            "src/glsl/ir_unused_structs.cpp",
            "src/glsl/ir_validate.cpp",
            "src/glsl/ir_variable_refcount.cpp",
            "src/glsl/link_atomics.cpp",
            "src/glsl/link_functions.cpp",
            "src/glsl/link_interface_blocks.cpp",
            "src/glsl/link_uniform_block_active_visitor.cpp",
            "src/glsl/link_uniform_blocks.cpp",
            "src/glsl/link_uniform_initializers.cpp",
            "src/glsl/link_uniforms.cpp",
            "src/glsl/link_varyings.cpp",
            "src/glsl/linker.cpp",
            "src/glsl/loop_analysis.cpp",
            "src/glsl/loop_controls.cpp",
            "src/glsl/loop_unroll.cpp",
            "src/glsl/lower_clip_distance.cpp",
            "src/glsl/lower_discard.cpp",
            "src/glsl/lower_discard_flow.cpp",
            "src/glsl/lower_if_to_cond_assign.cpp",
            "src/glsl/lower_instructions.cpp",
            "src/glsl/lower_jumps.cpp",
            "src/glsl/lower_mat_op_to_vec.cpp",
            "src/glsl/lower_named_interface_blocks.cpp",
            "src/glsl/lower_noise.cpp",
            "src/glsl/lower_offset_array.cpp",
            "src/glsl/lower_output_reads.cpp",
            "src/glsl/lower_packed_varyings.cpp",
            "src/glsl/lower_packing_builtins.cpp",
            "src/glsl/lower_ubo_reference.cpp",
            "src/glsl/lower_variable_index_to_cond_assign.cpp",
            "src/glsl/lower_vec_index_to_cond_assign.cpp",
            "src/glsl/lower_vec_index_to_swizzle.cpp",
            "src/glsl/lower_vector.cpp",
            "src/glsl/lower_vector_insert.cpp",
            "src/glsl/lower_vertex_id.cpp",
            "src/glsl/opt_algebraic.cpp",
            "src/glsl/opt_array_splitting.cpp",
            "src/glsl/opt_constant_folding.cpp",
            "src/glsl/opt_constant_propagation.cpp",
            "src/glsl/opt_constant_variable.cpp",
            "src/glsl/opt_copy_propagation.cpp",
            "src/glsl/opt_copy_propagation_elements.cpp",
            "src/glsl/opt_cse.cpp",
            "src/glsl/opt_dead_builtin_variables.cpp",
            "src/glsl/opt_dead_builtin_varyings.cpp",
            "src/glsl/opt_dead_code.cpp",
            "src/glsl/opt_dead_code_local.cpp",
            "src/glsl/opt_dead_functions.cpp",
            "src/glsl/opt_flatten_nested_if_blocks.cpp",
            "src/glsl/opt_flip_matrices.cpp",
            "src/glsl/opt_function_inlining.cpp",
            "src/glsl/opt_if_simplification.cpp",
            "src/glsl/opt_minmax.cpp",
            "src/glsl/opt_noop_swizzle.cpp",
            "src/glsl/opt_rebalance_tree.cpp",
            "src/glsl/opt_redundant_jumps.cpp",
            "src/glsl/opt_structure_splitting.cpp",
            "src/glsl/opt_swizzle_swizzle.cpp",
            "src/glsl/opt_tree_grafting.cpp",
            "src/glsl/opt_vectorize.cpp",
            "src/glsl/s_expression.cpp",
            "src/glsl/standalone_scaffolding.cpp",
        },
        .flags = &glsl_optimizer_cxx_options,
    });

    // adding C files
    glsl_optimizer_lib.addCSourceFiles(.{
        .root = b.path(glsl_optimizer_path),
        .files = &.{
            "src/glsl/glcpp/glcpp-lex.c",
            "src/glsl/glcpp/glcpp-parse.c",
            "src/glsl/glcpp/pp.c",
            "src/glsl/strtod.c",
            "src/mesa/main/imports.c",
            "src/mesa/program/prog_hash_table.c",
            "src/mesa/program/symbol_table.c",
            "src/util/hash_table.c",
            "src/util/ralloc.c",
        },
        .flags = &glsl_optimizer_c_options,
    });

    glsl_optimizer_lib.want_lto = false;
    glsl_optimizer_lib.linkSystemLibrary("c++");

    const glsl_optimizer_lib_artifact = b.addInstallArtifact(glsl_optimizer_lib, .{});
    b.getInstallStep().dependOn(&glsl_optimizer_lib_artifact.step);

    const shaderc_cxx_options = [_][]const u8{
        "-D__STDC_LIMIT_MACROS",
        "-D__STDC_FORMAT_MACROS",
        "-D__STDC_CONSTANT_MACROS",
        "-DBX_CONFIG_DEBUG",
        "-DSHADERC_STANDALONE",
        "-fno-sanitize=undefined",
    };
    const bgfx_path = "3rdparty/bgfx/";
    const bx_path = "3rdparty/bx/";

    const exe = b.addExecutable(.{
        .name = "shaderc",
        .target = target,
        .optimize = build_mode,
    });

    exe.addIncludePath(b.path(bx_path ++ "3rdparty"));
    exe.addIncludePath(b.path(bx_path ++ "include"));
    exe.addIncludePath(b.path(bx_path ++ "/include/compat/osx"));
    exe.addIncludePath(b.path("3rdparty/bimg/include"));
    exe.addIncludePath(b.path(bgfx_path ++ "include"));
    exe.addIncludePath(b.path(bgfx_path ++ "src"));
    exe.addIncludePath(b.path(bgfx_path ++ "3rdparty/dxsdk/include"));
    exe.addIncludePath(b.path(bgfx_path ++ "3rdparty/fcpp"));
    exe.addIncludePath(b.path(bgfx_path ++ "3rdparty/glslang/glslang/Public"));
    exe.addIncludePath(b.path(bgfx_path ++ "3rdparty/glslang/glslang/Include"));
    exe.addIncludePath(b.path(bgfx_path ++ "3rdparty/glslang"));
    exe.addIncludePath(b.path(bgfx_path ++ "3rdparty/glsl-optimizer/include"));
    exe.addIncludePath(b.path(bgfx_path ++ "3rdparty/glsl-optimizer/src/glsl"));
    exe.addIncludePath(b.path(bgfx_path ++ "3rdparty/spirv-cross"));
    exe.addIncludePath(b.path(bgfx_path ++ "3rdparty/spirv-tools/include"));
    exe.addIncludePath(b.path(bgfx_path ++ "3rdparty/webgpu/include"));
    exe.addCSourceFiles(.{
        .root = b.path(bx_path),
        .files = &.{
            "src/amalgamated.cpp",
        },
        .flags = &shaderc_cxx_options,
    });
    exe.addCSourceFiles(
        .{
            .root = b.path(bgfx_path),
            .files = &.{
                "src/shader.cpp",
                "src/shader_dx9bc.cpp",
                "src/shader_dxbc.cpp",
                "src/shader_spirv.cpp",
                "src/vertexlayout.cpp",
                "tools/shaderc/shaderc.cpp",
                "tools/shaderc/shaderc_glsl.cpp",
                "tools/shaderc/shaderc_hlsl.cpp",
                "tools/shaderc/shaderc_metal.cpp",
                "tools/shaderc/shaderc_pssl.cpp",
                "tools/shaderc/shaderc_spirv.cpp",
            },
            .flags = &shaderc_cxx_options,
        },
    );

    exe.want_lto = false;

    exe.linkLibrary(fcpp_lib);
    exe.linkLibrary(glslang_lib);
    exe.linkLibrary(glsl_optimizer_lib);
    exe.linkLibrary(spirv_opt_lib);
    exe.linkLibrary(spirv_cross_lib);
    exe.linkSystemLibrary("c++");

    if (target.result.os.tag == .macos) {
        exe.linkFramework("CoreFoundation");
        exe.linkFramework("Foundation");
    }

    const install_exe = b.addInstallArtifact(exe, .{});
    b.getInstallStep().dependOn(&install_exe.step);
    return exe;
}

inline fn thisDir() []const u8 {
    return comptime std.fs.path.dirname(@src().file) orelse ".";
}
