//SystemVerilog
// Top-level module: rng_combine_14
module rng_combine_14(
    input             clk,
    input             rst,
    input             en,
    output reg [7:0]  rnd
);

    wire [7:0] rng_mixer_out;
    reg  [7:0] rnd_buf;   // First buffer stage for data_in
    reg  [7:0] rnd_buf2;  // Second buffer stage for data_in (for further fanout balancing)

    // Buffer the high-fanout data_in signal (rnd) before feeding to submodule
    always @(posedge clk) begin
        if (rst)
            rnd_buf <= 8'h99;
        else if (en)
            rnd_buf <= rnd;
    end

    always @(posedge clk) begin
        if (rst)
            rnd_buf2 <= 8'h99;
        else if (en)
            rnd_buf2 <= rnd_buf;
    end

    // RNG Mix Logic Submodule instance, driven by buffered signal
    rng_mixer u_rng_mixer (
        .data_in    (rnd_buf2),
        .mix_out    (rng_mixer_out)
    );

    // RNG State Register Submodule instance
    always @(posedge clk) begin
        if (rst)
            rnd <= 8'h99;
        else if (en)
            rnd <= rng_mixer_out;
    end

endmodule

// -----------------------------------------------------------------------------
// Submodule: rng_mixer
// Function: Performs mixing operation for RNG state update
// -----------------------------------------------------------------------------
module rng_mixer(
    input  [7:0] data_in,
    output [7:0] mix_out
);
    assign mix_out = (data_in << 3) ^ (data_in >> 2) ^ 8'h5A;
endmodule