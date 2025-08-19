//SystemVerilog
module Comparator_Approximate #(
    parameter WIDTH = 10,
    parameter THRESHOLD = 3 // 最大允许差值
)(
    input  [WIDTH-1:0] data_p,
    input  [WIDTH-1:0] data_q,
    output             approx_eq
);
    wire [WIDTH-1:0] diff;
    wire [WIDTH-1:0] larger, smaller;
    
    // 确定较大和较小的操作数
    assign larger  = (data_p > data_q) ? data_p : data_q;
    assign smaller = (data_p > data_q) ? data_q : data_p;
    
    // 使用先行借位减法器实现
    wire [WIDTH:0] borrow;  // 多一位用于初始借位
    assign borrow[0] = 1'b0;  // 初始无借位
    
    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin: gen_sub
            assign diff[i] = larger[i] ^ smaller[i] ^ borrow[i];
            assign borrow[i+1] = (larger[i] & smaller[i] & borrow[i]) | 
                                 (~larger[i] & smaller[i]) | 
                                 (~larger[i] & borrow[i]);
        end
    endgenerate
    
    assign approx_eq = (diff <= THRESHOLD);
endmodule