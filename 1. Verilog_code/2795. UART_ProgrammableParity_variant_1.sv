//SystemVerilog
module UART_ProgrammableParity #(
    parameter DYNAMIC_CONFIG = 1
)(
    input  wire clk,
    input  wire rst_n,  
    input  wire cfg_parity_en,    // 奇偶校验使能
    input  wire cfg_parity_type,  // 0-奇校验 1-偶校验
    input  wire [7:0] tx_payload,
    output reg  [7:0] rx_payload, 
    input  wire [7:0] rx_shift,   
    output reg  rx_parity_err,    
    output wire tx_parity         
);

// 跳跃进位8位加法器子模块声明
function [7:0] lca_sum;
    input [7:0] a, b;
    reg [7:0] p, g, c;
    integer i;
    begin
        p = a ^ b;
        g = a & b;
        c[0] = 1'b0;
        c[1] = g[0] | (p[0] & c[0]);
        c[2] = g[1] | (p[1] & g[0]) | (p[1] & p[0] & c[0]);
        c[3] = g[2] | (p[2] & g[1]) | (p[2] & p[1] & g[0]) | (p[2] & p[1] & p[0] & c[0]);
        c[4] = g[3] | (p[3] & g[2]) | (p[3] & p[2] & g[1]) | (p[3] & p[2] & p[1] & g[0]) | (p[3] & p[2] & p[1] & p[0] & c[0]);
        c[5] = g[4] | (p[4] & g[3]) | (p[4] & p[3] & g[2]) | (p[4] & p[3] & p[2] & g[1]) | (p[4] & p[3] & p[2] & p[1] & g[0]) | (p[4] & p[3] & p[2] & p[1] & p[0] & c[0]);
        c[6] = g[5] | (p[5] & g[4]) | (p[5] & p[4] & g[3]) | (p[5] & p[4] & p[3] & g[2]) | (p[5] & p[4] & p[3] & p[2] & g[1]) | (p[5] & p[4] & p[3] & p[2] & p[1] & g[0]) | (p[5] & p[4] & p[3] & p[2] & p[1] & p[0] & c[0]);
        c[7] = g[6] | (p[6] & g[5]) | (p[6] & p[5] & g[4]) | (p[6] & p[5] & p[4] & g[3]) | (p[6] & p[5] & p[4] & p[3] & g[2]) | (p[6] & p[5] & p[4] & p[3] & p[2] & g[1]) | (p[6] & p[5] & p[4] & p[3] & p[2] & p[1] & g[0]) | (p[6] & p[5] & p[4] & p[3] & p[2] & p[1] & p[0] & c[0]);
        for (i=0; i<8; i=i+1)
            lca_sum[i] = p[i] ^ c[i];
    end
endfunction

// 奇偶生成函数（使用跳跃进位加法器实现位求和）
function calc_parity_lca;
    input [7:0] data;
    input parity_type;
    reg [7:0] ones_sum;
    reg [2:0] ones_count;
    reg parity_bit;
    begin
        // 统计1的个数（使用跳跃进位加法器实现加法）
        ones_sum = lca_sum(lca_sum(lca_sum({7'b0, data[0]}, {7'b0, data[1]}),
                                   lca_sum({7'b0, data[2]}, {7'b0, data[3]})),
                           lca_sum(lca_sum({7'b0, data[4]}, {7'b0, data[5]}),
                                   lca_sum({7'b0, data[6]}, {7'b0, data[7]})));
        // ones_sum的最低三位为1的个数
        ones_count = ones_sum[2:0];
        parity_bit = ^data;
        calc_parity_lca = (parity_type) ? ~parity_bit : parity_bit;
    end
endfunction

// 移动后的寄存器定义
reg parity_en_reg;
reg [7:0] tx_data_reg;
reg [7:0] rx_shift_reg;
reg cfg_parity_type_reg;
reg cfg_parity_en_reg;

//-----------------------------------------------------------------------------
// 配置寄存器同步和数据同步前向重定时
//-----------------------------------------------------------------------------
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        cfg_parity_en_reg   <= 1'b0;
        cfg_parity_type_reg <= 1'b0;
        tx_data_reg         <= 8'b0;
        rx_shift_reg        <= 8'b0;
    end else begin
        cfg_parity_en_reg   <= cfg_parity_en;
        cfg_parity_type_reg <= cfg_parity_type;
        tx_data_reg         <= tx_payload;
        rx_shift_reg        <= rx_shift;
    end
end

//-----------------------------------------------------------------------------
// 前向重定时后的同步寄存器
//-----------------------------------------------------------------------------
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        parity_en_reg <= 1'b0;
    end else begin
        parity_en_reg <= cfg_parity_en_reg;
    end
end

//-----------------------------------------------------------------------------
// 接收数据同步（保持原有输出接口）
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        rx_payload <= 8'b0;
    end else begin
        rx_payload <= rx_shift_reg[7:0];
    end
end

//-----------------------------------------------------------------------------
// 接收端奇偶校验检测（寄存器推至组合逻辑后）
reg rx_parity_err_next;
always @(*) begin
    if (parity_en_reg) begin
        rx_parity_err_next = (calc_parity_lca(rx_shift_reg[7:0], cfg_parity_type_reg) != rx_shift_reg[7]);
    end else begin
        rx_parity_err_next = 1'b0;
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        rx_parity_err <= 1'b0;
    end else begin
        rx_parity_err <= rx_parity_err_next;
    end
end

//-----------------------------------------------------------------------------
// 发送端奇偶校验生成逻辑
//-----------------------------------------------------------------------------
generate
    if (DYNAMIC_CONFIG) begin : dynamic_cfg
        reg tx_parity_reg;
        always @(posedge clk or negedge rst_n) begin
            if (!rst_n) begin
                tx_parity_reg <= 1'b0;
            end else begin
                tx_parity_reg <= calc_parity_lca(tx_data_reg, cfg_parity_type_reg);
            end
        end
        assign tx_parity = tx_parity_reg;
    end else begin : fixed_cfg
        parameter FIXED_TYPE = 0;
        assign tx_parity = ^tx_data_reg ^ FIXED_TYPE;
    end
endgenerate

endmodule