//SystemVerilog
// 顶层模块
module shift_buffer #(
    parameter WIDTH = 8,
    parameter STAGES = 2  // 减少流水线级数，从4降至2
)(
    input wire clk,
    input wire enable,
    input wire [WIDTH-1:0] data_in,
    output wire [WIDTH-1:0] data_out
);
    // 内部连线，用于连接各级缓冲器
    wire [WIDTH-1:0] stage_connections [0:STAGES-1];
    
    // 第一级移位单元 (处理两级数据)
    shift_stage_dual #(
        .WIDTH(WIDTH)
    ) first_stage (
        .clk(clk),
        .enable(enable),
        .data_in(data_in),
        .data_out(stage_connections[0])
    );
    
    // 中间移位单元 (如果STAGES > 2时使用)
    genvar g;
    generate
        for (g = 1; g < STAGES-1; g = g + 1) begin : stage_gen
            shift_stage_dual #(
                .WIDTH(WIDTH)
            ) middle_stage (
                .clk(clk),
                .enable(enable),
                .data_in(stage_connections[g-1]),
                .data_out(stage_connections[g])
            );
        end
    endgenerate
    
    // 最后一级移位单元 (处理两级数据)
    shift_stage_dual #(
        .WIDTH(WIDTH)
    ) last_stage (
        .clk(clk),
        .enable(enable),
        .data_in(stage_connections[STAGES-2]),
        .data_out(data_out)
    );
    
endmodule

// 双级移位缓冲器子模块 (合并两个原始stage的功能)
module shift_stage_dual #(
    parameter WIDTH = 8
)(
    input wire clk,
    input wire enable,
    input wire [WIDTH-1:0] data_in,
    output reg [WIDTH-1:0] data_out
);
    // 中间寄存器，捕获第一级的结果
    reg [WIDTH-1:0] intermediate;
    
    // 在时钟上升沿，如果使能信号有效，则同时处理两级
    always @(posedge clk) begin
        if (enable) begin
            intermediate <= data_in;
            data_out <= intermediate;
        end
    end
endmodule