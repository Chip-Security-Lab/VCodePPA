//SystemVerilog
// Top-level module: bin2sevenseg
// Hierarchically decomposed version of binary-to-7-segment decoder

module bin2sevenseg (
    input  wire [3:0] bin_in,
    output wire [6:0] seg_out_n  // active low {a,b,c,d,e,f,g}
);

    // Internal wire to hold segment pattern
    wire [6:0] segment_pattern;

    // Instantiate the decoder logic submodule
    bin2sevenseg_decoder u_decoder (
        .bin_in         (bin_in),
        .segment_pattern(segment_pattern)
    );

    // Output assignment (buffering, if needed for future PPA tuning)
    assign seg_out_n = segment_pattern;

endmodule

// ------------------------------------------------------------------
// Submodule: bin2sevenseg_decoder
// Function: Decodes 4-bit binary input to 7-segment active-low pattern
// Segments: {a,b,c,d,e,f,g}
// ------------------------------------------------------------------
module bin2sevenseg_decoder (
    input  wire [3:0] bin_in,
    output reg  [6:0] segment_pattern
);
    always @(*) begin
        if (bin_in == 4'h0) begin
            segment_pattern = 7'b0000001;  // 0
        end else if (bin_in == 4'h1) begin
            segment_pattern = 7'b1001111;  // 1
        end else if (bin_in == 4'h2) begin
            segment_pattern = 7'b0010010;  // 2
        end else if (bin_in == 4'h3) begin
            segment_pattern = 7'b0000110;  // 3
        end else if (bin_in == 4'h4) begin
            segment_pattern = 7'b1001100;  // 4
        end else begin
            segment_pattern = 7'b1111111;  // blank
        end
    end
endmodule