//SystemVerilog
module power_optimized_crc(
    input wire clk,
    input wire rst,
    input wire [7:0] data,
    input wire data_valid,
    input wire power_save,
    output reg [7:0] crc
);
    parameter [7:0] POLY = 8'h07;
    
    // 使用时钟门控单元代替简单的AND门
    // 减少时钟树功耗和潜在的毛刺问题
    reg clk_en;
    wire gated_clk;
    
    always @(negedge clk or posedge rst) begin
        if (rst)
            clk_en <= 1'b0;
        else
            clk_en <= ~power_save;
    end
    
    assign gated_clk = clk & clk_en;
    
    // CRC计算逻辑优化
    wire xor_bit = crc[7] ^ data[0];
    wire [7:0] shifted_crc = {crc[6:0], 1'b0};
    wire [7:0] poly_mask = {8{xor_bit}} & POLY;
    
    always @(posedge gated_clk or posedge rst) begin
        if (rst) 
            crc <= 8'h00;
        else if (data_valid) 
            crc <= shifted_crc ^ poly_mask;
    end
endmodule