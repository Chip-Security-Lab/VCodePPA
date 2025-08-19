//SystemVerilog
module param_hamming_encoder #(
    parameter DATA_WIDTH = 4
)(
    input clk, enable,
    input [DATA_WIDTH-1:0] data,
    output reg [(DATA_WIDTH+4):0] encoded
);
    // 声明足够的数组大小
    reg [DATA_WIDTH-1:0] data_reg;
    reg [3:0] parity_bits;
    integer j;
    
    always @(posedge clk) begin
        if (enable) begin
            data_reg <= data;
            
            // 计算校验位 (简化实现)
            parity_bits[0] <= ^(data & 4'b0101);
            parity_bits[1] <= ^(data & 4'b0110);
            parity_bits[2] <= ^(data & 4'b1100);
            parity_bits[3] <= ^data;
            
            // 使用变量j跟踪数据位索引
            j = 0;
            
            // 使用case语句填充编码位
            for (integer i = 0; i < DATA_WIDTH+4; i = i + 1) begin
                // 将位置k作为case变量
                case (i + 1)
                    1: encoded[i] <= parity_bits[0];
                    2: encoded[i] <= parity_bits[1];
                    4: encoded[i] <= parity_bits[2];
                    8: encoded[i] <= parity_bits[3];
                    default: begin
                        if (j < DATA_WIDTH) begin
                            encoded[i] <= data_reg[j];
                            j = j + 1;
                        end
                    end
                endcase
            end
        end
    end
endmodule