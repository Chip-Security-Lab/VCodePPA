//SystemVerilog
module exp_waveform(
    input clk,
    input rst,
    input req,            // 请求信号，替代原来的enable信号
    output reg ack,       // 应答信号
    output reg [9:0] exp_out
);
    reg [3:0] count;
    reg [9:0] exp_values [0:15];
    reg [9:0] next_exp_out;
    reg req_d;            // 寄存请求信号用于边沿检测
    wire req_edge;        // 请求信号上升沿
    
    // 检测请求信号的上升沿
    always @(posedge clk or posedge rst) begin
        if (rst)
            req_d <= 1'b0;
        else
            req_d <= req;
    end
    
    assign req_edge = req & ~req_d;
    
    // Pre-load the exponential values
    initial begin
        // First half: exponential growth (powers of 2)
        exp_values[0] = 10'd1;    exp_values[1] = 10'd2;    exp_values[2] = 10'd4;    exp_values[3] = 10'd8;
        exp_values[4] = 10'd16;   exp_values[5] = 10'd32;   exp_values[6] = 10'd64;   exp_values[7] = 10'd128;
        exp_values[8] = 10'd256;  exp_values[9] = 10'd512;  exp_values[10] = 10'd1023;
        // Second half: exponential decay
        exp_values[11] = 10'd512; exp_values[12] = 10'd256; exp_values[13] = 10'd128;
        exp_values[14] = 10'd64;  exp_values[15] = 10'd32;
    end
    
    // Pre-compute next output value to reduce critical path
    always @(*) begin
        next_exp_out = exp_values[count];
    end
    
    // Sequential logic
    always @(posedge clk) begin
        if (rst) begin
            count <= 4'd0;
            exp_out <= 10'd0;
            ack <= 1'b0;
        end else begin
            if (req_edge) begin
                count <= count + 4'd1;
                exp_out <= next_exp_out;
                ack <= 1'b1;
            end else if (ack) begin
                ack <= 1'b0;  // 自动清除应答信号，准备下一次请求
            end
        end
    end
endmodule