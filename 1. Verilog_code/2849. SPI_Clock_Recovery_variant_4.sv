//SystemVerilog
`timescale 1ns/1ps
module SPI_Clock_Recovery #(
    parameter OVERSAMPLE = 8
)(
    input  wire        async_clk,
    input  wire        sdi,
    output reg         recovered_clk,
    output reg  [7:0]  data_out
);

//----------------------------------------------------------------------
// Stage 1: SDI Input Sampling Pipeline
//----------------------------------------------------------------------

reg  [2:0] sdi_sample_pipeline;    // Pipeline for SDI input sampling

always @(posedge async_clk) begin
    sdi_sample_pipeline <= {sdi_sample_pipeline[1:0], sdi};
end

wire sdi_sampled_stage1 = sdi_sample_pipeline[1];
wire sdi_sampled_stage2 = sdi_sample_pipeline[2];

//----------------------------------------------------------------------
// Stage 2: Edge Detection
//----------------------------------------------------------------------

reg  edge_detected_stage1;
always @(posedge async_clk) begin
    edge_detected_stage1 <= sdi_sampled_stage2 ^ sdi_sampled_stage1;
end

//----------------------------------------------------------------------
// Stage 3: Edge Counter Pipeline
//----------------------------------------------------------------------

reg  [3:0] edge_counter_stage1;
reg  [3:0] edge_counter_stage2;

wire edge_counter_max_stage1  = (edge_counter_stage1 == (OVERSAMPLE-1));
wire edge_counter_half_stage1 = (edge_counter_stage1 < (OVERSAMPLE >> 1));

wire [3:0] edge_counter_next_stage1 = edge_detected_stage1 ? (OVERSAMPLE >> 1) :
                                      edge_counter_max_stage1 ? 4'd0 :
                                      edge_counter_stage1 + 1;

always @(posedge async_clk) begin
    edge_counter_stage1 <= edge_counter_next_stage1;
    edge_counter_stage2 <= edge_counter_stage1;
end

//----------------------------------------------------------------------
// Stage 4: Recovered Clock Generation Pipeline
//----------------------------------------------------------------------

reg recovered_clk_stage1;
reg recovered_clk_stage2;

wire recovered_clk_next_stage1 = edge_detected_stage1 ? 1'b0 :
                                 edge_counter_max_stage1 ? 1'b1 :
                                 edge_counter_half_stage1;

always @(posedge async_clk) begin
    recovered_clk_stage1 <= recovered_clk_next_stage1;
    recovered_clk_stage2 <= recovered_clk_stage1;
    recovered_clk        <= recovered_clk_stage2;
end

//----------------------------------------------------------------------
// Stage 5: Shift Register Pipeline
//----------------------------------------------------------------------

reg [7:0] shift_register_stage1;
reg [7:0] shift_register_stage2;

always @(posedge async_clk) begin
    if (recovered_clk_stage2) begin
        shift_register_stage1 <= {shift_register_stage1[6:0], sdi_sampled_stage2};
    end
end

always @(posedge async_clk) begin
    shift_register_stage2 <= shift_register_stage1;
end

//----------------------------------------------------------------------
// Stage 6: Output Register
//----------------------------------------------------------------------

always @(posedge async_clk) begin
    data_out <= shift_register_stage2;
end

//----------------------------------------------------------------------
// Initialization (IEEE 1364-2005 compliant)
//----------------------------------------------------------------------

initial begin
    sdi_sample_pipeline   = 3'b000;
    edge_detected_stage1  = 1'b0;
    edge_counter_stage1   = 4'h0;
    edge_counter_stage2   = 4'h0;
    recovered_clk_stage1  = 1'b0;
    recovered_clk_stage2  = 1'b0;
    recovered_clk         = 1'b0;
    shift_register_stage1 = 8'h00;
    shift_register_stage2 = 8'h00;
    data_out              = 8'h00;
end

endmodule