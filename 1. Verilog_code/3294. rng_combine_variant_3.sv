//SystemVerilog
module rng_combine_14(
    input             clk,
    input             rst,
    input             en,
    output reg [7:0]  rnd
);
    wire [7:0] left_shift_3;
    wire [7:0] right_shift_2;
    wire [7:0] mix;

    // Barrel shifter for left shift by 3
    assign left_shift_3 = {rnd[4:0], 3'b000};

    // Barrel shifter for right shift by 2
    assign right_shift_2 = {2'b00, rnd[7:2]};

    assign mix = left_shift_3 ^ right_shift_2 ^ 8'h5A;

    always @(posedge clk) begin
        if (rst)
            rnd <= 8'h99;
        else if (en)
            rnd <= mix;
    end
endmodule