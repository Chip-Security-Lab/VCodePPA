//SystemVerilog
module ResetEdgeDetector (
    input wire clk,
    input wire rst_n,
    output reg reset_edge_detected
);
    reg rst_n_d;

    always @(posedge clk) begin
        rst_n_d <= rst_n;
        reset_edge_detected <= (~rst_n_d) & rst_n;
    end
endmodule