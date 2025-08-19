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
reg [7:0] CTRL_REG;      // 控制寄存器
reg [7:0] STAT_REG;      // 状态寄存器
reg [15:0] BAUD_REG;     // 波特率寄存器
reg [7:0] TX_REG;        // 发送寄存器
reg [7:0] RX_REG;        // 接收寄存器

// 中断控制逻辑
reg tx_empty_irq_en;
reg rx_full_irq_en;
reg [2:0] error_irq_en;

// 使用APB协议的状态机
localparam IDLE   = 2'b00;
localparam SETUP  = 2'b01;
localparam ACCESS = 2'b10;

reg [1:0] apb_state;

// 添加缺失信号
reg TX_EMPTY, RX_FULL;

// 前向寄存器重定时变量
reg  [ADDR_WIDTH-1:0] paddr_r;
reg                   psel_r;
reg                   penable_r;
reg                   pwrite_r;
reg  [31:0]           pwdata_r;

// 采样输入信号的寄存器推到组合逻辑后
always @(posedge PCLK or negedge PRESETn) begin
    if (!PRESETn) begin
        paddr_r   <= {ADDR_WIDTH{1'b0}};
        psel_r    <= 1'b0;
        penable_r <= 1'b0;
        pwrite_r  <= 1'b0;
        pwdata_r  <= 32'h0;
    end else begin
        if (apb_state == IDLE && PSEL && !PENABLE) begin
            paddr_r   <= PADDR;
            psel_r    <= PSEL;
            penable_r <= PENABLE;
            pwrite_r  <= PWRITE;
            pwdata_r  <= PWDATA;
        end else if (apb_state == IDLE) begin
            paddr_r   <= {ADDR_WIDTH{1'b0}};
            psel_r    <= 1'b0;
            penable_r <= 1'b0;
            pwrite_r  <= 1'b0;
            pwdata_r  <= 32'h0;
        end
    end
end

// 状态机及寄存器写入/读取逻辑
always @(posedge PCLK or negedge PRESETn) begin
    if (!PRESETn) begin
        PRDATA           <= 32'h0;
        CTRL_REG         <= 8'h00;
        STAT_REG         <= 8'h00;
        BAUD_REG         <= 16'h0000;
        TX_REG           <= 8'h00;
        RX_REG           <= 8'h00;
        tx_empty_irq_en  <= 1'b0;
        rx_full_irq_en   <= 1'b0;
        error_irq_en     <= 3'b000;
        apb_state        <= IDLE;
        TX_EMPTY         <= 1'b1;
        RX_FULL          <= 1'b0;
    end else begin
        case(apb_state)
            IDLE: begin
                if (PSEL && !PENABLE) begin
                    apb_state <= SETUP;
                end
            end

            SETUP: begin
                apb_state <= ACCESS;
            end

            ACCESS: begin
                if (pwrite_r) begin
                    case(paddr_r)
                        4'h0 : CTRL_REG <= pwdata_r[7:0];
                        4'h4 : BAUD_REG <= pwdata_r[15:0];
                        4'h8 : TX_REG   <= pwdata_r[7:0];
                        default: ; // 其他寄存器写入
                    endcase
                end else begin
                    case(paddr_r)
                        4'h0 : PRDATA <= {24'h0, CTRL_REG};
                        4'h4 : PRDATA <= {16'h0, BAUD_REG};
                        4'h8 : PRDATA <= {24'h0, TX_REG};
                        4'hC : PRDATA <= {24'h0, RX_REG};
                        4'h10: PRDATA <= {24'h0, STAT_REG};
                        default: PRDATA <= 32'h0;
                    endcase
                end
                apb_state <= IDLE;
            end
            default: apb_state <= IDLE;
        endcase
    end
end

assign PREADY = (apb_state == ACCESS);
assign irq = (tx_empty_irq_en & TX_EMPTY) | (rx_full_irq_en & RX_FULL);
assign txd = TX_REG[0]; // 简化实现，直接输出TX寄存器最低位

endmodule