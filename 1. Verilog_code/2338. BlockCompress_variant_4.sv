//SystemVerilog
module BlockCompress #(parameter BLK=4) (
    input clk, blk_en,
    input [BLK*8-1:0] data,
    output reg [15:0] code
);
    // 中间寄存器，存储数据位进行XOR操作
    reg [BLK*8-1:0] data_reg;
    reg [15:0] xor_result;
    
    // 合并所有posedge clk触发的always块
    always @(posedge clk) begin
        if (blk_en) begin
            data_reg <= data;
            code <= xor_result;
        end
    end
    
    // 基于分段XOR的组合逻辑，提高效率
    always @(*) begin
        integer i;
        xor_result = 16'h0000;
        for (i = 0; i < BLK; i = i + 1) begin
            xor_result = xor_result ^ {8'h00, data_reg[i*8 +: 8]};
        end
    end
endmodule