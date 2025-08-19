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
    output wire [31:0] PRDATA,
    output wire PREADY,
    output wire txd,
    input  wire rxd,
    output wire irq
);

// -----------------------------------
// 寄存器定义
// -----------------------------------
reg [7:0] ctrl_reg_stage1, ctrl_reg_stage2;            
reg [7:0] stat_reg_stage1, stat_reg_stage2;            
reg [15:0] baud_reg_stage1, baud_reg_stage2;           
reg [7:0] tx_reg_stage1, tx_reg_stage2;                
reg [7:0] rx_reg_stage1, rx_reg_stage2;                

reg tx_empty_irq_en_stage1, tx_empty_irq_en_stage2;
reg rx_full_irq_en_stage1, rx_full_irq_en_stage2;
reg [2:0] error_irq_en_stage1, error_irq_en_stage2;
reg tx_empty_stage1, tx_empty_stage2;
reg rx_full_stage1, rx_full_stage2;

// -----------------------------------
// APB接口状态机流水线寄存器
// -----------------------------------
localparam IDLE   = 2'b00;
localparam SETUP  = 2'b01;
localparam ACCESS = 2'b10;

reg [1:0] apb_state_stage1, apb_state_stage2;

// -----------------------------------
// 流水线控制信号
// -----------------------------------
reg valid_stage1, valid_stage2;
reg flush_stage1, flush_stage2;

// -----------------------------------
// APB接口输入信号采样
// -----------------------------------
reg psel_stage1, psel_stage2;
reg penable_stage1, penable_stage2;
reg pwrite_stage1, pwrite_stage2;
reg [ADDR_WIDTH-1:0] paddr_stage1, paddr_stage2;
reg [31:0] pwdata_stage1, pwdata_stage2;

// -----------------------------------
// PRDATA输出寄存器
// -----------------------------------
reg [31:0] prdata_stage1, prdata_stage2, prdata_out;

// -----------------------------------
// 写使能信号优化
// -----------------------------------
wire write_ctrl_reg  = (apb_state_stage1 == ACCESS) && PWRITE && (PADDR == 4'h0);
wire write_baud_reg  = (apb_state_stage1 == ACCESS) && PWRITE && (PADDR == 4'h4);
wire write_tx_reg    = (apb_state_stage1 == ACCESS) && PWRITE && (PADDR == 4'h8);

// -----------------------------------
// 读选择信号优化
// -----------------------------------
wire read_access = (apb_state_stage2 == ACCESS) && !pwrite_stage2;
wire [2:0] addr_sel = { (paddr_stage2[4] | paddr_stage2[3]), paddr_stage2[2:1] }; // 3位地址选择

// -----------------------------------
// 流水线启动和复位
// -----------------------------------
always @(posedge PCLK or negedge PRESETn) begin
    if (!PRESETn) begin
        ctrl_reg_stage1         <= 8'h00;
        stat_reg_stage1         <= 8'h00;
        baud_reg_stage1         <= 16'h0000;
        tx_reg_stage1           <= 8'h00;
        rx_reg_stage1           <= 8'h00;
        tx_empty_irq_en_stage1  <= 1'b0;
        rx_full_irq_en_stage1   <= 1'b0;
        error_irq_en_stage1     <= 3'b000;
        tx_empty_stage1         <= 1'b1;
        rx_full_stage1          <= 1'b0;
        apb_state_stage1        <= IDLE;
        valid_stage1            <= 1'b0;
        flush_stage1            <= 1'b0;
        psel_stage1             <= 1'b0;
        penable_stage1          <= 1'b0;
        pwrite_stage1           <= 1'b0;
        paddr_stage1            <= {ADDR_WIDTH{1'b0}};
        pwdata_stage1           <= 32'h0;
        prdata_stage1           <= 32'h0;

        ctrl_reg_stage2         <= 8'h00;
        stat_reg_stage2         <= 8'h00;
        baud_reg_stage2         <= 16'h0000;
        tx_reg_stage2           <= 8'h00;
        rx_reg_stage2           <= 8'h00;
        tx_empty_irq_en_stage2  <= 1'b0;
        rx_full_irq_en_stage2   <= 1'b0;
        error_irq_en_stage2     <= 3'b000;
        tx_empty_stage2         <= 1'b1;
        rx_full_stage2          <= 1'b0;
        apb_state_stage2        <= IDLE;
        valid_stage2            <= 1'b0;
        flush_stage2            <= 1'b0;
        psel_stage2             <= 1'b0;
        penable_stage2          <= 1'b0;
        pwrite_stage2           <= 1'b0;
        paddr_stage2            <= {ADDR_WIDTH{1'b0}};
        pwdata_stage2           <= 32'h0;
        prdata_stage2           <= 32'h0;

        prdata_out              <= 32'h0;
    end else begin
        // 一级流水段
        psel_stage1    <= PSEL;
        penable_stage1 <= PENABLE;
        pwrite_stage1  <= PWRITE;
        paddr_stage1   <= PADDR;
        pwdata_stage1  <= PWDATA;

        valid_stage1   <= 1'b1;
        flush_stage1   <= 1'b0;

        case (apb_state_stage1)
            IDLE:   apb_state_stage1 <= (PSEL && !PENABLE) ? SETUP : IDLE;
            SETUP:  apb_state_stage1 <= ACCESS;
            ACCESS: apb_state_stage1 <= IDLE;
            default: apb_state_stage1 <= IDLE;
        endcase

        // 写操作优化
        ctrl_reg_stage1        <= (write_ctrl_reg) ? PWDATA[7:0]  : ctrl_reg_stage2;
        baud_reg_stage1        <= (write_baud_reg) ? PWDATA[15:0] : baud_reg_stage2;
        tx_reg_stage1          <= (write_tx_reg)   ? PWDATA[7:0]  : tx_reg_stage2;
        rx_reg_stage1          <= rx_reg_stage2;
        stat_reg_stage1        <= stat_reg_stage2;
        tx_empty_irq_en_stage1 <= tx_empty_irq_en_stage2;
        rx_full_irq_en_stage1  <= rx_full_irq_en_stage2;
        error_irq_en_stage1    <= error_irq_en_stage2;
        tx_empty_stage1        <= tx_empty_stage2;
        rx_full_stage1         <= rx_full_stage2;

        // 二级流水段
        psel_stage2    <= psel_stage1;
        penable_stage2 <= penable_stage1;
        pwrite_stage2  <= pwrite_stage1;
        paddr_stage2   <= paddr_stage1;
        pwdata_stage2  <= pwdata_stage1;

        valid_stage2   <= valid_stage1;
        flush_stage2   <= flush_stage1;

        apb_state_stage2 <= apb_state_stage1;

        ctrl_reg_stage2        <= ctrl_reg_stage1;
        baud_reg_stage2        <= baud_reg_stage1;
        tx_reg_stage2          <= tx_reg_stage1;
        rx_reg_stage2          <= rx_reg_stage1;
        stat_reg_stage2        <= stat_reg_stage1;
        tx_empty_irq_en_stage2 <= tx_empty_irq_en_stage1;
        rx_full_irq_en_stage2  <= rx_full_irq_en_stage1;
        error_irq_en_stage2    <= error_irq_en_stage1;
        tx_empty_stage2        <= tx_empty_stage1;
        rx_full_stage2         <= rx_full_stage1;

        // 优化后的读操作
        prdata_stage2 <= 32'h0;
        if (read_access) begin
            casez (addr_sel)
                3'b000: prdata_stage2 <= {24'h0, ctrl_reg_stage2};        // 0x0
                3'b001: prdata_stage2 <= {16'h0, baud_reg_stage2};        // 0x4
                3'b010: prdata_stage2 <= {24'h0, tx_reg_stage2};          // 0x8
                3'b011: prdata_stage2 <= {24'h0, rx_reg_stage2};          // 0xC
                3'b100: prdata_stage2 <= {24'h0, stat_reg_stage2};        // 0x10
                default: prdata_stage2 <= 32'h0;
            endcase
        end

        prdata_out <= prdata_stage2;
    end
end

assign PRDATA = prdata_out;
assign PREADY = (apb_state_stage2 == ACCESS) && valid_stage2;
assign irq = (tx_empty_irq_en_stage2 & tx_empty_stage2) | (rx_full_irq_en_stage2 & rx_full_stage2);
assign txd = tx_reg_stage2[0];

endmodule