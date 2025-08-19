//SystemVerilog
module MajorityVote #(parameter N=5, M=3) (
    input [N-1:0] inputs,
    output reg vote_out
);
    wire [N-1:0] sum_bits;
    wire [N-1:0] sum_bits_shifted;
    wire [N-1:0] sum_result;
    wire [N-1:0] threshold_comp;
    
    assign sum_bits = inputs;
    assign sum_bits_shifted = sum_bits >> 1;
    assign threshold_comp = ~M + 1'b1;  // 补码表示
    assign sum_result = sum_bits + sum_bits_shifted;
    
    always @(*) begin
        vote_out = (sum_result + threshold_comp) >= 0;
    end
endmodule