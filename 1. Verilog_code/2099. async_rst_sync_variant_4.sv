//SystemVerilog
module async_rst_sync_pipeline #(parameter CH=2) (
    input                   clk,
    input                   async_rst,
    input                   valid_in,
    input  [CH-1:0]         ch_in,
    output                  valid_out,
    output [CH-1:0]         ch_out
);
    // Stage 1: First synchronizer register
    reg [CH-1:0] sync_stage1_reg;
    reg          valid_stage1_reg;

    // Stage 2: Second synchronizer register (moved before combination logic)
    reg [CH-1:0] sync_stage2_reg;
    reg          valid_stage2_reg;

    // Output logic
    wire [CH-1:0] ch_out_comb;
    wire          valid_out_comb;

    // Move the second register before combination logic
    always @(posedge clk or posedge async_rst) begin
        if (async_rst) begin
            sync_stage2_reg   <= {CH{1'b0}};
            valid_stage2_reg  <= 1'b0;
        end else begin
            sync_stage2_reg   <= ch_in;
            valid_stage2_reg  <= valid_in;
        end
    end

    always @(posedge clk or posedge async_rst) begin
        if (async_rst) begin
            sync_stage1_reg   <= {CH{1'b0}};
            valid_stage1_reg  <= 1'b0;
        end else begin
            sync_stage1_reg   <= sync_stage2_reg;
            valid_stage1_reg  <= valid_stage2_reg;
        end
    end

    assign ch_out   = sync_stage1_reg;
    assign valid_out = valid_stage1_reg;

endmodule