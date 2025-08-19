//SystemVerilog
module MultiResetDetector (
    input wire clk,
    input wire rst_n,
    input wire soft_rst,
    output reg reset_detected
);
    always @(posedge clk or negedge rst_n or negedge soft_rst) begin
        if (!rst_n || !soft_rst) begin
            reset_detected <= 1'b1;
        end else begin
            reset_detected <= 1'b0;
        end
    end
endmodule