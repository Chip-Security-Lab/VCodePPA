//SystemVerilog
module UART_APB_Interface #(
    parameter ADDR_WIDTH = 4,
    parameter REG_FILE = 8
)(
    input  wire PCLK,
    input  wire PRESETn,
    input  wire [ADDR_WIDTH-1:0] PADDR,
    input  wire PSEL,
    input  wire PENABLE,
    input  wire PWRITE,
    input  wire [31:0] PWDATA,
    output reg  [31:0] PRDATA,
    output wire PREADY,
    output wire txd,
    input  wire rxd,
    output wire irq
);
// APB寄存器组
reg [7:0] CTRL_REG;  // 控制寄存器
reg [7:0] STAT_REG;  // 状态寄存器
reg [15:0] BAUD_REG; // 波特率寄存器
reg [7:0] TX_REG;    // 发送寄存器
reg [7:0] RX_REG;    // 接收寄存器

// 中断控制逻辑
reg tx_empty_irq_en;
reg rx_full_irq_en;
reg [2:0] error_irq_en;

// APB协议状态机混合编码(Hybrid Encoding)
// 频繁访问的状态组采用独热编码
localparam APB_IDLE      = 3'b001; // One-hot
localparam APB_SETUP     = 3'b010; // One-hot
localparam APB_ACCESS    = 3'b100; // One-hot

reg [2:0] apb_state;

// 添加缺失信号
reg TX_EMPTY, RX_FULL;

// 前向寄存器重定时相关信号
reg [ADDR_WIDTH-1:0] paddr_reg;
reg psel_reg;
reg penable_reg;
reg pwrite_reg;
reg [31:0] pwdata_reg;

// 输入寄存器前移穿过组合逻辑
always @(posedge PCLK or negedge PRESETn) begin
    if (!PRESETn) begin
        paddr_reg   <= {ADDR_WIDTH{1'b0}};
        psel_reg    <= 1'b0;
        penable_reg <= 1'b0;
        pwrite_reg  <= 1'b0;
        pwdata_reg  <= 32'b0;
    end else begin
        paddr_reg   <= PADDR;
        psel_reg    <= PSEL;
        penable_reg <= PENABLE;
        pwrite_reg  <= PWRITE;
        pwdata_reg  <= PWDATA;
    end
end

// 状态机及寄存器写读操作，输入信号替换为寄存器后的信号
reg [ADDR_WIDTH-1:0] paddr_r;
reg psel_r;
reg penable_r;
reg pwrite_r;
reg [31:0] pwdata_r;

always @(posedge PCLK or negedge PRESETn) begin
    if (!PRESETn) begin
        // APB接口复位逻辑
        PRDATA <= 32'h0;
        CTRL_REG <= 8'h00;
        STAT_REG <= 8'h00;
        BAUD_REG <= 16'h0000;
        TX_REG <= 8'h00;
        RX_REG <= 8'h00;
        tx_empty_irq_en <= 1'b0;
        rx_full_irq_en <= 1'b0;
        error_irq_en <= 3'b000;
        apb_state <= APB_IDLE;
        TX_EMPTY <= 1'b1;
        RX_FULL <= 1'b0;
        paddr_r   <= {ADDR_WIDTH{1'b0}};
        psel_r    <= 1'b0;
        penable_r <= 1'b0;
        pwrite_r  <= 1'b0;
        pwdata_r  <= 32'b0;
    end else begin
        // 二级寄存器，保证组合逻辑后移
        paddr_r   <= paddr_reg;
        psel_r    <= psel_reg;
        penable_r <= penable_reg;
        pwrite_r  <= pwrite_reg;
        pwdata_r  <= pwdata_reg;

        case (apb_state)
            APB_IDLE: begin
                if (psel_r && !penable_r) begin
                    apb_state <= APB_SETUP;
                end
            end
            APB_SETUP: begin
                apb_state <= APB_ACCESS;
            end
            APB_ACCESS: begin
                if (pwrite_r) begin
                    case (paddr_r)
                        4'h0: CTRL_REG <= pwdata_r[7:0];
                        4'h4: BAUD_REG <= pwdata_r[15:0];
                        4'h8: TX_REG <= pwdata_r[7:0];
                        default: ; // 其他寄存器写入
                    endcase
                end else begin
                    case (paddr_r)
                        4'h0:  PRDATA <= {24'h0, CTRL_REG};
                        4'h4:  PRDATA <= {16'h0, BAUD_REG};
                        4'h8:  PRDATA <= {24'h0, TX_REG};
                        4'hC:  PRDATA <= {24'h0, RX_REG};
                        4'h10: PRDATA <= {24'h0, STAT_REG};
                        default: PRDATA <= 32'h0;
                    endcase
                end
                apb_state <= APB_IDLE;
            end
            default: apb_state <= APB_IDLE;
        endcase
    end
end

assign PREADY = (apb_state == APB_ACCESS);
assign irq = (tx_empty_irq_en & TX_EMPTY) | (rx_full_irq_en & RX_FULL);
assign txd = TX_REG[0]; // 简化实现，直接输出TX寄存器最低位

endmodule