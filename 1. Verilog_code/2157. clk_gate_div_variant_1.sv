//SystemVerilog
module clk_gate_div #(
    parameter DIV = 2
)(
    input  wire clk,
    input  wire en,
    output reg  clk_out
);

    // 使用恰当的位宽，避免不必要的资源浪费
    // 计算所需的位宽以容纳DIV值
    localparam CNT_WIDTH = $clog2(DIV);
    reg [CNT_WIDTH-1:0] cnt;
    
    // 初始值设定
    initial begin
        cnt = {CNT_WIDTH{1'b0}};
        clk_out = 1'b0;
    end
    
    wire cnt_max = (cnt == DIV-1);
    wire cnt_zero = (cnt == {CNT_WIDTH{1'b0}});
    
    always @(posedge clk) begin
        if (en) begin
            // 使用预计算的比较信号，减少关键路径延迟
            cnt <= cnt_max ? {CNT_WIDTH{1'b0}} : cnt + 1'b1;
            
            // 通过条件优化触发时钟反转的逻辑
            if (cnt_max || (DIV == 2 && cnt_zero)) begin
                clk_out <= ~clk_out;
            end
        end
    end

endmodule