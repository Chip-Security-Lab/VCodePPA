//SystemVerilog
module bidirectional_shifter #(parameter DATA_W=16) (
    input  wire [DATA_W-1:0] data,
    input  wire [$clog2(DATA_W)-1:0] amount,
    input  wire left_not_right,   // Direction control
    input  wire arithmetic_shift, // 1=arithmetic, 0=logical
    output wire [DATA_W-1:0] result
);
    // Internal signals for each shift type
    wire [DATA_W-1:0] left_shifted;
    wire [DATA_W-1:0] logical_right_shifted;
    wire [DATA_W-1:0] arithmetic_right_shifted;

    // Barrel shifter for left shift
    function [DATA_W-1:0] barrel_left_shift;
        input [DATA_W-1:0] in;
        input [$clog2(DATA_W)-1:0] shamt;
        integer i;
        reg [DATA_W-1:0] temp [0:$clog2(DATA_W)];
        begin
            temp[0] = in;
            for (i=0; i<$clog2(DATA_W); i=i+1) begin
                temp[i+1] = shamt[i] ? (temp[i] << (1<<i)) : temp[i];
            end
            barrel_left_shift = temp[$clog2(DATA_W)];
        end
    endfunction

    // Barrel shifter for logical right shift
    function [DATA_W-1:0] barrel_logical_right_shift;
        input [DATA_W-1:0] in;
        input [$clog2(DATA_W)-1:0] shamt;
        integer i;
        reg [DATA_W-1:0] temp [0:$clog2(DATA_W)];
        begin
            temp[0] = in;
            for (i=0; i<$clog2(DATA_W); i=i+1) begin
                temp[i+1] = shamt[i] ? (temp[i] >> (1<<i)) : temp[i];
            end
            barrel_logical_right_shift = temp[$clog2(DATA_W)];
        end
    endfunction

    // Barrel shifter for arithmetic right shift
    function [DATA_W-1:0] barrel_arithmetic_right_shift;
        input [DATA_W-1:0] in;
        input [$clog2(DATA_W)-1:0] shamt;
        integer i, j;
        reg [DATA_W-1:0] temp [0:$clog2(DATA_W)];
        reg signed [DATA_W-1:0] signed_temp;
        begin
            temp[0] = in;
            for (i=0; i<$clog2(DATA_W); i=i+1) begin
                if (shamt[i]) begin
                    // Arithmetic shift: replicate sign bit
                    signed_temp = $signed(temp[i]);
                    temp[i+1] = signed_temp >>> (1<<i);
                end else begin
                    temp[i+1] = temp[i];
                end
            end
            barrel_arithmetic_right_shift = temp[$clog2(DATA_W)];
        end
    endfunction

    assign left_shifted             = barrel_left_shift(data, amount);
    assign logical_right_shifted    = barrel_logical_right_shift(data, amount);
    assign arithmetic_right_shifted = barrel_arithmetic_right_shift(data, amount);

    assign result = left_not_right ? left_shifted :
                    (arithmetic_shift ? arithmetic_right_shifted : logical_right_shifted);

endmodule