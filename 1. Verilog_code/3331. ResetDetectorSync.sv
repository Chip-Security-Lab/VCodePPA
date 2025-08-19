module ResetDetectorSync (
    input wire clk,
    input wire rst_n,
    output reg reset_detected
);
    always @(posedge clk) begin
        if (!rst_n)
            reset_detected <= 1'b1;
        else
            reset_detected <= 1'b0;
    end
endmodule
