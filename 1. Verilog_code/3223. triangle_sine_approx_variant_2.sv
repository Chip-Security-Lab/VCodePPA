//SystemVerilog
module triangle_sine_approx(
    input clk,
    input reset,
    input req,           // 请求信号，替代valid
    output reg ack,      // 应答信号，替代ready
    output reg [7:0] sine_out
);
    reg [7:0] triangle;
    reg up_down;
    reg [1:0] state;
    
    // 状态定义
    localparam IDLE = 2'b00;
    localparam PROCESSING = 2'b01;
    localparam DONE = 2'b10;
    
    // 状态机和三角波生成
    always @(posedge clk) begin
        if (reset) begin
            triangle <= 8'd0;
            up_down <= 1'b1;
            ack <= 1'b0;
            state <= IDLE;
        end else begin
            case (state)
                IDLE: begin
                    if (req) begin
                        state <= PROCESSING;
                        ack <= 1'b0;
                        
                        // 生成三角波
                        if (up_down) begin
                            if (triangle == 8'd255)
                                up_down <= 1'b0;
                            else
                                triangle <= triangle + 8'd1;
                        end else begin
                            if (triangle == 8'd0)
                                up_down <= 1'b1;
                            else
                                triangle <= triangle - 8'd1;
                        end
                    end
                end
                
                PROCESSING: begin
                    state <= DONE;
                    
                    // 应用立方变换近似正弦波
                    if (triangle < 8'd64)
                        sine_out <= 8'd64 + (triangle >> 1);
                    else if (triangle < 8'd192)
                        sine_out <= 8'd96 + (triangle >> 1);
                    else
                        sine_out <= 8'd192 + (triangle >> 2);
                end
                
                DONE: begin
                    ack <= 1'b1;
                    if (!req) begin
                        state <= IDLE;
                        ack <= 1'b0;
                    end
                end
                
                default: state <= IDLE;
            endcase
        end
    end
endmodule