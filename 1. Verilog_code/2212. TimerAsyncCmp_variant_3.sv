//SystemVerilog
module TimerAsyncCmp #(parameter CMP_VAL=8'hFF) (
    input clk, rst_n,
    output reg timer_trigger
);

    reg [7:0] cnt;
    wire comparison_result;
    
    // 优化后的计数器和触发器逻辑，合并处理
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cnt <= 8'h0;
            timer_trigger <= 1'b0;
        end else begin
            cnt <= cnt + 8'h1;
            timer_trigger <= (cnt == CMP_VAL);
        end
    end

endmodule