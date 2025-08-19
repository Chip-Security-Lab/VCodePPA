//SystemVerilog
module variable_slope_triangle(
    input clk_in,
    input reset,
    input req,
    input [7:0] up_slope_rate,
    input [7:0] down_slope_rate,
    output reg [7:0] triangle_out,
    output reg ack
);
    reg direction;  // 0 = up, 1 = down
    reg [7:0] counter;
    wire up_condition;
    wire down_condition;
    wire max_reached;
    wire min_reached;
    reg req_reg;
    reg processing;
    
    assign up_condition = !direction && (counter >= up_slope_rate);
    assign down_condition = direction && (counter >= down_slope_rate);
    assign max_reached = (triangle_out == 8'hff);
    assign min_reached = (triangle_out == 8'h00);
    
    // 请求边沿检测
    always @(posedge clk_in) begin
        if (reset)
            req_reg <= 1'b0;
        else
            req_reg <= req;
    end
    
    // 主状态逻辑
    always @(posedge clk_in) begin
        if (reset) begin
            triangle_out <= 8'b0;
            direction <= 1'b0;
            counter <= 8'b0;
            ack <= 1'b0;
            processing <= 1'b0;
        end else begin
            // 新请求到达
            if (req && !req_reg && !processing) begin
                processing <= 1'b1;
                ack <= 1'b0;
            end
            
            // 处理过程
            if (processing) begin
                counter <= counter + 8'b1;
                
                if (up_condition) begin
                    counter <= 8'b0;
                    direction <= max_reached ? 1'b1 : direction;
                    triangle_out <= max_reached ? triangle_out : triangle_out + 8'b1;
                    ack <= 1'b1;  // 操作完成，发送应答
                    processing <= 1'b0;
                end else if (down_condition) begin
                    counter <= 8'b0;
                    direction <= min_reached ? 1'b0 : direction;
                    triangle_out <= min_reached ? triangle_out : triangle_out - 8'b1;
                    ack <= 1'b1;  // 操作完成，发送应答
                    processing <= 1'b0;
                end
            end
            
            // 当请求撤销时，重置应答信号
            if (!req && req_reg)
                ack <= 1'b0;
        end
    end
endmodule