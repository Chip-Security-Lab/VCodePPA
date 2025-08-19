module MultiResetDetector (
    input wire clk,
    input wire rst_n,
    input wire soft_rst,
    output reg reset_detected
);
    always @(posedge clk or negedge rst_n or negedge soft_rst) begin
        if (!rst_n || !soft_rst)
            reset_detected <= 1'b1;
        else
            reset_detected <= 1'b0;
    end
endmodule
