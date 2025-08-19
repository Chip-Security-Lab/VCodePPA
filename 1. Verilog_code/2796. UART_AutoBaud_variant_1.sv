//SystemVerilog
//IEEE 1364-2005 Verilog
module UART_AutoBaud #(
    parameter MIN_BAUD = 9600,
    parameter CLK_FREQ = 100_000_000
)(
    input  wire clk,
    input  wire rst_n,
    input  wire rxd,
    input  wire auto_br_en,
    output reg  [15:0] detected_br,
    output reg         baud_tick
);

    // ----------- Stage 1: RXD Synchronization and Edge Detection Pipeline ----------- //
    wire        sync_rxd_stage1;
    wire        sync_rxd_stage2;
    wire        sync_rxd_falling;
    wire        sync_rxd_rising;

    // RXD synchronization registers moved after edge detection logic (forward retiming)
    wire        rxd_falling_comb;
    wire        rxd_rising_comb;
    UART_AutoBaud_RxSyncEdge_Comb rx_sync_edge_pipe (
        .clk            (clk),
        .rst_n          (rst_n),
        .rxd            (rxd),
        .rxd_sync1      (sync_rxd_stage1),
        .rxd_sync2      (sync_rxd_stage2),
        .rxd_falling_comb (rxd_falling_comb),
        .rxd_rising_comb  (rxd_rising_comb)
    );

    // Forward retimed registers for edge detection outputs
    reg sync_rxd_falling_reg, sync_rxd_rising_reg;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sync_rxd_falling_reg <= 1'b0;
            sync_rxd_rising_reg  <= 1'b0;
        end else begin
            sync_rxd_falling_reg <= rxd_falling_comb;
            sync_rxd_rising_reg  <= rxd_rising_comb;
        end
    end

    assign sync_rxd_falling = sync_rxd_falling_reg;
    assign sync_rxd_rising  = sync_rxd_rising_reg;

    // ----------- Stage 2: Baudrate FSM Pipeline ----------- //
    reg  [1:0]  fsm_state_reg,  fsm_state_next;
    reg  [31:0] edge_count_reg, edge_count_next;
    reg  [15:0] detected_br_reg, detected_br_next;
    reg  [15:0] manual_br_reg, manual_br_next;

    UART_AutoBaud_FSM_Pipeline #(
        .CLK_FREQ (CLK_FREQ)
    ) baud_fsm_pipe (
        .clk                (clk),
        .rst_n              (rst_n),
        .state_in           (fsm_state_reg),
        .edge_count_in      (edge_count_reg),
        .detected_br_in     (detected_br_reg),
        .manual_br_in       (manual_br_reg),
        .auto_br_en         (auto_br_en),
        .rxd_falling        (sync_rxd_falling),
        .rxd_rising         (sync_rxd_rising),
        .state_out          (fsm_state_next),
        .edge_count_out     (edge_count_next),
        .detected_br_out    (detected_br_next),
        .manual_br_out      (manual_br_next)
    );

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            fsm_state_reg    <= 2'b00;
            edge_count_reg   <= 32'd0;
            detected_br_reg  <= 16'd0;
            manual_br_reg    <= 16'd0;
        end else begin
            fsm_state_reg    <= fsm_state_next;
            edge_count_reg   <= edge_count_next;
            detected_br_reg  <= detected_br_next;
            manual_br_reg    <= manual_br_next;
        end
    end

    // ----------- Stage 3: Baudrate Selection Pipeline ----------- //
    wire [15:0] selected_baudrate;
    assign selected_baudrate = auto_br_en ? detected_br_reg : manual_br_reg;

    // ----------- Stage 4: Baudrate Counter Pipeline ----------- //
    reg  [15:0] baud_cnt_reg, baud_cnt_next;
    wire        baud_tick_stage;

    UART_AutoBaud_BaudCounter_Pipeline baud_counter_pipe (
        .clk                (clk),
        .rst_n              (rst_n),
        .baud_counter_in    (baud_cnt_reg),
        .baudrate_in        (selected_baudrate),
        .baud_counter_out   (baud_cnt_next),
        .baud_tick_out      (baud_tick_stage)
    );

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            baud_cnt_reg <= 16'd0;
            baud_tick    <= 1'b0;
        end else begin
            baud_cnt_reg <= baud_cnt_next;
            baud_tick    <= baud_tick_stage;
        end
    end

    // ----------- Output Register Pipeline ----------- //
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            detected_br <= 16'd0;
        else
            detected_br <= detected_br_reg;
    end

endmodule

// ----------- RXD Synchronization and Edge Detection Pipeline Stage ----------- //
// Forward retimed: registers are after edge-detect combinational logic
module UART_AutoBaud_RxSyncEdge_Comb (
    input  wire clk,
    input  wire rst_n,
    input  wire rxd,
    output wire rxd_sync1,
    output wire rxd_sync2,
    output wire rxd_falling_comb,
    output wire rxd_rising_comb
);
    reg rxd_sync1_reg, rxd_sync2_reg;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rxd_sync1_reg <= 1'b1;
            rxd_sync2_reg <= 1'b1;
        end else begin
            rxd_sync1_reg <= rxd;
            rxd_sync2_reg <= rxd_sync1_reg;
        end
    end

    assign rxd_sync1 = rxd_sync1_reg;
    assign rxd_sync2 = rxd_sync2_reg;
    assign rxd_falling_comb =  rxd_sync2_reg & ~rxd_sync1_reg;
    assign rxd_rising_comb  = ~rxd_sync2_reg &  rxd_sync1_reg;
endmodule

// ----------- Baudrate FSM Pipeline Stage ----------- //
module UART_AutoBaud_FSM_Pipeline #(
    parameter CLK_FREQ = 100_000_000
)(
    input  wire        clk,
    input  wire        rst_n,
    input  wire [1:0]  state_in,
    input  wire [31:0] edge_count_in,
    input  wire [15:0] detected_br_in,
    input  wire [15:0] manual_br_in,
    input  wire        auto_br_en,
    input  wire        rxd_falling,
    input  wire        rxd_rising,
    output reg  [1:0]  state_out,
    output reg  [31:0] edge_count_out,
    output reg  [15:0] detected_br_out,
    output reg  [15:0] manual_br_out
);

    always @(*) begin
        // Default assignments
        state_out        = state_in;
        edge_count_out   = edge_count_in;
        detected_br_out  = detected_br_in;
        manual_br_out    = manual_br_in;

        case (state_in)
            2'b00: begin // BAUD_IDLE
                if (rxd_falling && auto_br_en) begin
                    state_out        = 2'b01;
                    edge_count_out   = 32'd0;
                end
            end
            2'b01: begin // BAUD_MEASURE
                edge_count_out = edge_count_in + 1;
                if (rxd_rising)
                    state_out = 2'b10;
            end
            2'b10: begin // BAUD_CALC
                if (edge_count_in > 0)
                    detected_br_out = (CLK_FREQ / (edge_count_in * 2)) - 1;
                else
                    detected_br_out = 16'd0;
                state_out = 2'b00;
            end
            default: state_out = 2'b00;
        endcase
    end

endmodule

// ----------- Baudrate Counter Pipeline Stage ----------- //
module UART_AutoBaud_BaudCounter_Pipeline (
    input  wire        clk,
    input  wire        rst_n,
    input  wire [15:0] baud_counter_in,
    input  wire [15:0] baudrate_in,
    output reg  [15:0] baud_counter_out,
    output reg         baud_tick_out
);
    always @(*) begin
        if (baud_counter_in >= baudrate_in) begin
            baud_counter_out = 16'd0;
            baud_tick_out    = 1'b1;
        end else begin
            baud_counter_out = baud_counter_in + 1;
            baud_tick_out    = 1'b0;
        end
    end
endmodule