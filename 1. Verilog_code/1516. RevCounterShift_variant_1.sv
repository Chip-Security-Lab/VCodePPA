//SystemVerilog
// IEEE 1364-2005 Verilog
module RevCounterShift #(parameter N=4) (
    input clk, up_down, load, 
    input [N-1:0] preset,
    output reg [N-1:0] cnt
);
    // Intermediate register to hold input signals
    reg load_r, up_down_r;
    reg [N-1:0] preset_r;
    
    // Register input signals to reduce input-to-register delay
    always @(posedge clk) begin
        load_r <= load;
        up_down_r <= up_down;
        preset_r <= preset;
    end
    
    // Main counter logic with registers pushed forward
    always @(posedge clk) begin
        cnt <= load_r ? preset_r : 
              up_down_r ? {cnt[N-2:0], cnt[N-1]} : // 上移模式
                         {cnt[0], cnt[N-1:1]};    // 下移模式
    end
endmodule