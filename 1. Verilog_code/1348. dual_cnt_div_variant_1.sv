//SystemVerilog
module dual_cnt_div #(parameter DIV1=3, DIV2=5) (
    input clk, sel,
    output reg clk_out
);
    // 优化计数器位宽，根据参数动态决定
    localparam CNT1_WIDTH = $clog2(DIV1);
    localparam CNT2_WIDTH = $clog2(DIV2);
    
    reg [CNT1_WIDTH-1:0] cnt1;
    reg [CNT2_WIDTH-1:0] cnt2;
    
    // 预计算下一周期cnt值
    wire [CNT1_WIDTH-1:0] next_cnt1 = (cnt1 == DIV1-1) ? '0 : cnt1 + 1'b1;
    wire [CNT2_WIDTH-1:0] next_cnt2 = (cnt2 == DIV2-1) ? '0 : cnt2 + 1'b1;
    
    // 优化比较逻辑 - 直接检测零值，避免多重比较
    wire cnt1_zero = (next_cnt1 == '0);
    wire cnt2_zero = (next_cnt2 == '0);
    
    reg out_sel;
    
    always @(posedge clk) begin
        // 更新计数器
        cnt1 <= next_cnt1;
        cnt2 <= next_cnt2;
        
        // 缓存选择信号，降低扇出并改善时序
        out_sel <= sel;
        
        // 输出逻辑使用预计算的零值检测
        clk_out <= out_sel ? cnt2_zero : cnt1_zero;
    end
endmodule