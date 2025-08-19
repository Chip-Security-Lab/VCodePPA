//SystemVerilog
// Top-level LFSR module with hierarchical submodules
module multi_bit_lfsr (
    input  wire        clk,
    input  wire        rst,
    output wire [19:0] rnd_out
);

    wire [19:0] lfsr_next;
    wire [19:0] lfsr_reg;

    // LFSR register logic
    lfsr_register #(
        .WIDTH(20),
        .RESET_VALUE(20'hFACEB)
    ) u_lfsr_register (
        .clk        (clk),
        .rst        (rst),
        .lfsr_next  (lfsr_next),
        .lfsr_reg   (lfsr_reg)
    );

    // LFSR taps and next-state logic
    lfsr_tap_logic #(
        .WIDTH(20)
    ) u_lfsr_tap_logic (
        .lfsr_in    (lfsr_reg),
        .lfsr_next  (lfsr_next)
    );

    assign rnd_out = lfsr_reg;

endmodule

// -----------------------------------------------------------------------------
// lfsr_register
// Purpose: Synchronous register for the LFSR state with parameterized width and reset value
// -----------------------------------------------------------------------------
module lfsr_register #(
    parameter WIDTH = 20,
    parameter RESET_VALUE = 20'hFACEB
) (
    input  wire             clk,
    input  wire             rst,
    input  wire [WIDTH-1:0] lfsr_next,
    output reg  [WIDTH-1:0] lfsr_reg
);
    always @(posedge clk) begin
        if (rst)
            lfsr_reg <= RESET_VALUE;
        else
            lfsr_reg <= lfsr_next;
    end
endmodule

// -----------------------------------------------------------------------------
// lfsr_tap_logic
// Purpose: Generates next LFSR state using tap logic (parameterized for width)
// -----------------------------------------------------------------------------
module lfsr_tap_logic #(
    parameter WIDTH = 20
) (
    input  wire [WIDTH-1:0] lfsr_in,
    output wire [WIDTH-1:0] lfsr_next
);
    wire [3:0] taps;

    // Tap positions for a 20-bit LFSR
    assign taps[0] = lfsr_in[19] ^ lfsr_in[16];
    assign taps[1] = lfsr_in[15] ^ lfsr_in[12];
    assign taps[2] = lfsr_in[11] ^ lfsr_in[8];
    assign taps[3] = lfsr_in[7]  ^ lfsr_in[0];

    // Concatenate taps to form next LFSR state
    assign lfsr_next = {lfsr_in[15:0], taps};
endmodule