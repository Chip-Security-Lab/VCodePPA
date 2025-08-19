//SystemVerilog
// 顶层模块
module pwm_generator #(parameter CNT_W=8) (
    input clk, rst,
    input [CNT_W-1:0] duty_cycle,
    output reg pwm_out
);
    // 内部信号声明
    wire [CNT_W-1:0] cnt_next;
    wire [CNT_W-1:0] cnt;
    wire [CNT_W-1:0] diff;
    wire borrow_out;
    wire pwm_next;

    // 计数器子模块实例化
    counter #(.WIDTH(CNT_W)) counter_inst (
        .clk(clk),
        .rst(rst),
        .cnt_next(cnt_next),
        .cnt(cnt)
    );

    // 比较器子模块实例化
    comparator #(.WIDTH(CNT_W)) comp_inst (
        .duty_cycle(duty_cycle),
        .cnt(cnt),
        .diff(diff),
        .borrow_out(borrow_out)
    );

    // PWM输出控制子模块实例化
    pwm_control #(.WIDTH(CNT_W)) pwm_ctrl_inst (
        .clk(clk),
        .rst(rst),
        .borrow_out(borrow_out),
        .cnt(cnt),
        .cnt_next(cnt_next),
        .pwm_next(pwm_next),
        .pwm_out(pwm_out)
    );

endmodule

// 计数器子模块
module counter #(parameter WIDTH=8) (
    input clk, rst,
    input [WIDTH-1:0] cnt_next,
    output reg [WIDTH-1:0] cnt
);
    always @(posedge clk or posedge rst) begin
        if (rst)
            cnt <= 0;
        else
            cnt <= cnt_next;
    end
endmodule

// 比较器子模块
module comparator #(parameter WIDTH=8) (
    input [WIDTH-1:0] duty_cycle,
    input [WIDTH-1:0] cnt,
    output [WIDTH-1:0] diff,
    output borrow_out
);
    wire [WIDTH:0] borrow;
    assign borrow[0] = 0;

    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin: gen_borrow
            assign diff[i] = duty_cycle[i] ^ cnt[i] ^ borrow[i];
            assign borrow[i+1] = (~duty_cycle[i] & cnt[i]) | (borrow[i] & ~(duty_cycle[i] ^ cnt[i]));
        end
    endgenerate

    assign borrow_out = borrow[WIDTH];
endmodule

// PWM控制子模块
module pwm_control #(parameter WIDTH=8) (
    input clk, rst,
    input borrow_out,
    input [WIDTH-1:0] cnt,
    output reg [WIDTH-1:0] cnt_next,
    output reg pwm_next,
    output reg pwm_out
);
    always @(*) begin
        cnt_next = cnt + 1;
        pwm_next = ~borrow_out;
    end

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            pwm_out <= 0;
        end else begin
            pwm_out <= pwm_next;
        end
    end
endmodule