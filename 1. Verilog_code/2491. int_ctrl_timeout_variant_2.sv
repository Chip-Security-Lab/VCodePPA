//SystemVerilog
// 中断控制超时模块 - 优化版本
module int_ctrl_timeout #(
    parameter TIMEOUT = 8'hFF
)(
    input clk, rst,
    input [7:0] req_in,
    output reg [2:0] curr_grant,
    output reg timeout
);
    reg [7:0] timer;
    wire [7:0] next_timer;
    wire timer_eq_timeout;
    wire [2:0] next_grant;
    
    // Priority encoder function for synthesis
    function [2:0] find_first_set;
        input [7:0] req;
        reg [2:0] index;
        begin
            index = 3'b0;
            if (req[0]) index = 3'd0;
            else if (req[1]) index = 3'd1;
            else if (req[2]) index = 3'd2;
            else if (req[3]) index = 3'd3;
            else if (req[4]) index = 3'd4;
            else if (req[5]) index = 3'd5;
            else if (req[6]) index = 3'd6;
            else if (req[7]) index = 3'd7;
            find_first_set = index;
        end
    endfunction
    
    // 使用带状进位加法器计算下一个计时器值
    cla_adder #(.WIDTH(8)) timer_adder (
        .a(timer),
        .b(8'h01),
        .cin(1'b0),
        .sum(next_timer),
        .cout()
    );
    
    // 判断timer是否等于TIMEOUT
    assign timer_eq_timeout = (timer == TIMEOUT);
    
    // 计算下一个授权信号
    assign next_grant = (req_in != 0) ? find_first_set(req_in) : 3'b0;
    
    // 超时信号生成逻辑
    always @(posedge clk) begin
        if (rst) begin
            timeout <= 1'b0;
        end else begin
            timeout <= timer_eq_timeout;
        end
    end
    
    // 计时器控制逻辑
    always @(posedge clk) begin
        if (rst || !req_in[curr_grant]) begin
            timer <= 8'b0;
        end else begin
            timer <= timer_eq_timeout ? 8'b0 : next_timer;
        end
    end
    
    // 授权控制逻辑
    always @(posedge clk) begin
        if (rst || !req_in[curr_grant]) begin
            curr_grant <= next_grant;
        end
    end
endmodule

// 8位带状进位加法器 - 优化版本
module cla_adder #(
    parameter WIDTH = 8
)(
    input [WIDTH-1:0] a,
    input [WIDTH-1:0] b,
    input cin,
    output [WIDTH-1:0] sum,
    output cout
);
    wire [WIDTH:0] carry;
    wire [WIDTH-1:0] g, p; // 生成和传播信号
    
    assign carry[0] = cin;
    
    // 计算生成和传播信号
    genvar i;
    generate
        for(i = 0; i < WIDTH; i = i + 1) begin: gen_gp
            assign g[i] = a[i] & b[i];          // 生成信号
            assign p[i] = a[i] ^ b[i];          // 传播信号 - 修正为XOR
        end
    endgenerate
    
    // 计算进位信号 - 优化逻辑
    generate
        for(i = 0; i < WIDTH; i = i + 1) begin: gen_carry
            assign carry[i+1] = g[i] | (p[i] & carry[i]);
        end
    endgenerate
    
    // 计算和
    generate
        for(i = 0; i < WIDTH; i = i + 1) begin: gen_sum
            assign sum[i] = p[i] ^ carry[i];    // 优化计算
        end
    endgenerate
    
    assign cout = carry[WIDTH];
endmodule