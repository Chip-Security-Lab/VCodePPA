module level2pulse_converter (
    input  wire clk_i,
    input  wire rst_i,  // Active high reset
    input  wire level_i,
    output reg  pulse_o
);
    reg level_r;
    
    always @(posedge clk_i) begin
        if (rst_i) begin
            level_r <= 1'b0;
            pulse_o <= 1'b0;
        end else begin
            level_r <= level_i;
            pulse_o <= level_i & ~level_r;  // Rising edge detection
        end
    end
endmodule