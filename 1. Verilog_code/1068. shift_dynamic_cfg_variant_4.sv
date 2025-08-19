//SystemVerilog
module shift_dynamic_cfg #(parameter WIDTH=8) (
    input clk,
    input [1:0] cfg_mode, // 00-hold, 01-left, 10-right, 11-load
    input [WIDTH-1:0] cfg_data,
    output reg [WIDTH-1:0] dout
);

wire [1:0] right_shift_operand;
wire [1:0] right_shift_subtrahend;
wire [1:0] right_shift_twos_complement;
wire [2:0] right_shift_add_result;

assign right_shift_operand = dout[1:0];
assign right_shift_subtrahend = 2'b01;
// Two's complement: invert and add 1
assign right_shift_twos_complement = ~right_shift_subtrahend + 2'b01;
// Add for subtraction in two's complement
assign right_shift_add_result = {1'b0, right_shift_operand} + {1'b0, right_shift_twos_complement};

always @(posedge clk) begin
    case(cfg_mode)
        2'b01: dout <= {dout[WIDTH-2:0], 1'b0};
        2'b10: begin
            // Right shift using two's complement subtractor for 2-bit
            dout[1:0] <= right_shift_add_result[1:0];
            dout[WIDTH-1:2] <= dout[WIDTH-1:2];
        end
        2'b11: dout <= cfg_data;
        default: dout <= dout;
    endcase
end

endmodule