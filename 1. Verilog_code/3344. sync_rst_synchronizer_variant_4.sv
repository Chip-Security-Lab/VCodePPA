//SystemVerilog
module sync_rst_synchronizer (
    input  wire clock,
    input  wire async_reset,
    input  wire sync_reset,
    output reg  reset_out
);
    // Stage 1: Capture async_reset or set by sync_reset
    reg meta_stage1;
    reg valid_stage1;

    // Stage 2: Output register stage
    reg meta_stage2;
    reg valid_stage2;

    // Pipeline flush logic
    wire pipeline_flush = sync_reset;

    always @(posedge clock) begin
        if (pipeline_flush) begin
            meta_stage1  <= 1'b1;
            valid_stage1 <= 1'b1;
        end else begin
            meta_stage1  <= async_reset;
            valid_stage1 <= 1'b1;
        end
    end

    always @(posedge clock) begin
        if (pipeline_flush) begin
            meta_stage2  <= 1'b1;
            valid_stage2 <= 1'b1;
        end else begin
            meta_stage2  <= meta_stage1;
            valid_stage2 <= valid_stage1;
        end
    end

    always @(posedge clock) begin
        if (pipeline_flush) begin
            reset_out <= 1'b1;
        end else begin
            reset_out <= meta_stage2;
        end
    end
endmodule