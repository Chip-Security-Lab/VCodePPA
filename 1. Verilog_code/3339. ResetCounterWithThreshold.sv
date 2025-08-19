module ResetCounterWithThreshold #(
    parameter THRESHOLD = 10
) (
    input wire clk,
    input wire rst_n,
    output wire reset_detected // 改为wire以匹配连续赋值
);
    reg [3:0] counter;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            counter <= 4'b0;
        else if (counter < THRESHOLD)
            counter <= counter + 1;
    end
    
    assign reset_detected = (counter >= THRESHOLD);
endmodule