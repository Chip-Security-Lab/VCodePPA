//SystemVerilog
module temp_compensated_codec (
    input clk, rst_n,
    input [7:0] r_in, g_in, b_in,
    input [7:0] temperature,
    input comp_enable,
    output reg [15:0] display_out
);
    // 温度补偿因子 - 根据温度范围计算
    reg [3:0] r_factor;
    reg [3:0] g_factor;
    reg [3:0] b_factor;
    
    // 调整后的RGB值
    reg [11:0] r_adj;
    reg [11:0] g_adj;
    reg [11:0] b_adj;
    
    // 第一个always块：计算温度补偿因子
    always @(*) begin
        // 红色通道温度补偿因子
        if (temperature > 8'd80)
            r_factor = 4'd12;
        else if (temperature > 8'd60)
            r_factor = 4'd13;
        else if (temperature > 8'd40)
            r_factor = 4'd14;
        else if (temperature > 8'd20)
            r_factor = 4'd15;
        else
            r_factor = 4'd15;
            
        // 绿色通道温度补偿因子
        if (temperature > 8'd80)
            g_factor = 4'd14;
        else if (temperature > 8'd60)
            g_factor = 4'd15;
        else if (temperature > 8'd40)
            g_factor = 4'd15;
        else if (temperature > 8'd20)
            g_factor = 4'd14;
        else
            g_factor = 4'd13;
            
        // 蓝色通道温度补偿因子
        if (temperature > 8'd80)
            b_factor = 4'd15;
        else if (temperature > 8'd60)
            b_factor = 4'd14;
        else if (temperature > 8'd40)
            b_factor = 4'd13;
        else if (temperature > 8'd20)
            b_factor = 4'd12;
        else
            b_factor = 4'd11;
    end
    
    // 第二个always块：应用温度补偿计算调整后的RGB值
    always @(*) begin
        if (comp_enable) begin
            r_adj = r_in * r_factor;
            g_adj = g_in * g_factor;
            b_adj = b_in * b_factor;
        end else begin
            r_adj = {r_in, 4'b0000};
            g_adj = {g_in, 4'b0000};
            b_adj = {b_in, 4'b0000};
        end
    end
    
    // 第三个always块：RGB转RGB565格式输出
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            display_out <= 16'h0000;
        else
            display_out <= {r_adj[11:7], g_adj[11:6], b_adj[11:7]};
    end
endmodule