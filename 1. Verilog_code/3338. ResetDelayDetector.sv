module ResetDelayDetector #(
    parameter DELAY = 4
) (
    input wire clk,
    input wire rst_n,
    output wire reset_detected // 改为wire以匹配连续赋值
);
    reg [DELAY-1:0] shift_reg;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            shift_reg <= {DELAY{1'b1}};
        else
            shift_reg <= {shift_reg[DELAY-2:0], 1'b0};
    end
    
    assign reset_detected = shift_reg[DELAY-1];
endmodule