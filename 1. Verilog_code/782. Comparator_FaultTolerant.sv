module Comparator_FaultTolerant #(
    parameter WIDTH = 8,
    parameter PARITY_TYPE = 0    // 0:偶校验 1:奇校验
)(
    input  [WIDTH:0]   data_a,   // [WIDTH]为校验位
    input  [WIDTH:0]   data_b,
    output             safe_equal
);
    // 校验位验证
    wire parity_ok_a = (^data_a[WIDTH-1:0]) == 
                      (PARITY_TYPE ? ~data_a[WIDTH] : data_a[WIDTH]);
    wire parity_ok_b = (^data_b[WIDTH-1:0]) == 
                      (PARITY_TYPE ? ~data_b[WIDTH] : data_b[WIDTH]);
    
    assign safe_equal = parity_ok_a & parity_ok_b & 
                       (data_a[WIDTH-1:0] == data_b[WIDTH-1:0]);
endmodule