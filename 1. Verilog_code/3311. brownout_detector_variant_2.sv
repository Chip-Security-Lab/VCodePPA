//SystemVerilog
// Top-level brownout detector module with hierarchical structure (optimized)
module brownout_detector #(
    parameter LOW_THRESHOLD = 8'd85,
    parameter HIGH_THRESHOLD = 8'd95
)(
    input  wire        clk,
    input  wire        enable,
    input  wire [7:0]  supply_voltage,
    output reg         brownout_reset
);

    // Internal signal for brownout state
    wire next_brownout_state;
    wire current_brownout_state;

    // Brownout control logic submodule: Determines next brownout state
    brownout_ctrl #(
        .LOW_THRESHOLD(LOW_THRESHOLD),
        .HIGH_THRESHOLD(HIGH_THRESHOLD)
    ) u_brownout_ctrl (
        .enable              (enable),
        .supply_voltage      (supply_voltage),
        .brownout_state      (current_brownout_state),
        .brownout_next_state (next_brownout_state)
    );

    // Brownout state register submodule: Synchronizes state to clk
    brownout_state_reg u_brownout_state_reg (
        .clk                 (clk),
        .enable              (enable),
        .brownout_next_state (next_brownout_state),
        .brownout_q          (current_brownout_state)
    );

    // Output register for brownout reset (for timing optimization)
    always @(posedge clk) begin
        brownout_reset <= current_brownout_state;
    end

endmodule

//------------------------------------------------------------------------------
// brownout_ctrl (Optimized for balanced path and reduced logic depth)
//------------------------------------------------------------------------------
module brownout_ctrl #(
    parameter LOW_THRESHOLD = 8'd85,
    parameter HIGH_THRESHOLD = 8'd95
)(
    input  wire        enable,
    input  wire [7:0]  supply_voltage,
    input  wire        brownout_state,
    output wire        brownout_next_state
);

    // Precompute threshold comparisons
    wire is_below_low  = (supply_voltage < LOW_THRESHOLD);
    wire is_above_high = (supply_voltage > HIGH_THRESHOLD);

    // Balanced logic: combine conditions to minimize logic depth and balance path delay
    assign brownout_next_state =
        (!enable)          ? 1'b0 :
        is_below_low       ? 1'b1 :
        is_above_high      ? 1'b0 :
                             brownout_state;

endmodule

//------------------------------------------------------------------------------
// brownout_state_reg (Optimized for single-stage enable synchronization)
//------------------------------------------------------------------------------
module brownout_state_reg (
    input  wire clk,
    input  wire enable,
    input  wire brownout_next_state,
    output reg  brownout_q
);

    reg enable_sync;

    always @(posedge clk) begin
        enable_sync <= enable;
    end

    always @(posedge clk) begin
        if (!enable_sync)
            brownout_q <= 1'b0;
        else
            brownout_q <= brownout_next_state;
    end

endmodule