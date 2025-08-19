//SystemVerilog
module UART_HW_FlowControl #(
    parameter FLOW_THRESH = 4
)(
    input  wire        clk,
    input  wire        rst_n,
    output wire        rts,              // Ready To Send (output to peer)
    input  wire        cts,              // Clear To Send (input from peer)
    input  wire [7:0]  tx_fifo_space,    // FIFO space available for TX
    input  wire [7:0]  rx_fifo_used,     // FIFO used entries for RX
    input  wire        tx_valid,         // TX valid flag
    output reg         tx_fifo_wr        // TX FIFO write enable
);

    //==========================================================================
    // 1. Input Synchronization Stage
    //==========================================================================

    reg cts_sync_ff1, cts_sync_ff2;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cts_sync_ff1 <= 1'b0;
            cts_sync_ff2 <= 1'b0;
        end else begin
            cts_sync_ff1 <= cts;
            cts_sync_ff2 <= cts_sync_ff1;
        end
    end
    wire cts_sync = cts_sync_ff2;

    //==========================================================================
    // 2. Pipeline Stage 1: FIFO Status Registration
    //==========================================================================

    reg [7:0] tx_fifo_space_q;
    reg [7:0] rx_fifo_used_q;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            tx_fifo_space_q <= 8'd0;
            rx_fifo_used_q  <= 8'd0;
        end else begin
            tx_fifo_space_q <= tx_fifo_space;
            rx_fifo_used_q  <= rx_fifo_used;
        end
    end

    //==========================================================================
    // 3. Pipeline Stage 2: Control Signal Calculation (Path Balanced)
    //==========================================================================

    // Precompute comparison results for path balancing
    wire tx_fifo_space_gt_thresh = (tx_fifo_space_q > FLOW_THRESH);
    wire rx_fifo_used_le_thresh = (rx_fifo_used_q <= FLOW_THRESH);
    wire tx_fifo_space_eq_ff    = (tx_fifo_space_q == 8'hFF);

    // Registered TX FIFO empty flag
    reg tx_fifo_empty_q;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            tx_fifo_empty_q <= 1'b1;
        else
            tx_fifo_empty_q <= tx_fifo_space_eq_ff;
    end

    // Registered TX allow signal
    reg tx_allow_q;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            tx_allow_q <= 1'b0;
        else
            tx_allow_q <= tx_fifo_space_gt_thresh & cts_sync;
    end

    // Registered RX ready signal
    reg rx_ready_q;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            rx_ready_q <= 1'b0;
        else
            rx_ready_q <= rx_fifo_used_le_thresh;
    end

    //==========================================================================
    // 4. Pipeline Stage 3: Flow Control State Machine (Path Balanced)
    //==========================================================================

    localparam FLOW_IDLE = 1'b0;
    localparam FLOW_HOLD = 1'b1;

    reg flow_state_q;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            flow_state_q <= FLOW_IDLE;
        else
            flow_state_q <= ((flow_state_q == FLOW_IDLE) && !cts_sync) ? FLOW_HOLD :
                            ((flow_state_q == FLOW_HOLD) && tx_fifo_empty_q) ? FLOW_IDLE :
                            flow_state_q;
    end

    //==========================================================================
    // 5. Pipeline Stage 4: TX FIFO Write Enable Generation (Path Balanced)
    //==========================================================================

    wire tx_fifo_wr_next = tx_allow_q & tx_valid;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            tx_fifo_wr <= 1'b0;
        else
            tx_fifo_wr <= tx_fifo_wr_next;
    end

    //==========================================================================
    // 6. Output Assignment
    //==========================================================================

    assign rts = rx_ready_q;

endmodule