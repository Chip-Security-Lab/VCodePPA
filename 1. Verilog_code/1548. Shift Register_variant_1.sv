//SystemVerilog
module shift_shadow_reg #(
    parameter WIDTH = 16,
    parameter STAGES = 2  // 减少流水线级数从3减到2
)(
    input wire clk,
    input wire rst_n,
    input wire [WIDTH-1:0] data_in,
    input wire shift,
    output wire [WIDTH-1:0] shadow_out
);
    // 减少流水线级数的移位寄存器链
    reg [WIDTH-1:0] shift_chain [0:STAGES-1];
    
    // 第一级移位寄存器控制逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // 复位第一级寄存器
            shift_chain[0] <= {WIDTH{1'b0}};
        end else if (shift) begin
            // 数据输入到第一级
            shift_chain[0] <= data_in;
        end
    end
    
    // 最后一级移位寄存器控制逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // 复位最后一级寄存器
            shift_chain[STAGES-1] <= {WIDTH{1'b0}};
        end else if (shift) begin
            // 数据从第一级传递到最后一级
            shift_chain[STAGES-1] <= shift_chain[0];
        end
    end
    
    // 输出连接到最后一级
    assign shadow_out = shift_chain[STAGES-1];
endmodule