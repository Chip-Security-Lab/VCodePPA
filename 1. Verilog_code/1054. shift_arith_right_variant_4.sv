//SystemVerilog
module shift_arith_right #(parameter WIDTH=8) (
    input  wire [WIDTH-1:0] data_in,
    input  wire [2:0] shift_amount,
    output reg  [WIDTH-1:0] data_out
);

    // 3位补码减法运算单元
    function [2:0] twos_complement_subtract_3bit;
        input [2:0] minuend;
        input [2:0] subtrahend;
        reg   [2:0] subtrahend_inverted;
        reg   [3:0] sum; // 1位扩展防止溢出
        begin
            subtrahend_inverted = ~subtrahend;
            sum = {1'b0, minuend} + {1'b0, subtrahend_inverted} + 1'b1;
            twos_complement_subtract_3bit = sum[2:0];
        end
    endfunction

    integer i;
    reg signed [WIDTH-1:0] temp_data;
    reg [2:0] shift_counter;

    always @* begin
        temp_data = $signed(data_in);
        shift_counter = shift_amount;
        for (i = 0; i < 3; i = i + 1) begin
            if (shift_counter != 3'b000) begin
                temp_data = {temp_data[WIDTH-1], temp_data[WIDTH-1:1]};
                shift_counter = twos_complement_subtract_3bit(shift_counter, 3'b001);
            end
        end
        data_out = temp_data;
    end

endmodule