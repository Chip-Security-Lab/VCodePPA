//SystemVerilog
module UART_HW_FlowControl #(
    parameter FLOW_THRESH = 4
)(
    input  wire clk,
    input  wire rst_n,
    output wire rts,
    input  wire cts,
    input  wire [7:0] tx_fifo_space,
    input  wire [7:0] rx_fifo_used,
    input  wire tx_valid,
    output wire tx_fifo_wr
);

    // Internal wires and registers
    wire cts_sync;
    wire tx_allow_comb;
    wire tx_fifo_empty_comb;
    wire tx_fifo_wr_comb;
    wire [0:0] next_flow_state_comb;

    reg flow_state_reg;
    reg tx_allow_reg;
    reg tx_fifo_empty_reg;
    reg tx_fifo_wr_reg;

    // CTS Synchronizer
    wire cts_sync_ff2_out;

    CTS_Synchronizer u_cts_sync (
        .clk(clk),
        .rst_n(rst_n),
        .cts_in(cts),
        .cts_sync_out(cts_sync)
    );

    // Flow Control Combinational Logic
    UART_FlowControlComb #(
        .FLOW_THRESH(FLOW_THRESH)
    ) u_flow_comb (
        .flow_state(flow_state_reg),
        .cts_sync(cts_sync),
        .tx_fifo_space(tx_fifo_space),
        .tx_valid(tx_valid),
        .tx_fifo_empty_reg(tx_fifo_empty_reg),
        .tx_allow_reg(tx_allow_reg),
        .next_flow_state(next_flow_state_comb),
        .tx_allow_comb(tx_allow_comb),
        .tx_fifo_empty_comb(tx_fifo_empty_comb),
        .tx_fifo_wr_comb(tx_fifo_wr_comb)
    );

    // Sequential Logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            flow_state_reg      <= 1'b0;
            tx_allow_reg        <= 1'b0;
            tx_fifo_empty_reg   <= 1'b1;
            tx_fifo_wr_reg      <= 1'b0;
        end else begin
            flow_state_reg      <= next_flow_state_comb;
            tx_allow_reg        <= tx_allow_comb;
            tx_fifo_empty_reg   <= tx_fifo_empty_comb;
            tx_fifo_wr_reg      <= tx_fifo_wr_comb;
        end
    end

    assign tx_fifo_wr = tx_fifo_wr_reg;
    assign rts = (rx_fifo_used <= FLOW_THRESH);

endmodule

// CTS Synchronizer Module
module CTS_Synchronizer (
    input  wire clk,
    input  wire rst_n,
    input  wire cts_in,
    output wire cts_sync_out
);
    reg cts_sync_ff1, cts_sync_ff2;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cts_sync_ff1 <= 1'b0;
            cts_sync_ff2 <= 1'b0;
        end else begin
            cts_sync_ff1 <= cts_in;
            cts_sync_ff2 <= cts_sync_ff1;
        end
    end
    assign cts_sync_out = cts_sync_ff2;
endmodule

// Combinational Flow Control Logic Module
module UART_FlowControlComb #(
    parameter FLOW_THRESH = 4
)(
    input  wire        flow_state,
    input  wire        cts_sync,
    input  wire [7:0]  tx_fifo_space,
    input  wire        tx_valid,
    input  wire        tx_fifo_empty_reg,
    input  wire        tx_allow_reg,
    output wire [0:0]  next_flow_state,
    output wire        tx_allow_comb,
    output wire        tx_fifo_empty_comb,
    output wire        tx_fifo_wr_comb
);
    // State encoding
    localparam FLOW_IDLE = 1'b0;
    localparam FLOW_HOLD = 1'b1;

    // Next state logic
    reg next_state_r;
    always @(*) begin
        next_state_r = flow_state;
        case(flow_state)
            FLOW_IDLE:
                if (!cts_sync)
                    next_state_r = FLOW_HOLD;
            FLOW_HOLD:
                if (tx_fifo_empty_reg)
                    next_state_r = FLOW_IDLE;
            default:
                next_state_r = FLOW_IDLE;
        endcase
    end
    assign next_flow_state = next_state_r;

    // tx_allow combinational logic
    assign tx_allow_comb = (tx_fifo_space > FLOW_THRESH) && cts_sync;

    // tx_fifo_empty combinational logic
    assign tx_fifo_empty_comb = (tx_fifo_space == 8'hFF);

    // tx_fifo_wr combinational logic
    assign tx_fifo_wr_comb = (tx_allow_reg && tx_valid);

endmodule