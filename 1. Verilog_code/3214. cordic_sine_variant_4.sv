//SystemVerilog
module cordic_sine(
    input clock,
    input resetn,
    input [7:0] angle_step,
    input req,           // 请求信号，替代原来的valid
    output reg ack,      // 应答信号，替代原来的ready
    output reg [9:0] sine_output
);
    reg [9:0] x, y;
    reg [7:0] angle;
    reg [2:0] state;
    reg processing;      // 数据处理中的标志信号
    
    always @(posedge clock or negedge resetn) begin
        if (!resetn) begin
            x <= 10'd307;       // ~0.6*512
            y <= 10'd0;
            angle <= 8'd0;
            state <= 3'd0;
            sine_output <= 10'd0;
            ack <= 1'b0;
            processing <= 1'b0;
        end else begin
            case (state)
                3'd0: begin
                    if (req && !processing) begin
                        angle <= angle + angle_step;
                        state <= 3'd1;
                        processing <= 1'b1;
                        ack <= 1'b0;
                    end else if (!req) begin
                        processing <= 1'b0;
                    end
                end
                
                3'd1: begin
                    if (angle < 8'd128) begin
                        // 0 to π/2
                        y <= y + (x >> 3);
                    end else begin
                        // π/2 to π
                        y <= y - (x >> 3);
                    end
                    state <= 3'd2;
                end
                
                3'd2: begin
                    sine_output <= y;
                    state <= 3'd3;
                end
                
                3'd3: begin
                    ack <= 1'b1;  // 发送应答信号
                    if (!req) begin  // 等待请求信号释放
                        ack <= 1'b0;
                        state <= 3'd0;
                        processing <= 1'b0;
                    end
                end
                
                default: state <= 3'd0;
            endcase
        end
    end
endmodule