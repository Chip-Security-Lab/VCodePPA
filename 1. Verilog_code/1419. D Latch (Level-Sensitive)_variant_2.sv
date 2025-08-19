//SystemVerilog (IEEE 1364-2005)
module d_latch (
    input  wire enable,
    input  wire d,
    output wire q
);
    // 实例化控制逻辑和状态保持子模块
    wire data_gated;
    
    d_latch_control control_unit (
        .enable(enable),
        .d(d),
        .data_gated(data_gated)
    );
    
    d_latch_storage storage_unit (
        .data_gated(data_gated),
        .enable(enable),
        .q(q)
    );
    
endmodule

module d_latch_control (
    input  wire enable,
    input  wire d,
    output wire data_gated
);
    // 控制逻辑 - 处理使能和数据输入
    assign data_gated = d & enable;
endmodule

module d_latch_storage (
    input  wire data_gated,
    input  wire enable,
    output reg  q
);
    // 状态存储逻辑 - 维持锁存器状态
    always @(*) begin
        if (enable) q = data_gated;
    end
endmodule