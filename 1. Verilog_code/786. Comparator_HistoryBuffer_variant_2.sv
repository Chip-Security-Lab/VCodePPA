//SystemVerilog
module Comparator_HistoryBuffer #(
    parameter WIDTH = 8,
    parameter HISTORY_DEPTH = 4
)(
    input               clk,
    input               rst_n,
    input  [WIDTH-1:0]  a,b,
    output              curr_eq,
    output [HISTORY_DEPTH-1:0] history_eq
);
    wire [WIDTH:0] diff;
    wire [WIDTH-1:0] p, g;
    wire [WIDTH:0] c;
    reg [HISTORY_DEPTH-1:0] history_reg;
    
    // 输入缓冲寄存器
    reg [WIDTH-1:0] a_buf, b_buf;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            a_buf <= {WIDTH{1'b0}};
            b_buf <= {WIDTH{1'b0}};
        end else begin
            a_buf <= a;
            b_buf <= b;
        end
    end
    
    // 生成初始传播和生成信号
    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin: gen_pg
            assign p[i] = ~a_buf[i] | b_buf[i];
            assign g[i] = ~a_buf[i] & b_buf[i];
        end
    endgenerate
    
    // 借位信号计算 - 并行前缀树实现
    assign c[0] = 1'b0;
    
    // 第一级前缀计算
    wire [WIDTH-1:0] p_lvl1, g_lvl1;
    reg [WIDTH-1:0] p_lvl1_buf, g_lvl1_buf;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin: gen_lvl1
            if (i == 0) begin
                assign p_lvl1[i] = p[i];
                assign g_lvl1[i] = g[i];
            end else begin
                assign p_lvl1[i] = p[i] & p[i-1];
                assign g_lvl1[i] = g[i] | (p[i] & g[i-1]);
            end
        end
    endgenerate
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            p_lvl1_buf <= {WIDTH{1'b0}};
            g_lvl1_buf <= {WIDTH{1'b0}};
        end else begin
            p_lvl1_buf <= p_lvl1;
            g_lvl1_buf <= g_lvl1;
        end
    end
    
    // 第二级前缀计算
    wire [WIDTH-1:0] p_lvl2, g_lvl2;
    reg [WIDTH-1:0] p_lvl2_buf, g_lvl2_buf;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin: gen_lvl2
            if (i < 2) begin
                assign p_lvl2[i] = p_lvl1_buf[i];
                assign g_lvl2[i] = g_lvl1_buf[i];
            end else begin
                assign p_lvl2[i] = p_lvl1_buf[i] & p_lvl1_buf[i-2];
                assign g_lvl2[i] = g_lvl1_buf[i] | (p_lvl1_buf[i] & g_lvl1_buf[i-2]);
            end
        end
    endgenerate
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            p_lvl2_buf <= {WIDTH{1'b0}};
            g_lvl2_buf <= {WIDTH{1'b0}};
        end else begin
            p_lvl2_buf <= p_lvl2;
            g_lvl2_buf <= g_lvl2;
        end
    end
    
    // 第三级前缀计算
    wire [WIDTH-1:0] p_lvl3, g_lvl3;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin: gen_lvl3
            if (i < 4) begin
                assign p_lvl3[i] = p_lvl2_buf[i];
                assign g_lvl3[i] = g_lvl2_buf[i];
            end else begin
                assign p_lvl3[i] = p_lvl2_buf[i] & p_lvl2_buf[i-4];
                assign g_lvl3[i] = g_lvl2_buf[i] | (p_lvl2_buf[i] & g_lvl2_buf[i-4]);
            end
        end
    endgenerate
    
    // 计算借位
    reg [WIDTH:0] c_buf;
    generate
        for (i = 1; i <= WIDTH; i = i + 1) begin: gen_carry
            assign c[i] = g_lvl3[i-1] | (p_lvl3[i-1] & c[0]);
        end
    endgenerate
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            c_buf <= {(WIDTH+1){1'b0}};
        else
            c_buf <= c;
    end
    
    // 计算差值
    reg [WIDTH:0] diff_buf;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin: gen_diff
            assign diff[i] = a_buf[i] ^ b_buf[i] ^ c_buf[i];
        end
    endgenerate
    assign diff[WIDTH] = c_buf[WIDTH];
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            diff_buf <= {(WIDTH+1){1'b0}};
        else
            diff_buf <= diff;
    end
    
    // 相等比较
    reg curr_eq_reg;
    assign curr_eq = curr_eq_reg;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            curr_eq_reg <= 1'b0;
        else
            curr_eq_reg <= (diff_buf[WIDTH-1:0] == {WIDTH{1'b0}}) && (diff_buf[WIDTH] == 1'b0);
    end
    
    // 历史寄存器
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) 
            history_reg <= {HISTORY_DEPTH{1'b0}};
        else
            history_reg <= {history_reg[HISTORY_DEPTH-2:0], curr_eq_reg};
    end
    
    assign history_eq = history_reg;
endmodule