//SystemVerilog
// 顶层模块
module parametric_crc #(
    parameter WIDTH = 8,
    parameter POLY = 8'h9B,
    parameter INIT = {WIDTH{1'b1}}
)(
    input clk,
    input en,
    input [WIDTH-1:0] data,
    output [WIDTH-1:0] crc
);
    // Internal signals
    wire [WIDTH-1:0] next_crc;
    
    // 优化的CRC计算逻辑
    wire [WIDTH-1:0] shifted_crc = {crc[WIDTH-2:0], 1'b0};
    wire [WIDTH-1:0] feedback_mask = {WIDTH{crc[WIDTH-1]}};
    wire [WIDTH-1:0] poly_masked = POLY & feedback_mask;
    
    // 计算下一个CRC值
    assign next_crc = shifted_crc ^ poly_masked ^ data;
    
    // 寄存器逻辑
    reg [WIDTH-1:0] crc_reg;
    assign crc = crc_reg;
    
    // 时序逻辑部分
    always @(posedge clk) begin
        if (!en) begin
            crc_reg <= INIT;
        end else begin
            crc_reg <= next_crc;
        end
    end
    
endmodule