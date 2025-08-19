module ResetDetectorWithEnable (
    input wire clk,
    input wire rst_n,
    input wire enable,
    output reg reset_detected
);
    always @(posedge clk) begin
        if (!rst_n)
            reset_detected <= 1'b1;
        else if (enable)
            reset_detected <= 1'b0;
    end
endmodule
