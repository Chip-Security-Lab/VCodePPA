//SystemVerilog
module power_on_reset_sync (
    input  wire clk,
    input  wire ext_rst_n,
    output wire por_rst_n
);
    reg [2:0] por_counter;
    reg       por_done;
    reg       ext_rst_sync0;
    reg       ext_rst_sync1;
    reg       por_rst_n_reg;
    
    // Brent-Kung加法器信号
    wire [2:0] p_signal;
    wire [2:0] g_signal;
    wire [1:0] p_group1;
    wire [1:0] g_group1;
    
    // 流水线寄存器
    reg [2:0] p_signal_reg;
    reg [2:0] g_signal_reg;
    reg [1:0] p_group1_reg;
    reg [1:0] g_group1_reg;
    reg       p_group2;
    reg       g_group2;
    reg [2:0] carry;
    reg [2:0] counter_next;
    
    initial begin
        por_counter = 3'b000;
        por_done = 1'b0;
        ext_rst_sync0 = 1'b0;
        ext_rst_sync1 = 1'b0;
        por_rst_n_reg = 1'b0;
        p_signal_reg = 3'b000;
        g_signal_reg = 3'b000;
        p_group1_reg = 2'b00;
        g_group1_reg = 2'b00;
        p_group2 = 1'b0;
        g_group2 = 1'b0;
        carry = 3'b000;
        counter_next = 3'b000;
    end
    
    // First stage synchronizer
    always @(posedge clk or negedge ext_rst_n) begin
        if (!ext_rst_n) begin
            ext_rst_sync0 <= 1'b0;
        end else begin
            ext_rst_sync0 <= 1'b1;
        end
    end
    
    // Second stage synchronizer
    always @(posedge clk or negedge ext_rst_n) begin
        if (!ext_rst_n) begin
            ext_rst_sync1 <= 1'b0;
        end else begin
            ext_rst_sync1 <= ext_rst_sync0;
        end
    end
    
    // Brent-Kung加法器实现 - 第一流水级
    // 第一阶段：生成p和g信号
    assign p_signal[0] = por_counter[0] ^ 1'b1; // 与1做XOR
    assign p_signal[1] = por_counter[1] ^ 1'b0;
    assign p_signal[2] = por_counter[2] ^ 1'b0;
    
    assign g_signal[0] = por_counter[0] & 1'b1; // 与1做AND
    assign g_signal[1] = por_counter[1] & 1'b0;
    assign g_signal[2] = por_counter[2] & 1'b0;
    
    // 第二阶段：生成组p和g信号
    assign p_group1[0] = p_signal[1] & p_signal[0];
    assign g_group1[0] = g_signal[1] | (p_signal[1] & g_signal[0]);
    
    assign p_group1[1] = 1'b0; // 未使用
    assign g_group1[1] = 1'b0; // 未使用
    
    // 流水线寄存器 - 第一级到第二级
    always @(posedge clk or negedge ext_rst_n) begin
        if (!ext_rst_n) begin
            p_signal_reg <= 3'b000;
            g_signal_reg <= 3'b000;
            p_group1_reg <= 2'b00;
            g_group1_reg <= 2'b00;
        end else begin
            p_signal_reg <= p_signal;
            g_signal_reg <= g_signal;
            p_group1_reg <= p_group1;
            g_group1_reg <= g_group1;
        end
    end
    
    // Brent-Kung加法器实现 - 第二流水级
    // 第三阶段：生成更高级别的组p和g信号
    always @(posedge clk or negedge ext_rst_n) begin
        if (!ext_rst_n) begin
            p_group2 <= 1'b0;
            g_group2 <= 1'b0;
        end else begin
            p_group2 <= p_signal_reg[2] & p_group1_reg[0];
            g_group2 <= g_signal_reg[2] | (p_signal_reg[2] & g_group1_reg[0]);
        end
    end
    
    // 第四阶段：计算进位
    always @(posedge clk or negedge ext_rst_n) begin
        if (!ext_rst_n) begin
            carry <= 3'b000;
        end else begin
            carry[0] <= g_signal_reg[0];
            carry[1] <= g_group1_reg[0];
            carry[2] <= g_group2;
        end
    end
    
    // 第五阶段：计算结果
    always @(posedge clk or negedge ext_rst_n) begin
        if (!ext_rst_n) begin
            counter_next <= 3'b000;
        end else begin
            counter_next[0] <= p_signal_reg[0] ^ 1'b0; // 初始进位为0
            counter_next[1] <= p_signal_reg[1] ^ carry[0];
            counter_next[2] <= p_signal_reg[2] ^ carry[1];
        end
    end
    
    // Counter logic with pipelined Brent-Kung adder
    always @(posedge clk or negedge ext_rst_n) begin
        if (!ext_rst_n) begin
            por_counter <= 3'b000;
            por_done <= 1'b0;
        end else begin
            if (!por_done)
                if (por_counter < 3'b111)
                    por_counter <= counter_next;
                else
                    por_done <= 1'b1;
        end
    end
    
    // Register the output logic
    always @(posedge clk or negedge ext_rst_n) begin
        if (!ext_rst_n) begin
            por_rst_n_reg <= 1'b0;
        end else begin
            por_rst_n_reg <= ext_rst_sync1 & por_done;
        end
    end
    
    assign por_rst_n = por_rst_n_reg;
endmodule