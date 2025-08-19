//SystemVerilog
module ResetEdgeDetector (
    input  wire clk,
    input  wire rst_n,
    output reg  reset_edge_detected
);

    // Stage 1: Sample rst_n
    reg rst_n_stage1;
    reg valid_stage1;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rst_n_stage1 <= 1'b0;
            valid_stage1 <= 1'b0;
        end else begin
            rst_n_stage1 <= rst_n;
            valid_stage1 <= 1'b1;
        end
    end

    // Stage 2: Delay rst_n and generate edge detect
    reg rst_n_stage2;
    reg valid_stage2;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rst_n_stage2 <= 1'b0;
            valid_stage2 <= 1'b0;
        end else begin
            rst_n_stage2 <= rst_n_stage1;
            valid_stage2 <= valid_stage1;
        end
    end

    // Stage 3: Compute edge detection using pipeline registers
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            reset_edge_detected <= 1'b0;
        end else if (valid_stage2) begin
            reset_edge_detected <= rst_n_stage2 & ~rst_n_stage1;
        end else begin
            reset_edge_detected <= 1'b0;
        end
    end

endmodule