//SystemVerilog
module async_rst_sync_pipeline #(parameter CH=2) (
    input                   clk,
    input                   async_rst,
    input                   start,
    input                   flush,
    input      [CH-1:0]     ch_in,
    output reg [CH-1:0]     ch_out,
    output reg              valid_out
);

    // Stage 1 registers and valid
    reg [CH-1:0] ch_in_stage1;
    reg          valid_stage1;

    // Stage 2 registers and valid
    reg [CH-1:0] ch_in_stage2;
    reg          valid_stage2;

    // Stage 3 registers and valid
    reg [CH-1:0] ch_in_stage3;
    reg          valid_stage3;

    // Stage 1: Capture input
    always @(posedge clk or posedge async_rst) begin
        if (async_rst) begin
            ch_in_stage1   <= {CH{1'b0}};
            valid_stage1   <= 1'b0;
        end else if (flush) begin
            ch_in_stage1   <= {CH{1'b0}};
            valid_stage1   <= 1'b0;
        end else if (start) begin
            ch_in_stage1   <= ch_in;
            valid_stage1   <= 1'b1;
        end else begin
            valid_stage1   <= 1'b0;
        end
    end

    // Stage 2: First synchronization register
    always @(posedge clk or posedge async_rst) begin
        if (async_rst) begin
            ch_in_stage2   <= {CH{1'b0}};
            valid_stage2   <= 1'b0;
        end else if (flush) begin
            ch_in_stage2   <= {CH{1'b0}};
            valid_stage2   <= 1'b0;
        end else begin
            ch_in_stage2   <= ch_in_stage1;
            valid_stage2   <= valid_stage1;
        end
    end

    // Stage 3: Second synchronization register
    always @(posedge clk or posedge async_rst) begin
        if (async_rst) begin
            ch_in_stage3   <= {CH{1'b0}};
            valid_stage3   <= 1'b0;
        end else if (flush) begin
            ch_in_stage3   <= {CH{1'b0}};
            valid_stage3   <= 1'b0;
        end else begin
            ch_in_stage3   <= ch_in_stage2;
            valid_stage3   <= valid_stage2;
        end
    end

    // Output logic
    always @(posedge clk or posedge async_rst) begin
        if (async_rst) begin
            ch_out     <= {CH{1'b0}};
            valid_out  <= 1'b0;
        end else if (flush) begin
            ch_out     <= {CH{1'b0}};
            valid_out  <= 1'b0;
        end else begin
            ch_out     <= ch_in_stage3;
            valid_out  <= valid_stage3;
        end
    end

endmodule