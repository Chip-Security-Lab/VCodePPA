//SystemVerilog
module lcg_rng (
    input  wire        clock,
    input  wire        reset,
    output wire [31:0] random_number
);

    reg [31:0] lcg_state_reg;
    wire [31:0] lcg_next_state;

    // Optimized LCG update logic (inlined, avoids module hierarchy and extra wire delays)
    localparam [31:0] LCG_A = 32'd1664525;
    localparam [31:0] LCG_C = 32'd1013904223;

    assign lcg_next_state = (LCG_A * lcg_state_reg) + LCG_C;

    always @(posedge clock) begin
        if (reset)
            lcg_state_reg <= 32'd123456789;
        else
            lcg_state_reg <= lcg_next_state;
    end

    assign random_number = lcg_state_reg;

endmodule