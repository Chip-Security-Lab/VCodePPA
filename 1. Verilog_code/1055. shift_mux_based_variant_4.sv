//SystemVerilog
module shift_mux_based #(parameter WIDTH=8) (
    input  [WIDTH-1:0] data_in,
    input  [$clog2(WIDTH)-1:0] shift_amt,
    output [WIDTH-1:0] data_out
);

wire [WIDTH-1:0] shifted_data;
wire [WIDTH-1:0] two_complement_operand;
wire [WIDTH-1:0] subtractor_result;
wire             subtractor_carry;

localparam [WIDTH-1:0] SUBTRACT_VALUE = 8'd15;

// Barrel shifter implementation for left shift
function [WIDTH-1:0] barrel_shifter_left;
    input [WIDTH-1:0] in_data;
    input [$clog2(WIDTH)-1:0] amt;
    integer i, j;
    reg [WIDTH-1:0] temp [0:$clog2(WIDTH)];
begin
    temp[0] = in_data;
    for (i = 0; i < $clog2(WIDTH); i = i + 1) begin
        for (j = 0; j < WIDTH; j = j + 1) begin
            if (j < (1 << i))
                temp[i+1][j] = temp[i][j];
            else if (amt[i])
                temp[i+1][j] = temp[i][j-(1<<i)];
            else
                temp[i+1][j] = temp[i][j];
        end
    end
    barrel_shifter_left = temp[$clog2(WIDTH)];
end
endfunction

assign shifted_data = barrel_shifter_left(data_in, shift_amt);

// Prepare two's complement of SUBTRACT_VALUE
assign two_complement_operand = ~SUBTRACT_VALUE + 1'b1;

// Use binary two's complement subtraction algorithm
assign {subtractor_carry, subtractor_result} = {1'b0, shifted_data} + {1'b0, two_complement_operand};

assign data_out = subtractor_result;

endmodule