//SystemVerilog
module ResetDetectorAsync (
    input wire clk,
    input wire rst_n,
    output reg reset_detected
);

    reg reset_n_stage1;
    reg reset_n_stage2;
    reg valid_stage1;
    reg valid_stage2;

    // Stage 1: Synchronize rst_n and generate valid signal
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            reset_n_stage1 <= 1'b0;
            valid_stage1 <= 1'b0;
        end else begin
            reset_n_stage1 <= rst_n;
            valid_stage1 <= 1'b1;
        end
    end

    // Stage 2: Detect reset and pipeline valid signal
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            reset_n_stage2 <= 1'b0;
            valid_stage2 <= 1'b0;
        end else begin
            reset_n_stage2 <= reset_n_stage1;
            valid_stage2 <= valid_stage1;
        end
    end

    // Output stage: Generate reset_detected based on pipelined signals
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            reset_detected <= 1'b1;
        end else if (valid_stage2) begin
            reset_detected <= ~reset_n_stage2;
        end else begin
            reset_detected <= 1'b0;
        end
    end

endmodule