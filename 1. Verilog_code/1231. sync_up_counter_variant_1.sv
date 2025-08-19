//SystemVerilog
module sync_counter_up (
    input clk,
    input reset,
    input enable,
    output reg [7:0] count
);
    reg enable_reg;
    wire [7:0] next_count;
    
    // 计算下一个计数值 - 优化的进位链逻辑
    assign next_count = count + 8'd1;

    // 简化的同步时序逻辑
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            count <= 8'b0;
            enable_reg <= 1'b0;
        end else begin
            enable_reg <= enable;
            if (enable_reg)
                count <= next_count;
        end
    end
endmodule