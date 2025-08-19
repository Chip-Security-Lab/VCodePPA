//SystemVerilog
module ResetDetectorWithEnable (
    input wire clk,
    input wire rst_n,
    input wire enable,
    output reg reset_detected
);
    always @(posedge clk) begin
        if (!rst_n) begin
            reset_detected <= 1'b1;
        end else begin
            if (enable) begin
                reset_detected <= 1'b0;
            end else begin
                reset_detected <= reset_detected;
            end
        end
    end
endmodule