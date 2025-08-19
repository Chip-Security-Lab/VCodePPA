//SystemVerilog
// Top-level triple-flop synchronizer with hierarchical structure

module triple_flop_sync #(
    parameter DW = 16
)(
    input  wire              dest_clock,
    input  wire              reset,
    input  wire              enable,
    input  wire [DW-1:0]     async_data,
    output wire [DW-1:0]     sync_data
);

    // Internal signals for inter-stage connections
    wire [DW-1:0] stage1_data;
    wire [DW-1:0] stage2_data;

    // Stage 1: Synchronize async_data into stage1_data
    sync_stage #(
        .DW(DW)
    ) sync_stage_0 (
        .clk(dest_clock),
        .rst(reset),
        .en(enable),
        .d_in(async_data),
        .d_out(stage1_data)
    );

    // Stage 2: Synchronize stage1_data into stage2_data
    sync_stage #(
        .DW(DW)
    ) sync_stage_1 (
        .clk(dest_clock),
        .rst(reset),
        .en(enable),
        .d_in(stage1_data),
        .d_out(stage2_data)
    );

    // Stage 3: Synchronize stage2_data into sync_data_reg
    sync_stage #(
        .DW(DW)
    ) sync_stage_2 (
        .clk(dest_clock),
        .rst(reset),
        .en(enable),
        .d_in(stage2_data),
        .d_out(sync_data_internal)
    );

    // Output register: Holds synchronized output
    sync_output_reg #(
        .DW(DW)
    ) sync_output_reg_inst (
        .clk(dest_clock),
        .rst(reset),
        .en(enable),
        .d_in(sync_data_internal),
        .d_out(sync_data)
    );

endmodule

// --------------------------------------------------------------------
// sync_stage: Single-stage synchronizer flip-flop bank
// --------------------------------------------------------------------
module sync_stage #(
    parameter DW = 16
)(
    input  wire           clk,
    input  wire           rst,
    input  wire           en,
    input  wire [DW-1:0]  d_in,
    output reg  [DW-1:0]  d_out
);
    // Synchronize input data to output with reset and enable
    always @(posedge clk) begin
        if (rst)
            d_out <= {DW{1'b0}};
        else if (en)
            d_out <= d_in;
    end
endmodule

// --------------------------------------------------------------------
// sync_output_reg: Output register for final synchronized data
// --------------------------------------------------------------------
module sync_output_reg #(
    parameter DW = 16
)(
    input  wire           clk,
    input  wire           rst,
    input  wire           en,
    input  wire [DW-1:0]  d_in,
    output reg  [DW-1:0]  d_out
);
    // Output register with reset and enable
    always @(posedge clk) begin
        if (rst)
            d_out <= {DW{1'b0}};
        else if (en)
            d_out <= d_in;
    end
endmodule