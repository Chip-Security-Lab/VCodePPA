//SystemVerilog
module crc_gated_clock (
    input clk, en,
    input [7:0] data,
    output reg [15:0] crc
);
    // 寄存器在前面捕获输入信号
    reg [7:0] data_reg;
    reg en_reg;
    
    // 在主时钟边沿捕获输入信号
    always @(posedge clk) begin
        data_reg <= data;
        en_reg <= en;
    end
    
    // 使用更规范的时钟门控单元
    reg en_latch;
    wire gated_clk;
    
    // 为避免毛刺，在时钟下降沿捕获寄存后的使能信号
    always @(negedge clk) begin
        en_latch <= en_reg;
    end
    
    // 生成门控时钟
    assign gated_clk = clk & en_latch;
    
    // 移动组合逻辑到寄存器之后
    wire [15:0] xor_term;
    wire [15:0] shifted_crc;
    
    assign shifted_crc = {crc[14:0], 1'b0};
    assign xor_term = crc[15] ? 16'h8005 : 16'h0000;
    
    always @(posedge gated_clk) begin
        crc <= shifted_crc ^ xor_term ^ {8'h00, data_reg};
    end
endmodule