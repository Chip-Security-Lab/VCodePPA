//SystemVerilog
//===================================================================
// 顶层模块
//===================================================================
module clk_with_delay (
    input  wire       clk_in,
    input  wire       rst_n,
    input  wire [3:0] delay_cycles,
    output wire       clk_out
);

    // 内部信号
    wire       delay_complete;
    wire       toggle_enable;

    // 延迟计数器子模块
    delay_counter u_delay_counter (
        .clk_in         (clk_in),
        .rst_n          (rst_n),
        .delay_cycles   (delay_cycles),
        .delay_complete (delay_complete),
        .toggle_enable  (toggle_enable)
    );

    // 时钟输出生成器子模块
    clock_generator u_clock_generator (
        .clk_in        (clk_in),
        .rst_n         (rst_n),
        .toggle_enable (toggle_enable),
        .clk_out       (clk_out)
    );

endmodule

//===================================================================
// 延迟计数器子模块 - 负责计数并生成使能信号
//===================================================================
module delay_counter (
    input  wire       clk_in,
    input  wire       rst_n,
    input  wire [3:0] delay_cycles,
    output reg        delay_complete,
    output reg        toggle_enable
);
    
    reg [3:0] counter;
    wire [3:0] next_counter;
    
    // 使用并行前缀加法器实现加法
    parallel_prefix_adder_4bit u_adder (
        .a       (counter),
        .b       (4'b0001),
        .sum     (next_counter),
        .carry_out()
    );
    
    always @(posedge clk_in or negedge rst_n) begin
        if (!rst_n) begin
            counter <= 4'd0;
            delay_complete <= 1'b0;
            toggle_enable <= 1'b0;
        end else if (!delay_complete) begin
            if (counter >= delay_cycles) begin
                delay_complete <= 1'b1;
                toggle_enable <= 1'b1;
                counter <= 4'd0;
            end else begin
                counter <= next_counter;
            end
        end
    end
    
endmodule

//===================================================================
// 时钟生成器子模块 - 负责生成输出时钟
//===================================================================
module clock_generator (
    input  wire clk_in,
    input  wire rst_n,
    input  wire toggle_enable,
    output reg  clk_out
);

    always @(posedge clk_in or negedge rst_n) begin
        if (!rst_n) begin
            clk_out <= 1'b0;
        end else if (toggle_enable) begin
            clk_out <= ~clk_out;
        end
    end
    
endmodule

//===================================================================
// 并行前缀加法器实现 (4位)
//===================================================================
module parallel_prefix_adder_4bit (
    input  wire [3:0] a,
    input  wire [3:0] b,
    output wire [3:0] sum,
    output wire       carry_out
);
    // 产生和传播信号
    wire [3:0] g; // 产生信号
    wire [3:0] p; // 传播信号
    
    // 预处理阶段：计算位级产生和传播信号
    assign g = a & b;
    assign p = a ^ b;
    
    // 前缀计算阶段
    wire [3:0] c; // 内部进位信号
    
    // 第一级前缀计算
    wire [3:0] g_level1, p_level1;
    
    // 位0保持不变
    assign g_level1[0] = g[0];
    assign p_level1[0] = p[0];
    
    // 位1更新（合并位0和位1）
    assign g_level1[1] = g[1] | (p[1] & g[0]);
    assign p_level1[1] = p[1] & p[0];
    
    // 位2保持不变
    assign g_level1[2] = g[2];
    assign p_level1[2] = p[2];
    
    // 位3保持不变
    assign g_level1[3] = g[3];
    assign p_level1[3] = p[3];
    
    // 第二级前缀计算
    wire [3:0] g_level2, p_level2;
    
    // 位0和位1保持不变
    assign g_level2[0] = g_level1[0];
    assign p_level2[0] = p_level1[0];
    assign g_level2[1] = g_level1[1];
    assign p_level2[1] = p_level1[1];
    
    // 位2更新（合并位0-1和位2）
    assign g_level2[2] = g_level1[2] | (p_level1[2] & g_level1[1]);
    assign p_level2[2] = p_level1[2] & p_level1[1];
    
    // 位3更新（合并位2和位3）
    assign g_level2[3] = g_level1[3] | (p_level1[3] & g_level1[2]);
    assign p_level2[3] = p_level1[3] & p_level1[2];
    
    // 第三级前缀计算
    wire [3:0] g_level3, p_level3;
    
    // 位0、1和2保持不变
    assign g_level3[0] = g_level2[0];
    assign p_level3[0] = p_level2[0];
    assign g_level3[1] = g_level2[1];
    assign p_level3[1] = p_level2[1];
    assign g_level3[2] = g_level2[2];
    assign p_level3[2] = p_level2[2];
    
    // 位3更新（合并位0-2和位3）
    assign g_level3[3] = g_level2[3] | (p_level2[3] & g_level2[1]);
    assign p_level3[3] = p_level2[3] & p_level2[1];
    
    // 计算进位
    assign c[0] = 1'b0; // 初始进位为0
    assign c[1] = g_level3[0];
    assign c[2] = g_level3[1];
    assign c[3] = g_level3[2];
    assign carry_out = g_level3[3]; // 最终进位
    
    // 最后阶段：计算和
    assign sum = p ^ {c[3:0]};
    
endmodule