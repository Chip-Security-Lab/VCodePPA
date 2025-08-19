//SystemVerilog
module ResetEdgeDetector_Pipelined (
    input wire clk,
    input wire rst_n,
    output reg reset_edge_detected
);

    // Optimized single-stage synchronizer and edge detector
    reg rst_n_sync_0, rst_n_sync_1;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rst_n_sync_0 <= 1'b0;
            rst_n_sync_1 <= 1'b0;
        end else begin
            rst_n_sync_0 <= rst_n;
            rst_n_sync_1 <= rst_n_sync_0;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            reset_edge_detected <= 1'b0;
        end else begin
            // Detect rising edge of rst_n signal (from 0 to 1)
            reset_edge_detected <= rst_n_sync_0 & ~rst_n_sync_1;
        end
    end

endmodule