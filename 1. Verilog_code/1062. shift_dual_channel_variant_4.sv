//SystemVerilog
module shift_dual_channel #(parameter WIDTH=8) (
    input  [WIDTH-1:0] din,
    output [WIDTH-1:0] left_out,
    output [WIDTH-1:0] right_out
);

    // Barrel shifter for left shift by 1 using MUX-based structure
    wire [WIDTH-1:0] left_shifted;
    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin: LEFT_SHIFT_MUX
            if (i == WIDTH-1) begin
                assign left_shifted[i] = 1'b0;
            end else begin
                assign left_shifted[i] = din[i+1];
            end
        end
    endgenerate

    // Barrel shifter for right shift by 1 using MUX-based structure
    wire [WIDTH-1:0] right_shifted;
    genvar j;
    generate
        for (j = 0; j < WIDTH; j = j + 1) begin: RIGHT_SHIFT_MUX
            if (j == 0) begin
                assign right_shifted[j] = 1'b0;
            end else begin
                assign right_shifted[j] = din[j-1];
            end
        end
    endgenerate

    assign left_out  = left_shifted;
    assign right_out = right_shifted;

endmodule

module subtractor_lut8 (
    input  [7:0] a,
    input  [7:0] b,
    output [7:0] diff
);
    reg [7:0] sub_lut [0:65535];
    initial begin : init_sub_lut
        integer idx;
        for (idx = 0; idx < 65536; idx = idx + 1) begin
            sub_lut[idx] = ((idx[15:8]) - (idx[7:0])) & 8'hFF;
        end
    end
    assign diff = sub_lut[{a, b}];
endmodule