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
// 奇偶生成函数
function calc_parity;
    input [7:0] data;
    input parity_type;
    reg sum;
    begin
        sum = ^data;
        calc_parity = (parity_type) ? ~sum : sum;
    end
endfunction

reg parity_en;
reg [7:0] tx_data;

// 初始化赋值
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        parity_en <= 0;
        rx_parity_err <= 0;
        rx_payload <= 0;
        tx_data <= 0;
    end else begin
        parity_en <= cfg_parity_en;
        tx_data <= tx_payload;
        rx_payload <= rx_shift[7:0];
        
        // 接收端校验检测
        if (parity_en) begin
            // 修复: 修改rx_shift位宽范围，确保索引不超出边界
            // 假设rx_shift至少是8位宽
            rx_parity_err <= (calc_parity(rx_shift[7:0], cfg_parity_type) != rx_shift[7]);
        end else begin
            rx_parity_err <= 0;
        end
    end
end

// 可重配置逻辑生成
generate
    if (DYNAMIC_CONFIG) begin : dynamic_cfg
        reg tx_parity_reg;
        always @(posedge clk or negedge rst_n) begin
            if (!rst_n) begin
                tx_parity_reg <= 0;
            end else begin
                tx_parity_reg <= calc_parity(tx_data, cfg_parity_type);
            end
        end
        assign tx_parity = tx_parity_reg;
    end else begin : fixed_cfg
        parameter FIXED_TYPE = 0;
        assign tx_parity = ^tx_data ^ FIXED_TYPE;
    end
endgenerate
endmodule