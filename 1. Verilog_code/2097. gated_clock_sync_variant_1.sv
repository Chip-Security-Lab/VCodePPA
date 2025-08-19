//SystemVerilog
module gated_clock_sync_pipeline (
    input        src_clk,
    input        dst_gclk,
    input        rst,
    input        data_in,
    output reg   data_out
);

    // Stage 1: Capture input data_in on src_clk
    reg data_in_stage1;
    reg valid_stage1;

    always @(posedge src_clk or posedge rst) begin
        if (rst) begin
            data_in_stage1 <= 1'b0;
            valid_stage1   <= 1'b0;
        end else begin
            data_in_stage1 <= data_in;
            valid_stage1   <= 1'b1;
        end
    end

    // Stage 2: Synchronize to dst_gclk domain
    reg data_in_stage2;
    reg valid_stage2;

    always @(posedge dst_gclk or posedge rst) begin
        if (rst) begin
            data_in_stage2 <= 1'b0;
            valid_stage2   <= 1'b0;
        end else begin
            data_in_stage2 <= data_in_stage1;
            valid_stage2   <= valid_stage1;
        end
    end

    // Stage 3: Output register
    reg data_in_stage3;
    reg valid_stage3;

    always @(posedge dst_gclk or posedge rst) begin
        if (rst) begin
            data_in_stage3 <= 1'b0;
            valid_stage3   <= 1'b0;
        end else begin
            data_in_stage3 <= data_in_stage2;
            valid_stage3   <= valid_stage2;
        end
    end

    // Output logic with valid control
    always @(posedge dst_gclk or posedge rst) begin
        if (rst) begin
            data_out <= 1'b0;
        end else if (valid_stage3) begin
            data_out <= data_in_stage3;
        end
    end

endmodule