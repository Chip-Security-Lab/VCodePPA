//SystemVerilog
module right_logical_shifter #(
    parameter WIDTH = 16
)(
    input wire clock,
    input wire reset,
    input wire enable,
    input wire [WIDTH-1:0] in_data,
    input wire [$clog2(WIDTH)-1:0] shift_amount,
    output reg [WIDTH-1:0] out_data
);
    // State encoding
    localparam [1:0] STATE_IDLE   = 2'b00;
    localparam [1:0] STATE_RESET  = 2'b01;
    localparam [1:0] STATE_ENABLE = 2'b10;
    
    reg [1:0] current_state;
    
    always @(*) begin
        case ({reset, enable})
            2'b10: current_state = STATE_RESET;
            2'b01: current_state = STATE_ENABLE;
            default: current_state = STATE_IDLE;
        endcase
    end

    // 2-bit conditional inversion subtractor
    function [1:0] conditional_invert_subtract;
        input [1:0] minuend;
        input [1:0] subtrahend;
        reg [1:0] subtrahend_inverted;
        reg carry_in;
        reg [2:0] sum;
        begin
            // invert subtrahend and add 1 (two's complement)
            subtrahend_inverted = ~subtrahend;
            carry_in = 1'b1;
            sum = minuend + subtrahend_inverted + carry_in;
            conditional_invert_subtract = sum[1:0];
        end
    endfunction

    // Shift Amount calculation using conditional inversion subtractor (2-bit wide)
    wire [1:0] shift_amt_2bit;
    assign shift_amt_2bit = conditional_invert_subtract(shift_amount[1:0], 2'b00); // Functionally returns shift_amount[1:0]

    integer i;
    reg [WIDTH-1:0] shifted_data;

    always @(*) begin
        shifted_data = in_data;
        for (i = 0; i < 2; i = i + 1) begin
            if (shift_amt_2bit[i])
                shifted_data = shifted_data >> (1 << i);
        end
    end

    always @(posedge clock) begin
        case (current_state)
            STATE_RESET:  out_data <= {WIDTH{1'b0}};
            STATE_ENABLE: out_data <= shifted_data;
            STATE_IDLE:   out_data <= out_data;
        endcase
    end
endmodule