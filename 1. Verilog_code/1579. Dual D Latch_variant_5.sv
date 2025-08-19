//SystemVerilog
// SystemVerilog

// Parameterized D-latch cell with power optimization
module d_latch_cell #(
    parameter POWER_OPTIMIZED = 1
) (
    input wire d,
    input wire latch_enable,
    output reg q
);
    // Use clock-gating style for power optimization when enabled
    always @* begin
        if (latch_enable)
            q = d;
    end
endmodule

// Dual D-latch module with parameterized width
module dual_d_latch #(
    parameter WIDTH = 2,
    parameter POWER_OPTIMIZED = 1
) (
    input wire [WIDTH-1:0] d_in,
    input wire latch_enable,
    output wire [WIDTH-1:0] q_out
);
    // Generate multiple latches based on parameterized width
    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : latch_instances
            d_latch_cell #(
                .POWER_OPTIMIZED(POWER_OPTIMIZED)
            ) latch_inst (
                .d(d_in[i]),
                .latch_enable(latch_enable),
                .q(q_out[i])
            );
        end
    endgenerate
endmodule

// Top-level module with additional control features
module latch_system #(
    parameter WIDTH = 2,
    parameter POWER_OPTIMIZED = 1
) (
    input wire [WIDTH-1:0] d_in,
    input wire latch_enable,
    input wire reset_n,
    output wire [WIDTH-1:0] q_out
);
    // Internal signals
    wire [WIDTH-1:0] internal_q;
    
    // Reset logic
    wire effective_enable = latch_enable & reset_n;
    
    // Instantiate the dual latch module
    dual_d_latch #(
        .WIDTH(WIDTH),
        .POWER_OPTIMIZED(POWER_OPTIMIZED)
    ) dual_latch_inst (
        .d_in(d_in),
        .latch_enable(effective_enable),
        .q_out(internal_q)
    );
    
    // Output assignment with reset handling
    assign q_out = reset_n ? internal_q : {WIDTH{1'b0}};
endmodule