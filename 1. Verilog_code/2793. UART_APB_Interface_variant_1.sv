//SystemVerilog
module UART_APB_Interface #(
    parameter ADDR_WIDTH = 4,
    parameter REG_FILE = 8
)(
    input  wire                   PCLK,
    input  wire                   PRESETn,
    input  wire [ADDR_WIDTH-1:0]  PADDR,
    input  wire                   PSEL,
    input  wire                   PENABLE,
    input  wire                   PWRITE,
    input  wire [31:0]            PWDATA,
    output reg  [31:0]            PRDATA,
    output wire                   PREADY,
    output wire                   txd,
    input  wire                   rxd,
    output wire                   irq
);

// APB寄存器组
reg [7:0]   ctrl_reg;        // 控制寄存器
reg [7:0]   stat_reg;        // 状态寄存器
reg [15:0]  baud_reg;        // 波特率寄存器
reg [7:0]   tx_reg;          // 发送寄存器
reg [7:0]   rx_reg;          // 接收寄存器

// 中断控制逻辑
reg         tx_empty_irq_en;
reg         rx_full_irq_en;
reg [2:0]   error_irq_en;

// 状态机编码
localparam  APB_IDLE    = 3'b001; // One-hot
localparam  APB_SETUP   = 3'b010; // One-hot
localparam  APB_ACCESS0 = 3'b100; // Binary group

reg [2:0]   apb_state;
reg [2:0]   apb_state_next;

// 状态信号
reg         tx_empty_flag, rx_full_flag;

//----------------------------------------------------------------------------
// 复位与状态机寄存器
always @(posedge PCLK or negedge PRESETn) begin
    if (!PRESETn) begin
        apb_state <= APB_IDLE;
    end else begin
        apb_state <= apb_state_next;
    end
end

//----------------------------------------------------------------------------
// 状态转移逻辑
always @(*) begin
    apb_state_next = apb_state;
    case (apb_state)
        APB_IDLE: begin
            if (PSEL && !PENABLE)
                apb_state_next = APB_SETUP;
        end
        APB_SETUP: begin
            apb_state_next = APB_ACCESS0;
        end
        APB_ACCESS0: begin
            apb_state_next = APB_IDLE;
        end
        default: apb_state_next = APB_IDLE;
    endcase
end

//----------------------------------------------------------------------------
// 控制寄存器写操作
always @(posedge PCLK or negedge PRESETn) begin
    if (!PRESETn) begin
        ctrl_reg <= 8'h00;
    end else if (apb_state == APB_ACCESS0 && PWRITE && PADDR == 4'h0) begin
        ctrl_reg <= PWDATA[7:0];
    end
end

// 波特率寄存器写操作
always @(posedge PCLK or negedge PRESETn) begin
    if (!PRESETn) begin
        baud_reg <= 16'h0000;
    end else if (apb_state == APB_ACCESS0 && PWRITE && PADDR == 4'h4) begin
        baud_reg <= PWDATA[15:0];
    end
end

// 发送寄存器写操作
always @(posedge PCLK or negedge PRESETn) begin
    if (!PRESETn) begin
        tx_reg <= 8'h00;
    end else if (apb_state == APB_ACCESS0 && PWRITE && PADDR == 4'h8) begin
        tx_reg <= PWDATA[7:0];
    end
end

// 状态寄存器复位
always @(posedge PCLK or negedge PRESETn) begin
    if (!PRESETn) begin
        stat_reg <= 8'h00;
    end
end

// 接收寄存器复位
always @(posedge PCLK or negedge PRESETn) begin
    if (!PRESETn) begin
        rx_reg <= 8'h00;
    end
end

//----------------------------------------------------------------------------
// APB读操作
always @(posedge PCLK or negedge PRESETn) begin
    if (!PRESETn) begin
        PRDATA <= 32'h0;
    end else if (apb_state == APB_ACCESS0 && !PWRITE) begin
        case(PADDR)
            4'h0:  PRDATA <= {24'h0, ctrl_reg};
            4'h4:  PRDATA <= {16'h0, baud_reg};
            4'h8:  PRDATA <= {24'h0, tx_reg};
            4'hC:  PRDATA <= {24'h0, rx_reg};
            4'h10: PRDATA <= {24'h0, stat_reg};
            default: PRDATA <= 32'h0;
        endcase
    end
end

//----------------------------------------------------------------------------
// IRQ使能信号复位
always @(posedge PCLK or negedge PRESETn) begin
    if (!PRESETn) begin
        tx_empty_irq_en <= 1'b0;
        rx_full_irq_en  <= 1'b0;
        error_irq_en    <= 3'b000;
    end
end

//----------------------------------------------------------------------------
// TX_EMPTY标志复位
always @(posedge PCLK or negedge PRESETn) begin
    if (!PRESETn) begin
        tx_empty_flag <= 1'b1;
    end
end

// RX_FULL标志复位
always @(posedge PCLK or negedge PRESETn) begin
    if (!PRESETn) begin
        rx_full_flag <= 1'b0;
    end
end

//----------------------------------------------------------------------------
// APB READY 信号
assign PREADY = (apb_state == APB_ACCESS0);

//----------------------------------------------------------------------------
// 简化版中断信号
assign irq = (tx_empty_irq_en & tx_empty_flag) | (rx_full_irq_en & rx_full_flag);

//----------------------------------------------------------------------------
// TXD输出
assign txd = tx_reg[0];

endmodule