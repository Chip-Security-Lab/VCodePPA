//SystemVerilog
module gated_clock_sync (
    input  wire src_clk,
    input  wire dst_gclk,
    input  wire rst,
    input  wire data_in,
    output reg  data_out
);

    // Pipeline stage 1: input capture and valid
    reg data_in_stage1;
    reg valid_stage1;

    // Pipeline stage 2: synchronization and valid
    reg data_in_stage2;
    reg valid_stage2;

    // Pipeline stage 3: output register and valid
    reg data_in_stage3;
    reg valid_stage3;

    // Flush logic (reset clears pipeline)
    always @(posedge dst_gclk or posedge rst) begin
        if (rst) begin
            data_in_stage1 <= 1'b0;
            valid_stage1   <= 1'b0;
        end else begin
            data_in_stage1 <= data_in;
            valid_stage1   <= 1'b1;
        end
    end

    always @(posedge dst_gclk or posedge rst) begin
        if (rst) begin
            data_in_stage2 <= 1'b0;
            valid_stage2   <= 1'b0;
        end else begin
            data_in_stage2 <= data_in_stage1;
            valid_stage2   <= valid_stage1;
        end
    end

    always @(posedge dst_gclk or posedge rst) begin
        if (rst) begin
            data_in_stage3 <= 1'b0;
            valid_stage3   <= 1'b0;
        end else begin
            data_in_stage3 <= data_in_stage2;
            valid_stage3   <= valid_stage2;
        end
    end

    always @(posedge dst_gclk or posedge rst) begin
        if (rst) begin
            data_out <= 1'b0;
        end else if (valid_stage3) begin
            data_out <= data_in_stage3;
        end
    end

endmodule