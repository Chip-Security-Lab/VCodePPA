//SystemVerilog
// 顶层模块
module counter_with_carry (
    input wire clk, rst_n,
    output wire [3:0] count,
    output reg carry_out_reg
);
    // 内部连线
    wire [3:0] counter_value;
    wire carry_out_comb;
    
    // 时钟缓冲
    wire clk_buf1, clk_buf2;
    
    // 时钟树缓冲
    BUFG clk_bufg_inst (
        .I(clk),
        .O(clk_buf1)
    );
    
    BUFG clk_bufg_inst2 (
        .I(clk_buf1),
        .O(clk_buf2)
    );
    
    // 计数器子模块实例化
    counter_core counter_inst (
        .clk(clk_buf1),
        .rst_n(rst_n),
        .count(counter_value)
    );
    
    // 计数器值缓冲
    reg [3:0] counter_value_buf;
    always @(posedge clk_buf2 or negedge rst_n) begin
        if (!rst_n)
            counter_value_buf <= 4'b0000;
        else
            counter_value_buf <= counter_value;
    end
    
    // 进位检测子模块实例化
    carry_detector carry_inst (
        .count_value(counter_value_buf),
        .carry_out(carry_out_comb)
    );
    
    // 将内部计数值连接到输出
    assign count = counter_value;
    
    // 后向重定时：将输出寄存器移到组合逻辑之后
    always @(posedge clk_buf2 or negedge rst_n) begin
        if (!rst_n)
            carry_out_reg <= 1'b0;
        else
            carry_out_reg <= carry_out_comb;
    end
    
endmodule

// 计数器核心子模块
module counter_core (
    input wire clk, rst_n,
    output reg [3:0] count
);
    // 计数器逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            count <= 4'b0000;
        else
            count <= count + 1'b1;
    end
endmodule

// 进位检测子模块
module carry_detector (
    input wire [3:0] count_value,
    output wire carry_out
);
    // 当计数器值为最大值(1111)时产生进位信号
    assign carry_out = (count_value == 4'b1111);
endmodule

// 时钟缓冲模块
module BUFG (
    input wire I,
    output wire O
);
    assign O = I;
endmodule