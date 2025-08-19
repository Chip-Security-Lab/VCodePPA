//SystemVerilog
module UART_APB_Interface #(
    parameter ADDR_WIDTH = 4,
    parameter REG_FILE = 8
)(
    input  wire                  PCLK,
    input  wire                  PRESETn,
    input  wire [ADDR_WIDTH-1:0] PADDR,
    input  wire                  PSEL,
    input  wire                  PENABLE,
    input  wire                  PWRITE,
    input  wire [31:0]           PWDATA,
    output wire [31:0]           PRDATA,
    output wire                  PREADY,
    output wire                  txd,
    input  wire                  rxd,
    output wire                  irq
);

    //==================================================================
    // Address decode and register interface signals
    //==================================================================
    wire addr_ctrl  = (PADDR == 4'h0);
    wire addr_baud  = (PADDR == 4'h4);
    wire addr_tx    = (PADDR == 4'h8);
    wire addr_rx    = (PADDR == 4'hC);
    wire addr_stat  = (PADDR == 4'h10);

    wire wr_ctrl    = PWRITE & addr_ctrl;
    wire wr_baud    = PWRITE & addr_baud;
    wire wr_tx      = PWRITE & addr_tx;

    wire rd_ctrl    = ~PWRITE & addr_ctrl;
    wire rd_baud    = ~PWRITE & addr_baud;
    wire rd_tx      = ~PWRITE & addr_tx;
    wire rd_rx      = ~PWRITE & addr_rx;
    wire rd_stat    = ~PWRITE & addr_stat;

    //==================================================================
    // APB Protocol State Machine (Stage 0)
    //==================================================================
    localparam APB_IDLE   = 2'b00;
    localparam APB_SETUP  = 2'b01;
    localparam APB_ACCESS = 2'b10;

    reg [1:0] apb_state_stage0, apb_state_stage1;

    always @(posedge PCLK or negedge PRESETn) begin
        if (!PRESETn) begin
            apb_state_stage0 <= APB_IDLE;
        end else begin
            case (apb_state_stage0)
                APB_IDLE:   apb_state_stage0 <= (PSEL && !PENABLE) ? APB_SETUP : APB_IDLE;
                APB_SETUP:  apb_state_stage0 <= APB_ACCESS;
                APB_ACCESS: apb_state_stage0 <= APB_IDLE;
                default:    apb_state_stage0 <= APB_IDLE;
            endcase
        end
    end

    // Pipeline APB state for timing isolation (Stage 1)
    always @(posedge PCLK or negedge PRESETn) begin
        if (!PRESETn)
            apb_state_stage1 <= APB_IDLE;
        else
            apb_state_stage1 <= apb_state_stage0;
    end

    //==================================================================
    // Register Bank (Stage 1): Pipeline for write/read
    //==================================================================
    reg [7:0]  ctrl_reg_q,   ctrl_reg_d;
    reg [7:0]  stat_reg_q,   stat_reg_d;
    reg [15:0] baud_reg_q,   baud_reg_d;
    reg [7:0]  tx_reg_q,     tx_reg_d;
    reg [7:0]  rx_reg_q,     rx_reg_d;

    // Interrupt enable
    reg        tx_empty_irq_en_q, tx_empty_irq_en_d;
    reg        rx_full_irq_en_q,  rx_full_irq_en_d;
    reg [2:0]  error_irq_en_q,    error_irq_en_d;

    // TX/RX status
    reg        tx_empty_q,        tx_empty_d;
    reg        rx_full_q,         rx_full_d;

    // Write logic (Stage 1)
    always @* begin
        ctrl_reg_d         = ctrl_reg_q;
        stat_reg_d         = stat_reg_q;
        baud_reg_d         = baud_reg_q;
        tx_reg_d           = tx_reg_q;
        rx_reg_d           = rx_reg_q;
        tx_empty_irq_en_d  = tx_empty_irq_en_q;
        rx_full_irq_en_d   = rx_full_irq_en_q;
        error_irq_en_d     = error_irq_en_q;
        tx_empty_d         = tx_empty_q;
        rx_full_d          = rx_full_q;

        if (apb_state_stage0 == APB_ACCESS && PWRITE) begin
            if (addr_ctrl) begin
                ctrl_reg_d        = PWDATA[7:0];
                tx_empty_irq_en_d = PWDATA[8];
                rx_full_irq_en_d  = PWDATA[9];
                error_irq_en_d    = PWDATA[12:10];
            end else if (addr_baud) begin
                baud_reg_d        = PWDATA[15:0];
            end else if (addr_tx) begin
                tx_reg_d          = PWDATA[7:0];
                tx_empty_d        = 1'b0; // Assume TX FIFO is not empty after write
            end
            // RX register is typically read-only via APB
        end

        // Example status update (this would be replaced by real UART logic)
        if (apb_state_stage0 == APB_ACCESS && addr_tx && PWRITE)
            tx_empty_d = 1'b0;
        else if (/* UART TX completed condition here */ 1'b0)
            tx_empty_d = 1'b1;

        if (apb_state_stage0 == APB_ACCESS && addr_rx && ~PWRITE)
            rx_full_d = 1'b0;
        else if (/* UART RX completed condition here */ 1'b0)
            rx_full_d = 1'b1;

        // stat_reg could be updated by UART hardware
        stat_reg_d = {5'b0, error_irq_en_q, rx_full_q, tx_empty_q};
    end

    always @(posedge PCLK or negedge PRESETn) begin
        if (!PRESETn) begin
            ctrl_reg_q         <= 8'h00;
            stat_reg_q         <= 8'h00;
            baud_reg_q         <= 16'h0000;
            tx_reg_q           <= 8'h00;
            rx_reg_q           <= 8'h00;
            tx_empty_irq_en_q  <= 1'b0;
            rx_full_irq_en_q   <= 1'b0;
            error_irq_en_q     <= 3'b000;
            tx_empty_q         <= 1'b1;
            rx_full_q          <= 1'b0;
        end else begin
            ctrl_reg_q         <= ctrl_reg_d;
            stat_reg_q         <= stat_reg_d;
            baud_reg_q         <= baud_reg_d;
            tx_reg_q           <= tx_reg_d;
            rx_reg_q           <= rx_reg_d;
            tx_empty_irq_en_q  <= tx_empty_irq_en_d;
            rx_full_irq_en_q   <= rx_full_irq_en_d;
            error_irq_en_q     <= error_irq_en_d;
            tx_empty_q         <= tx_empty_d;
            rx_full_q          <= rx_full_d;
        end
    end

    //==================================================================
    // Read Data Mux (Stage 2): Isolated pipeline readback
    //==================================================================
    reg [31:0] prdata_stage2;

    always @(*) begin
        case (1'b1)
            rd_ctrl: prdata_stage2 = {24'h0, ctrl_reg_q};
            rd_baud: prdata_stage2 = {16'h0, baud_reg_q};
            rd_tx:   prdata_stage2 = {24'h0, tx_reg_q};
            rd_rx:   prdata_stage2 = {24'h0, rx_reg_q};
            rd_stat: prdata_stage2 = {24'h0, stat_reg_q};
            default: prdata_stage2 = 32'h0;
        endcase
    end

    reg [31:0] prdata_q;
    always @(posedge PCLK or negedge PRESETn) begin
        if (!PRESETn)
            prdata_q <= 32'h0;
        else if (apb_state_stage1 == APB_ACCESS && !PWRITE)
            prdata_q <= prdata_stage2;
    end

    assign PRDATA = prdata_q;

    //==================================================================
    // APB Ready signal - one cycle after access phase
    //==================================================================
    reg pready_q;
    always @(posedge PCLK or negedge PRESETn) begin
        if (!PRESETn)
            pready_q <= 1'b0;
        else
            pready_q <= (apb_state_stage1 == APB_ACCESS);
    end

    assign PREADY = pready_q;

    //==================================================================
    // IRQ Output logic (Stage 2)
    //==================================================================
    reg irq_q;
    always @(posedge PCLK or negedge PRESETn) begin
        if (!PRESETn)
            irq_q <= 1'b0;
        else
            irq_q <= (tx_empty_irq_en_q & tx_empty_q) | (rx_full_irq_en_q & rx_full_q);
    end

    assign irq = irq_q;

    //==================================================================
    // TX Output (Simplified)
    //==================================================================
    assign txd = tx_reg_q[0];

endmodule