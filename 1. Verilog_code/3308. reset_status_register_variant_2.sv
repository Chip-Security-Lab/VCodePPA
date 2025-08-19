//SystemVerilog
// Top-level Module: Hierarchically structured reset status register
module reset_status_register(
    input             clk,
    input             global_rst_n,
    input      [5:0]  reset_inputs_n,   // Active low inputs
    input      [5:0]  status_clear,     // Clear individual bits
    output reg [5:0]  reset_status
);

    // Stage 1: Registers for active resets and previous resets
    wire [5:0] active_resets_stage1;
    wire [5:0] prev_resets_stage1;

    reset_pipeline_stage1 u_stage1 (
        .clk                (clk),
        .global_rst_n       (global_rst_n),
        .reset_inputs_n     (reset_inputs_n),
        .active_resets_out  (active_resets_stage1),
        .prev_resets_out    (prev_resets_stage1)
    );

    // Stage 2: Registers for new reset event and status_clear
    wire [5:0] new_reset_event_stage2;
    wire [5:0] status_clear_stage2;

    reset_pipeline_stage2 u_stage2 (
        .clk                  (clk),
        .global_rst_n         (global_rst_n),
        .active_resets_in     (active_resets_stage1),
        .prev_resets_in       (prev_resets_stage1),
        .status_clear_in      (status_clear),
        .new_reset_event_out  (new_reset_event_stage2),
        .status_clear_out     (status_clear_stage2)
    );

    // Stage 3: Final status register update
    reset_status_update u_status_update (
        .clk                 (clk),
        .global_rst_n        (global_rst_n),
        .new_reset_event_in  (new_reset_event_stage2),
        .status_clear_in     (status_clear_stage2),
        .reset_status_out    (reset_status)
    );

endmodule

//------------------------------------------------------------------------------
// Submodule: reset_pipeline_stage1
// Description: Registers the current and previous active reset signals.
//------------------------------------------------------------------------------
module reset_pipeline_stage1(
    input            clk,
    input            global_rst_n,
    input  [5:0]     reset_inputs_n,
    output reg [5:0] active_resets_out,
    output reg [5:0] prev_resets_out
);
    always @(posedge clk or negedge global_rst_n) begin
        if (!global_rst_n) begin
            active_resets_out <= 6'b0;
            prev_resets_out   <= 6'b0;
        end else begin
            active_resets_out <= ~reset_inputs_n;
            prev_resets_out   <= active_resets_out;
        end
    end
endmodule

//------------------------------------------------------------------------------
// Submodule: reset_pipeline_stage2
// Description: Detects new reset events and registers the status_clear signal.
//------------------------------------------------------------------------------
module reset_pipeline_stage2(
    input            clk,
    input            global_rst_n,
    input  [5:0]     active_resets_in,
    input  [5:0]     prev_resets_in,
    input  [5:0]     status_clear_in,
    output reg [5:0] new_reset_event_out,
    output reg [5:0] status_clear_out
);
    always @(posedge clk or negedge global_rst_n) begin
        if (!global_rst_n) begin
            new_reset_event_out <= 6'b0;
            status_clear_out    <= 6'b0;
        end else begin
            new_reset_event_out <= active_resets_in & ~prev_resets_in;
            status_clear_out    <= status_clear_in;
        end
    end
endmodule

//------------------------------------------------------------------------------
// Submodule: reset_status_update
// Description: Updates the reset_status register based on new reset events and clear signals.
//------------------------------------------------------------------------------
module reset_status_update(
    input            clk,
    input            global_rst_n,
    input  [5:0]     new_reset_event_in,
    input  [5:0]     status_clear_in,
    output reg [5:0] reset_status_out
);
    always @(posedge clk or negedge global_rst_n) begin
        if (!global_rst_n) begin
            reset_status_out <= 6'b0;
        end else begin
            reset_status_out <= (reset_status_out | new_reset_event_in) & ~status_clear_in;
        end
    end
endmodule