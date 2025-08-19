//SystemVerilog
module async_reset_qualifier(
    input wire raw_reset,
    input wire [3:0] qualifiers,
    output wire [3:0] qualified_resets
);
    // 实例化reset_mask_generator子模块
    wire [3:0] reset_mask;
    reset_mask_generator rmg_inst (
        .reset_in(raw_reset),
        .reset_mask(reset_mask)
    );
    
    // 实例化reset_qualifier子模块
    reset_qualifier rq_inst (
        .reset_mask(reset_mask),
        .qualifiers(qualifiers),
        .qualified_resets(qualified_resets)
    );
    
endmodule

module reset_mask_generator(
    input wire reset_in,
    output wire [3:0] reset_mask
);
    // 生成复位掩码，将单个复位信号广播到所有位
    assign reset_mask = {4{reset_in}};
    
endmodule

module reset_qualifier(
    input wire [3:0] reset_mask,
    input wire [3:0] qualifiers,
    output wire [3:0] qualified_resets
);
    // 应用限定条件到复位信号
    assign qualified_resets = reset_mask & qualifiers;
    
endmodule