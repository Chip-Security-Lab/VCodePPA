//SystemVerilog
module param_hamming_encoder #(
    parameter DATA_WIDTH = 4
)(
    input clk, enable,
    input [DATA_WIDTH-1:0] data,
    output reg [(DATA_WIDTH+4):0] encoded
);
    // 声明合理的变量大小
    reg [DATA_WIDTH-1:0] data_reg;
    reg [3:0] parity_bits;
    
    // 预先计算的索引映射表，避免循环逻辑
    reg [3:0] position_map[0:DATA_WIDTH-1];
    integer i;
    
    initial begin
        // 为每个数据位预先计算其在编码输出中的位置
        // 这样避免了运行时的循环判断
        position_map[0] = 2;
        position_map[1] = 4;
        position_map[2] = 5;
        position_map[3] = 6;
    end
    
    always @(posedge clk) begin
        if (enable) begin
            data_reg <= data;
            
            // 优化校验位计算 - 使用位掩码和异或组合
            parity_bits[0] <= ^(data & {DATA_WIDTH{1'b1}} & 4'b0101);
            parity_bits[1] <= ^(data & {DATA_WIDTH{1'b1}} & 4'b0110);
            parity_bits[2] <= ^(data & {DATA_WIDTH{1'b1}} & 4'b1100);
            parity_bits[3] <= ^data;
            
            // 将校验位放在固定位置
            encoded[0] <= parity_bits[0]; // 位置1
            encoded[1] <= parity_bits[1]; // 位置2
            encoded[3] <= parity_bits[2]; // 位置4
            encoded[7] <= parity_bits[3]; // 位置8
            
            // 并行放置数据位而不是循环
            for (i = 0; i < DATA_WIDTH; i = i + 1) begin
                encoded[position_map[i]] <= data_reg[i];
            end
        end
    end
endmodule