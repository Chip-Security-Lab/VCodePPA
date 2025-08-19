module IVMU_ReqQueue #(parameter DEPTH=4) (
    input clk, rd_en,
    input [7:0] irq,
    output reg [7:0] next_irq
);
    reg [7:0] queue [0:DEPTH-1];
    integer i;
    
    always @(posedge clk) begin
        if (rd_en) begin
            // 移动队列
            for (i = 0; i < DEPTH-1; i = i + 1) begin
                queue[i] <= queue[i+1];
            end
            queue[DEPTH-1] <= 8'h0;
        end else begin
            // 添加新中断
            for (i = DEPTH-1; i > 0; i = i - 1) begin
                queue[i] <= queue[i-1];
            end
            queue[0] <= irq;
        end
        next_irq <= queue[0];
    end
endmodule