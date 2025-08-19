//SystemVerilog
module TimerAsyncCmp #(parameter CMP_VAL=8'hFF) (
    input clk, rst_n,
    output reg timer_trigger
);
    reg [7:0] cnt;
    
    always @(posedge clk or negedge rst_n)
        if (!rst_n) cnt <= 0;
        else cnt <= cnt + 1;
    
    always @(posedge clk or negedge rst_n)
        if (!rst_n) timer_trigger <= 0;
        else timer_trigger <= (cnt == (CMP_VAL - 1'b1));
endmodule