//SystemVerilog
module UART_HW_FlowControl #(
    parameter FLOW_THRESH = 4  // FIFO threshold
)(
    input  wire        clk,
    input  wire        rst_n,
    output wire        rts,         // Request to send
    input  wire        cts,         // Clear to send
    input  wire [7:0]  tx_fifo_space,
    input  wire [7:0]  rx_fifo_used,
    input  wire        tx_valid,
    output reg         tx_fifo_wr
);

// -----------------------------------------------------------------------------
// Stage 1: Synchronize CTS, capture FIFO states, and calculate conditions
// -----------------------------------------------------------------------------
reg cts_sync_stage1, cts_sync_stage2;
reg [7:0] tx_fifo_space_stage1;
reg [7:0] rx_fifo_used_stage1;
reg       tx_valid_stage1;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        cts_sync_stage1        <= 1'b0;
        cts_sync_stage2        <= 1'b0;
        tx_fifo_space_stage1   <= 8'd0;
        rx_fifo_used_stage1    <= 8'd0;
        tx_valid_stage1        <= 1'b0;
    end else begin
        cts_sync_stage1        <= cts;
        cts_sync_stage2        <= cts_sync_stage1;
        tx_fifo_space_stage1   <= tx_fifo_space;
        rx_fifo_used_stage1    <= rx_fifo_used;
        tx_valid_stage1        <= tx_valid;
    end
end

wire cts_sync = cts_sync_stage2;

reg tx_allow_stage1, rts_stage1, tx_fifo_empty_stage1;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        tx_allow_stage1      <= 1'b0;
        rts_stage1           <= 1'b0;
        tx_fifo_empty_stage1 <= 1'b1;
    end else begin
        tx_allow_stage1      <= (tx_fifo_space_stage1 > FLOW_THRESH) && cts_sync;
        rts_stage1           <= (rx_fifo_used_stage1 <= FLOW_THRESH);
        tx_fifo_empty_stage1 <= (tx_fifo_space_stage1 == 8'hFF);
    end
end

// -----------------------------------------------------------------------------
// Stage 2: State machine and tx_fifo_wr generation
// -----------------------------------------------------------------------------
localparam FLOW_IDLE = 1'b0;
localparam FLOW_HOLD = 1'b1;

reg flow_state_stage2, flow_state_stage2_next;
reg tx_valid_stage2;
reg tx_allow_stage2;
reg tx_fifo_empty_stage2;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        tx_valid_stage2      <= 1'b0;
        tx_allow_stage2      <= 1'b0;
        tx_fifo_empty_stage2 <= 1'b1;
    end else begin
        tx_valid_stage2      <= tx_valid_stage1;
        tx_allow_stage2      <= tx_allow_stage1;
        tx_fifo_empty_stage2 <= tx_fifo_empty_stage1;
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        flow_state_stage2 <= FLOW_IDLE;
    end else begin
        flow_state_stage2 <= flow_state_stage2_next;
    end
end

always @(*) begin
    if ((flow_state_stage2 == FLOW_IDLE) && (!tx_allow_stage2)) begin
        flow_state_stage2_next = FLOW_HOLD;
    end else if ((flow_state_stage2 == FLOW_HOLD) && (tx_fifo_empty_stage2)) begin
        flow_state_stage2_next = FLOW_IDLE;
    end else begin
        flow_state_stage2_next = flow_state_stage2;
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        tx_fifo_wr <= 1'b0;
    end else begin
        if (tx_allow_stage2 && tx_valid_stage2)
            tx_fifo_wr <= 1'b1;
        else
            tx_fifo_wr <= 1'b0;
    end
end

// -----------------------------------------------------------------------------
// Output assignment (final pipeline stage for rts)
// -----------------------------------------------------------------------------
reg rts_stage2;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        rts_stage2 <= 1'b0;
    end else begin
        rts_stage2 <= rts_stage1;
    end
end

assign rts = rts_stage2;

endmodule