//SystemVerilog
module multimod_divider (
    input CLK_IN, RST, ENABLE,
    input [2:0] DIV_SEL,
    output reg CLK_OUT
);
    reg [3:0] counter;
    wire [3:0] div_value;
    
    // 为高扇出信号DIV_SEL添加缓冲寄存器
    reg [2:0] div_sel_buf1, div_sel_buf2;
    
    // 将DIV_SEL信号负载分为两组，分别驱动
    always @(posedge CLK_IN or posedge RST) begin
        if (RST) begin
            div_sel_buf1 <= 3'd0;
            div_sel_buf2 <= 3'd0;
        end else begin
            div_sel_buf1 <= DIV_SEL;
            div_sel_buf2 <= DIV_SEL;
        end
    end
    
    // 使用缓冲后的信号进行分支逻辑解码
    wire is_div1 = (div_sel_buf1 == 3'd0);
    wire is_div2 = (div_sel_buf1 == 3'd1);
    wire is_div4 = (div_sel_buf2 == 3'd2);
    wire is_div8 = (div_sel_buf2 == 3'd3);
    wire is_div16 = !is_div1 && !is_div2 && !is_div4 && !is_div8;
    
    // 根据解码结果选择分频值
    assign div_value = is_div1 ? 4'd1 :
                      is_div2 ? 4'd2 :
                      is_div4 ? 4'd4 :
                      is_div8 ? 4'd8 : 4'd16;
    
    always @(posedge CLK_IN or posedge RST) begin
        if (RST) begin
            counter <= 4'd0;
            CLK_OUT <= 1'b0;
        end else if (ENABLE) begin
            if (counter >= div_value-1) begin
                counter <= 4'd0;
                CLK_OUT <= ~CLK_OUT;
            end else
                counter <= counter + 1'b1;
        end
    end
endmodule