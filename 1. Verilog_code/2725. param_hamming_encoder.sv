module param_hamming_encoder #(
    parameter DATA_WIDTH = 4
)(
    input clk, enable,
    input [DATA_WIDTH-1:0] data,
    output reg [(DATA_WIDTH+4):0] encoded // 简化的位宽计算，增加额外的位
);
    // 声明足够的数组大小
    reg [DATA_WIDTH-1:0] data_reg;
    reg [3:0] parity_bits;
    integer i, j, k;
    
    always @(posedge clk) begin
        if (enable) begin
            data_reg <= data;
            
            // 计算校验位 (简化实现)
            parity_bits[0] <= ^(data & 4'b0101);
            parity_bits[1] <= ^(data & 4'b0110);
            parity_bits[2] <= ^(data & 4'b1100);
            parity_bits[3] <= ^data;
            
            // 填充数据位
            j = 0;
            for (i = 0; i < DATA_WIDTH+4; i = i + 1) begin
                // 位置是2的幂则为校验位
                k = i + 1;
                if (k == 1 || k == 2 || k == 4 || k == 8)
                    encoded[i] <= parity_bits[k>>1];
                else if (j < DATA_WIDTH) begin
                    encoded[i] <= data_reg[j];
                    j = j + 1;
                end
            end
        end
    end
endmodule