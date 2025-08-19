//SystemVerilog
// 顶层模块
module d_latch_async_rst (
    input wire d,
    input wire enable,
    input wire rst_n,    // Active low reset
    output wire q
);
    // 内部连线
    wire data_gated;
    
    // 实例化子模块
    latch_input_controller input_ctrl (
        .d(d),
        .enable(enable),
        .data_gated(data_gated)
    );
    
    latch_storage_unit storage_unit (
        .data_in(data_gated),
        .rst_n(rst_n),
        .q(q)
    );
    
endmodule

// 输入控制子模块
module latch_input_controller (
    input wire d,
    input wire enable,
    output wire data_gated
);
    // 控制数据何时可以通过
    assign data_gated = enable ? d : 1'bz;
endmodule

// 存储单元子模块
module latch_storage_unit (
    input wire data_in,
    input wire rst_n,
    output reg q
);
    // 存储元素实现，优化敏感列表和时序
    always @(data_in, rst_n) begin
        if (!rst_n)
            q <= 1'b0;
        else if (data_in !== 1'bz)
            q <= data_in;
    end
endmodule