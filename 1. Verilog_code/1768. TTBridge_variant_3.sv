//SystemVerilog
module TTBridge_pipeline #(
    parameter SCHEDULE = 32'h0000_FFFF
)(
    input clk, rst_n,
    input [31:0] timestamp,
    output reg trigger
);
    reg [31:0] last_ts_stage1, last_ts_stage2;
    reg valid_stage1, valid_stage2;
    reg [31:0] timestamp_stage1;

    // Stage 1: Capture timestamp and check schedule
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            timestamp_stage1 <= 32'b0;
            valid_stage1 <= 1'b0;
        end else begin
            timestamp_stage1 <= timestamp;
            valid_stage1 <= (timestamp & SCHEDULE) ? 1'b1 : 1'b0;
        end
    end

    // Stage 2: Compute trigger condition
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            last_ts_stage1 <= 32'b0;
            valid_stage2 <= 1'b0;
            trigger <= 1'b0;
        end else begin
            if (valid_stage1) begin
                if ((timestamp_stage1 - last_ts_stage1) >= 100) begin
                    trigger <= 1'b1;
                    last_ts_stage1 <= timestamp_stage1;
                end else begin
                    trigger <= 1'b0;
                end
                valid_stage2 <= 1'b1;
            end else begin
                valid_stage2 <= 1'b0;
            end
        end
    end
endmodule