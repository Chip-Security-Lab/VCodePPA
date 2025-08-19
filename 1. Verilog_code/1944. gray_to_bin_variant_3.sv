//SystemVerilog
module gray_to_bin #(
    parameter DATA_W = 8
)(
    input  [DATA_W-1:0] gray_code,
    output [DATA_W-1:0] binary
);
    integer idx;
    reg [DATA_W-1:0] binary_temp;
    reg [DATA_W-1:0] conditional_sum;
    reg [DATA_W-1:0] subtrahend;
    reg borrow;
    reg [DATA_W-1:0] difference;

    // 8-bit conditional sum subtractor
    function [DATA_W-1:0] conditional_sum_subtract;
        input [DATA_W-1:0] minuend;
        input [DATA_W-1:0] subtrahend;
        reg [DATA_W-1:0] sum_with_borrow0, sum_with_borrow1;
        reg [DATA_W:0] borrow_chain0, borrow_chain1;
        integer i;
        begin
            borrow_chain0[0] = 1'b0;
            borrow_chain1[0] = 1'b1;
            for (i = 0; i < DATA_W; i = i + 1) begin
                sum_with_borrow0[i] = minuend[i] ^ subtrahend[i] ^ borrow_chain0[i];
                sum_with_borrow1[i] = minuend[i] ^ subtrahend[i] ^ borrow_chain1[i];
                borrow_chain0[i+1] = (~minuend[i] & subtrahend[i]) | ((~minuend[i] | subtrahend[i]) & borrow_chain0[i]);
                borrow_chain1[i+1] = (~minuend[i] & subtrahend[i]) | ((~minuend[i] | subtrahend[i]) & borrow_chain1[i]);
            end
            conditional_sum_subtract = borrow_chain0[DATA_W] ? sum_with_borrow1 : sum_with_borrow0;
        end
    endfunction

    always @(*) begin
        binary_temp[DATA_W-1] = gray_code[DATA_W-1];
        for (idx = DATA_W-2; idx >= 0; idx = idx - 1) begin
            subtrahend = gray_code[idx];
            difference = conditional_sum_subtract(binary_temp[idx+1], subtrahend);
            binary_temp[idx] = difference;
        end
    end

    assign binary = binary_temp;
endmodule