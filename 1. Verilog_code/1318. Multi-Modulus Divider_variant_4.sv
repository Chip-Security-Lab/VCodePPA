//SystemVerilog
module multimod_divider (
    input CLK_IN, RST, ENABLE,
    input [2:0] DIV_SEL,
    output reg CLK_OUT
);
    reg [3:0] counter;
    reg [3:0] div_value;
    
    // 预解码分频值 - 使用if-else级联结构
    always @(*) begin
        if (DIV_SEL == 3'd0) begin
            div_value = 4'd1;
        end else if (DIV_SEL == 3'd1) begin
            div_value = 4'd2;
        end else if (DIV_SEL == 3'd2) begin
            div_value = 4'd4;
        end else if (DIV_SEL == 3'd3) begin
            div_value = 4'd8;
        end else begin
            div_value = 4'd16;
        end
    end
    
    // 计算终止计数值
    wire counter_max;
    assign counter_max = (counter == (div_value - 1'b1));
    
    // 计数器控制逻辑
    always @(posedge CLK_IN or posedge RST) begin
        if (RST) begin
            counter <= 4'd0;
        end else if (ENABLE) begin
            if (counter_max) begin
                counter <= 4'd0;
            end else begin
                counter <= counter + 1'b1;
            end
        end
    end
    
    // 输出时钟控制逻辑
    always @(posedge CLK_IN or posedge RST) begin
        if (RST) begin
            CLK_OUT <= 1'b0;
        end else if (ENABLE && counter_max) begin
            CLK_OUT <= ~CLK_OUT;
        end
    end
endmodule