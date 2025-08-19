//SystemVerilog
// SystemVerilog
// IEEE 1364-2005 Verilog标准
module address_shadow_reg #(
    parameter WIDTH = 32,
    parameter ADDR_WIDTH = 4,
    parameter BASE_ADDR = 4'h0
)(
    input wire clk,
    input wire rst_n,
    input wire [WIDTH-1:0] data_in,
    input wire [ADDR_WIDTH-1:0] addr,
    input wire write_en,
    input wire read_en,
    output reg [WIDTH-1:0] data_out,
    output reg [WIDTH-1:0] shadow_data
);
    // 预先计算地址匹配信号并寄存
    reg addr_match_reg;
    reg shadow_addr_match_reg;
    reg [WIDTH-1:0] data_in_reg;
    reg write_en_reg;
    
    // 先行借位减法器相关信号
    wire [3:0] addr_sub_base;     // 地址与基址的差值
    wire [3:0] p_signals;         // 传播信号
    wire [3:0] g_signals;         // 生成信号
    wire [4:0] borrow;            // 借位信号，包括输入借位和输出借位
    
    // 生成传播信号和生成信号
    assign p_signals = ~addr[3:0] | BASE_ADDR[3:0];
    assign g_signals = ~addr[3:0] & BASE_ADDR[3:0];
    
    // 阶段1：计算前两位借位信号和差值
    reg borrow1_pipe, borrow2_pipe;
    reg [1:0] addr_sub_base_pipe;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            borrow1_pipe <= 1'b0;
            borrow2_pipe <= 1'b0;
            addr_sub_base_pipe <= 2'b00;
        end else begin
            borrow1_pipe <= g_signals[0] | (p_signals[0] & 1'b0);
            borrow2_pipe <= g_signals[1] | (p_signals[1] & g_signals[0]) | (p_signals[1] & p_signals[0] & 1'b0);
            addr_sub_base_pipe[0] <= addr[0] ^ BASE_ADDR[0] ^ 1'b0;
            addr_sub_base_pipe[1] <= addr[1] ^ BASE_ADDR[1] ^ (g_signals[0] | (p_signals[0] & 1'b0));
        end
    end
    
    // 阶段2：计算高位借位信号和差值
    wire borrow3 = g_signals[2] | (p_signals[2] & g_signals[1]) | (p_signals[2] & p_signals[1] & g_signals[0]) | 
                  (p_signals[2] & p_signals[1] & p_signals[0] & 1'b0);
    wire borrow4 = g_signals[3] | (p_signals[3] & g_signals[2]) | (p_signals[3] & p_signals[2] & g_signals[1]) | 
                  (p_signals[3] & p_signals[2] & p_signals[1] & g_signals[0]) | 
                  (p_signals[3] & p_signals[2] & p_signals[1] & p_signals[0] & 1'b0);
    
    // 计算高位差值
    wire [1:0] addr_sub_base_high;
    assign addr_sub_base_high[0] = addr[2] ^ BASE_ADDR[2] ^ borrow2_pipe;
    assign addr_sub_base_high[1] = addr[3] ^ BASE_ADDR[3] ^ borrow3;
    
    // 组合完整的差值
    reg [3:0] addr_sub_base_full;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            addr_sub_base_full <= 4'h0;
        end else begin
            addr_sub_base_full <= {addr_sub_base_high, addr_sub_base_pipe};
        end
    end
    
    // 存储p_signals和g_signals用于第二阶段
    reg [3:0] p_signals_reg, g_signals_reg;
    reg [1:0] addr_high_reg, base_addr_high_reg;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            p_signals_reg <= 4'h0;
            g_signals_reg <= 4'h0;
            addr_high_reg <= 2'b00;
            base_addr_high_reg <= 2'b00;
        end else begin
            p_signals_reg <= p_signals;
            g_signals_reg <= g_signals;
            addr_high_reg <= addr[3:2];
            base_addr_high_reg <= BASE_ADDR[3:2];
        end
    end
    
    // 输入级寄存器 - 使用流水线结果计算地址匹配
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            addr_match_reg <= 1'b0;
            shadow_addr_match_reg <= 1'b0;
            data_in_reg <= {WIDTH{1'b0}};
            write_en_reg <= 1'b0;
        end else begin
            addr_match_reg <= (addr_sub_base_full == 4'h0);
            shadow_addr_match_reg <= (addr_sub_base_full == 4'h1);
            data_in_reg <= data_in;
            write_en_reg <= write_en;
        end
    end
    
    // 主寄存器逻辑 - 使用已寄存的控制信号
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            data_out <= 0;
        else if (write_en_reg && addr_match_reg)
            data_out <= data_in_reg;
    end
    
    // 影子寄存器逻辑 - 使用已寄存的控制信号
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            shadow_data <= 0;
        else if (write_en_reg && shadow_addr_match_reg)
            shadow_data <= data_in_reg;
        else if (write_en_reg && addr_match_reg)
            shadow_data <= data_out;
    end
endmodule