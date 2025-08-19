//SystemVerilog
module UART_HW_FlowControl #(
    parameter FLOW_THRESH = 4  // FIFO threshold
)(
    input  wire         clk,
    input  wire         rst_n,
    output wire         rts,              // Request to send
    input  wire         cts,              // Clear to send
    input  wire [7:0]   tx_fifo_space,
    input  wire [7:0]   rx_fifo_used,
    input  wire         tx_valid,
    output wire         tx_fifo_wr
);

    //==================== Combination Logic Declarations ====================
    wire                cts_synced_comb;
    wire [7:0]          tx_fifo_space_comb;
    wire [7:0]          rx_fifo_used_comb;
    wire signed [7:0]   signed_tx_fifo_space_comb;
    wire signed [7:0]   signed_flow_thresh_comb;
    wire signed [15:0]  mult_result_comb;
    wire                tx_allow_comb;
    wire                tx_fifo_empty_comb;
    wire                rts_comb;
    wire                next_flow_state_comb;
    wire                tx_fifo_wr_comb;

    //==================== Synchronization Registers ====================
    reg   cts_sync_stage1_reg, cts_sync_stage2_reg;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cts_sync_stage1_reg <= 1'b0;
            cts_sync_stage2_reg <= 1'b0;
        end else begin
            cts_sync_stage1_reg <= cts;
            cts_sync_stage2_reg <= cts_sync_stage1_reg;
        end
    end
    assign cts_synced_comb = cts_sync_stage2_reg;

    //==================== Pipeline Stage 2 Registers ====================
    reg [7:0] tx_fifo_space_stage2_reg;
    reg [7:0] rx_fifo_used_stage2_reg;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            tx_fifo_space_stage2_reg <= 8'd0;
            rx_fifo_used_stage2_reg  <= 8'd0;
        end else begin
            tx_fifo_space_stage2_reg <= tx_fifo_space;
            rx_fifo_used_stage2_reg  <= rx_fifo_used;
        end
    end
    assign tx_fifo_space_comb = tx_fifo_space_stage2_reg;
    assign rx_fifo_used_comb  = rx_fifo_used_stage2_reg;

    //==================== Pipeline Stage 3 Registers ====================
    reg signed [7:0] signed_tx_fifo_space_stage3_reg;
    reg signed [7:0] signed_flow_thresh_stage3_reg;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            signed_tx_fifo_space_stage3_reg <= 8'sd0;
            signed_flow_thresh_stage3_reg   <= 8'sd0;
        end else begin
            signed_tx_fifo_space_stage3_reg <= tx_fifo_space_comb;
            signed_flow_thresh_stage3_reg   <= FLOW_THRESH;
        end
    end
    assign signed_tx_fifo_space_comb = signed_tx_fifo_space_stage3_reg;
    assign signed_flow_thresh_comb   = signed_flow_thresh_stage3_reg;

    //==================== Booth Multiplier (Combinational Module) ====================
    wire signed [15:0] booth_mult_result_wire;
    BoothSignedMult8 booth_mult_inst (
        .a (signed_tx_fifo_space_comb),
        .b (signed_flow_thresh_comb),
        .product (booth_mult_result_wire)
    );

    //==================== Pipeline Stage 4 Registers ====================
    reg signed [15:0] mult_result_stage4_reg;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            mult_result_stage4_reg <= 16'sd0;
        end else begin
            mult_result_stage4_reg <= booth_mult_result_wire;
        end
    end
    assign mult_result_comb = mult_result_stage4_reg;

    //==================== Pipeline Stage 5 Registers ====================
    reg tx_allow_stage5_reg;
    reg tx_fifo_empty_stage5_reg;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            tx_allow_stage5_reg      <= 1'b0;
            tx_fifo_empty_stage5_reg <= 1'b1;
        end else begin
            tx_allow_stage5_reg      <= (mult_result_comb > 16'sd0) && cts_synced_comb;
            tx_fifo_empty_stage5_reg <= (tx_fifo_space_comb == 8'hFF);
        end
    end
    assign tx_allow_comb      = tx_allow_stage5_reg;
    assign tx_fifo_empty_comb = tx_fifo_empty_stage5_reg;

    //==================== TX Valid Pipeline Register ====================
    reg tx_valid_stage6_reg;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            tx_valid_stage6_reg <= 1'b0;
        else
            tx_valid_stage6_reg <= tx_valid;
    end

    //==================== TX FIFO Write Enable Combinational ====================
    assign tx_fifo_wr_comb = tx_allow_comb && tx_valid_stage6_reg;

    //==================== TX FIFO Write Enable Register ====================
    reg tx_fifo_wr_stage7_reg;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            tx_fifo_wr_stage7_reg <= 1'b0;
        else
            tx_fifo_wr_stage7_reg <= tx_fifo_wr_comb;
    end
    assign tx_fifo_wr = tx_fifo_wr_stage7_reg;

    //==================== RX Flow Control Combinational Logic ====================
    assign rts_comb = (rx_fifo_used_comb <= FLOW_THRESH);

    //==================== RX Flow Control Registers ====================
    reg rts_stage1_reg, rts_stage2_reg;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rts_stage1_reg <= 1'b1;
            rts_stage2_reg <= 1'b1;
        end else begin
            rts_stage1_reg <= rts_comb;
            rts_stage2_reg <= rts_stage1_reg;
        end
    end
    assign rts = rts_stage2_reg;

    //==================== Flow Control FSM States ====================
    localparam FLOW_IDLE = 1'b0;
    localparam FLOW_HOLD = 1'b1;

    reg flow_state_stage1_reg, flow_state_stage2_reg;

    //==================== Flow Control FSM Next State Combinational ====================
    assign next_flow_state_comb = (flow_state_stage2_reg == FLOW_IDLE) ?
                                  (~cts_synced_comb ? FLOW_HOLD : FLOW_IDLE) :
                                  (tx_fifo_empty_comb ? FLOW_IDLE : FLOW_HOLD);

    //==================== Flow Control FSM Registers ====================
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            flow_state_stage1_reg <= FLOW_IDLE;
            flow_state_stage2_reg <= FLOW_IDLE;
        end else begin
            flow_state_stage1_reg <= next_flow_state_comb;
            flow_state_stage2_reg <= flow_state_stage1_reg;
        end
    end

endmodule

//==================== Booth Multiplier Submodule ====================
module BoothSignedMult8 (
    input  wire signed [7:0] a,
    input  wire signed [7:0] b,
    output wire signed [15:0] product
);
    reg signed [15:0] prod;
    reg signed [8:0]  mcand;
    reg signed [16:0] acc;
    integer i;

    always @(*) begin
        prod = 16'sd0;
        mcand = {a[7], a};
        acc = 17'sd0;
        acc[8:1] = b;
        acc[0] = 1'b0;
        for (i=0; i<8; i=i+1) begin
            case (acc[1:0])
                2'b01: prod = prod + (mcand <<< i);
                2'b10: prod = prod - (mcand <<< i);
                default: prod = prod;
            endcase
            acc = acc >>> 1;
        end
    end

    assign product = prod;
endmodule