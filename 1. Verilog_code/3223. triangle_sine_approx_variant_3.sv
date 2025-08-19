//SystemVerilog
module triangle_sine_approx(
    input clk,
    input reset,
    output reg [7:0] sine_out
);
    reg [7:0] triangle;
    reg up_down;
    reg direction_change;
    
    // 处理复位逻辑
    always @(posedge clk) begin
        if (reset) begin
            triangle <= 8'd0;
            up_down <= 1'b1;
        end else if (direction_change) begin
            up_down <= ~up_down;
        end
    end
    
    // 检测方向变化条件
    always @(posedge clk) begin
        if (reset) begin
            direction_change <= 1'b0;
        end else begin
            direction_change <= (up_down && triangle == 8'd255) || 
                               (!up_down && triangle == 8'd0);
        end
    end
    
    // 三角波计数逻辑
    always @(posedge clk) begin
        if (reset) begin
            triangle <= 8'd0;
        end else if (!direction_change) begin
            if (up_down)
                triangle <= triangle + 8'd1;
            else
                triangle <= triangle - 8'd1;
        end
    end
    
    // 三角波到正弦波的变换 - 第一阶段
    reg [7:0] sine_base;
    reg [7:0] triangle_scaled;
    
    always @(posedge clk) begin
        case (triangle[7:6])
            2'b00: begin
                sine_base <= 8'd64;
                triangle_scaled <= triangle >> 1;
            end
            2'b01, 2'b10: begin
                sine_base <= 8'd96;
                triangle_scaled <= triangle >> 1;
            end
            2'b11: begin
                sine_base <= 8'd192;
                triangle_scaled <= triangle >> 2;
            end
        endcase
    end
    
    // 三角波到正弦波的变换 - 最终输出
    always @(posedge clk) begin
        sine_out <= sine_base + triangle_scaled;
    end
endmodule