//SystemVerilog
module sync_2ff_en_pipeline #(parameter DW=8) (
    input  wire              src_clk,
    input  wire              dst_clk,
    input  wire              rst_n,
    input  wire              en,
    input  wire [DW-1:0]     async_in,
    output reg  [DW-1:0]     synced_out
);

    // Pipeline Stage 1: First synchronizer flip-flop
    reg [DW-1:0] sync_ff_stage1;
    reg          valid_stage1;

    // Pipeline Stage 2: Second synchronizer flip-flop
    reg [DW-1:0] sync_ff_stage2;
    reg          valid_stage2;

    // Pipeline Stage 3: Output register
    reg [DW-1:0] synced_out_stage3;
    reg          valid_stage3;

    // Pipeline control: propagate enable as valid signal
    always @(posedge dst_clk or negedge rst_n) begin
        if (!rst_n) begin
            sync_ff_stage1   <= {DW{1'b0}};
            valid_stage1     <= 1'b0;
        end else if (en) begin
            sync_ff_stage1   <= async_in;
            valid_stage1     <= 1'b1;
        end else begin
            sync_ff_stage1   <= sync_ff_stage1;
            valid_stage1     <= 1'b0;
        end
    end

    always @(posedge dst_clk or negedge rst_n) begin
        if (!rst_n) begin
            sync_ff_stage2   <= {DW{1'b0}};
            valid_stage2     <= 1'b0;
        end else begin
            sync_ff_stage2   <= sync_ff_stage1;
            valid_stage2     <= valid_stage1;
        end
    end

    always @(posedge dst_clk or negedge rst_n) begin
        if (!rst_n) begin
            synced_out_stage3 <= {DW{1'b0}};
            valid_stage3      <= 1'b0;
        end else begin
            synced_out_stage3 <= sync_ff_stage2;
            valid_stage3      <= valid_stage2;
        end
    end

    // Output assignment
    always @(posedge dst_clk or negedge rst_n) begin
        if (!rst_n) begin
            synced_out <= {DW{1'b0}};
        end else if (valid_stage3) begin
            synced_out <= synced_out_stage3;
        end
    end

endmodule