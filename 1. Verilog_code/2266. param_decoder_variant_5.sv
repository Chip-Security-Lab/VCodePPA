//SystemVerilog
module param_decoder #(
    parameter ADDR_WIDTH = 4,
    parameter OUT_WIDTH = 16
)(
    input wire clk,
    input wire rst_n,
    input wire [ADDR_WIDTH-1:0] address,
    input wire enable,
    output reg [OUT_WIDTH-1:0] select
);
    // 解码计算在组合逻辑中完成，而不是在寄存器后
    wire [OUT_WIDTH-1:0] decoded = (1 << address);
    
    // 第一级流水线：存储解码结果和使能信号
    reg [OUT_WIDTH-1:0] decode_r;
    reg enable_r;
    
    // 优化的数据流路径
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // 复位所有流水线寄存器
            decode_r <= {OUT_WIDTH{1'b0}};
            enable_r <= 1'b0;
            select <= {OUT_WIDTH{1'b0}};
        end
        else begin
            // 第一级流水线：存储预解码结果和使能信号
            decode_r <= decoded;
            enable_r <= enable;
            
            // 第二级流水线：使能控制和输出
            select <= enable_r ? decode_r : {OUT_WIDTH{1'b0}};
        end
    end
endmodule