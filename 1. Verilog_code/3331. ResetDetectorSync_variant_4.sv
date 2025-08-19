//SystemVerilog
module ResetDetectorSync_Pipelined (
    input wire clk,
    input wire rst_n,
    output reg reset_detected
);

    // Pipeline stage 1: Sample rst_n and generate valid signal
    reg rst_n_stage1;
    reg valid_stage1;

    // Pipeline stage 2: Generate reset_detected output
    reg reset_detected_stage2;
    reg valid_stage2;

    // Stage 1: Register input and valid
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rst_n_stage1   <= 1'b0;
            valid_stage1   <= 1'b0;
        end else begin
            rst_n_stage1   <= rst_n;
            valid_stage1   <= 1'b1;
        end
    end

    // Stage 2: Register output and valid
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            reset_detected_stage2 <= 1'b1;
            valid_stage2          <= 1'b0;
        end else begin
            reset_detected_stage2 <= ~rst_n_stage1;
            valid_stage2          <= valid_stage1;
        end
    end

    // Output register
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            reset_detected <= 1'b1;
        end else if (valid_stage2) begin
            reset_detected <= reset_detected_stage2;
        end
    end

endmodule