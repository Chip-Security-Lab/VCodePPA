//SystemVerilog
// Top-level module: Hierarchical rotate left with asynchronous shift using barrel shifter
module rotate_left_async #(parameter WIDTH=8) (
    input  [WIDTH-1:0] din,
    input  [$clog2(WIDTH)-1:0] shift,
    output [WIDTH-1:0] dout
);

    wire [WIDTH-1:0] rotated_data;

    barrel_rotate_left #(
        .WIDTH(WIDTH)
    ) u_barrel_rotate_left (
        .data_in(din),
        .shift_amt(shift),
        .data_out(rotated_data)
    );

    assign dout = rotated_data;

endmodule

// Barrel shifter-based rotate left module
module barrel_rotate_left #(parameter WIDTH=8) (
    input  [WIDTH-1:0] data_in,
    input  [$clog2(WIDTH)-1:0] shift_amt,
    output [WIDTH-1:0] data_out
);
    // Stage wires for each step in the barrel shifter
    wire [WIDTH-1:0] stage [0:$clog2(WIDTH)];

    assign stage[0] = data_in;

    genvar i;
    generate
        for (i = 0; i < $clog2(WIDTH); i = i + 1) begin : gen_barrel_shift
            wire [WIDTH-1:0] temp_left;
            assign temp_left = {stage[i][WIDTH-(1<<i)-1:0], stage[i][WIDTH-1:WIDTH-(1<<i)]};
            assign stage[i+1] = shift_amt[i] ? temp_left : stage[i];
        end
    endgenerate

    assign data_out = stage[$clog2(WIDTH)];

endmodule