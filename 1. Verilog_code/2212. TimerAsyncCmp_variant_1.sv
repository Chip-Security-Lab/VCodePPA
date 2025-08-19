//SystemVerilog
module TimerAsyncCmp #(parameter CMP_VAL=8'hFF) (
    input clk, rst_n,
    output reg timer_trigger
);
    reg [7:0] cnt;
    
    always @(posedge clk or negedge rst_n)
        if (!rst_n) cnt <= 8'h0;
        else cnt <= cnt + 8'h1;
    
    // 前向寄存器重定时：将比较器逻辑移到寄存器之前
    always @(posedge clk or negedge rst_n)
        if (!rst_n) timer_trigger <= 1'b0;
        else timer_trigger <= (cnt + 8'h1 == CMP_VAL);
        
endmodule