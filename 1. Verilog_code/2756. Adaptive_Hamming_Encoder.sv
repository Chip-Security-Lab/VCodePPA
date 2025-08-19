module Adaptive_Hamming_Encoder(
    input clk,
    input [7:0] data_in,
    output reg [11:0] adaptive_code,
    output reg [2:0] parity_bits_used
);
    // 替换$countones函数
    function [2:0] count_ones;
        input [7:0] data;
        reg [2:0] count;
        integer i;
        begin
            count = 0;
            for(i=0; i<8; i=i+1)
                if(data[i]) count = count + 1;
            count_ones = count;
        end
    endfunction
    
    wire [2:0] ones_count = count_ones(data_in);
    
    always @(posedge clk) begin
        case(ones_count)
            3'd0, 3'd1, 3'd2: begin // 低密度使用(8,4)码
                adaptive_code[10:8] <= data_in[7:4];
                adaptive_code[7] <= ^{data_in[7:4], data_in[3:0]};
                adaptive_code[6:0] <= {data_in[3:0], 3'b0};
                parity_bits_used <= 3'd4;
            end
            default: begin // 高密度使用(12,8)码
                adaptive_code[11] <= ^data_in;
                adaptive_code[10:3] <= data_in;
                adaptive_code[2] <= ^{data_in[7:5], data_in[3:1]};
                adaptive_code[1] <= ^{data_in[4:2], data_in[0]};
                adaptive_code[0] <= ^{data_in[7:4], data_in[3:0]};
                parity_bits_used <= 3'd3;
            end
        endcase
    end
endmodule