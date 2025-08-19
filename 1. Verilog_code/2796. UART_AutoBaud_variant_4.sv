//SystemVerilog
module UART_AutoBaud #(
    parameter MIN_BAUD = 9600,
    parameter CLK_FREQ = 100_000_000
)(
    input  wire        clk,
    input  wire        rst_n,
    input  wire        rxd,
    input  wire        auto_br_en,
    output reg  [15:0] detected_br,
    output reg         baud_tick
);

// ============================================================================
// Pipeline Stage 1: RXD Edge Detection
// ============================================================================
reg rxd_stage1, rxd_stage2;
wire rxd_falling_edge_stage1, rxd_rising_edge_stage1;
reg valid_stage1, valid_stage1_next;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        rxd_stage1 <= 1'b1;
        rxd_stage2 <= 1'b1;
        valid_stage1 <= 1'b0;
    end else begin
        rxd_stage1 <= rxd;
        rxd_stage2 <= rxd_stage1;
        valid_stage1 <= auto_br_en;
    end
end

assign rxd_falling_edge_stage1 =  rxd_stage2 & ~rxd_stage1;
assign rxd_rising_edge_stage1  = ~rxd_stage2 &  rxd_stage1;

// ============================================================================
// Pipeline Stage 2: Edge Event Latching and FSM Input Preparation
// ============================================================================
reg rxd_falling_edge_stage2, rxd_rising_edge_stage2;
reg valid_stage2;
reg auto_br_en_stage2;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        rxd_falling_edge_stage2 <= 1'b0;
        rxd_rising_edge_stage2  <= 1'b0;
        valid_stage2            <= 1'b0;
        auto_br_en_stage2       <= 1'b0;
    end else begin
        rxd_falling_edge_stage2 <= rxd_falling_edge_stage1;
        rxd_rising_edge_stage2  <= rxd_rising_edge_stage1;
        valid_stage2            <= valid_stage1;
        auto_br_en_stage2       <= auto_br_en;
    end
end

// ============================================================================
// Pipeline Stage 3: FSM State & Edge Counter Update
// ============================================================================
localparam BAUD_IDLE    = 2'b00;
localparam BAUD_MEASURE = 2'b01;
localparam BAUD_CALC    = 2'b10;

reg [1:0]  baud_fsm_state_stage3, baud_fsm_state_stage3_next;
reg [31:0] edge_counter_stage3, edge_counter_stage3_next;
reg [31:0] measure_counter_stage3, measure_counter_stage3_next;
reg        valid_stage3;
reg        start_count_stage3, finish_count_stage3;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        baud_fsm_state_stage3   <= BAUD_IDLE;
        edge_counter_stage3     <= 32'd0;
        measure_counter_stage3  <= 32'd0;
        valid_stage3            <= 1'b0;
        start_count_stage3      <= 1'b0;
        finish_count_stage3     <= 1'b0;
    end else begin
        baud_fsm_state_stage3   <= baud_fsm_state_stage3_next;
        edge_counter_stage3     <= edge_counter_stage3_next;
        measure_counter_stage3  <= measure_counter_stage3_next;
        valid_stage3            <= valid_stage2;
        start_count_stage3      <= rxd_falling_edge_stage2 & auto_br_en_stage2;
        finish_count_stage3     <= rxd_rising_edge_stage2;
    end
end

always @(*) begin
    baud_fsm_state_stage3_next   = baud_fsm_state_stage3;
    edge_counter_stage3_next     = edge_counter_stage3;
    measure_counter_stage3_next  = measure_counter_stage3;
    case (baud_fsm_state_stage3)
        BAUD_IDLE: begin
            if (start_count_stage3) begin
                baud_fsm_state_stage3_next  = BAUD_MEASURE;
                edge_counter_stage3_next    = 32'd0;
            end
        end
        BAUD_MEASURE: begin
            edge_counter_stage3_next = edge_counter_stage3 + 1;
            if (finish_count_stage3) begin
                baud_fsm_state_stage3_next  = BAUD_CALC;
                measure_counter_stage3_next = edge_counter_stage3 + 1;
            end
        end
        BAUD_CALC: begin
            baud_fsm_state_stage3_next = BAUD_IDLE;
        end
        default: baud_fsm_state_stage3_next = BAUD_IDLE;
    endcase
end

// ============================================================================
// Pipeline Stage 4: Baud Rate Calculation
// ============================================================================
reg [31:0] measure_counter_stage4;
reg [1:0]  baud_fsm_state_stage4;
reg        valid_stage4;
reg [15:0] detected_br_stage4;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        measure_counter_stage4   <= 32'd0;
        baud_fsm_state_stage4    <= BAUD_IDLE;
        valid_stage4             <= 1'b0;
        detected_br_stage4       <= 16'd0;
    end else begin
        baud_fsm_state_stage4    <= baud_fsm_state_stage3;
        measure_counter_stage4   <= measure_counter_stage3;
        valid_stage4             <= valid_stage3;
        if (baud_fsm_state_stage3 == BAUD_CALC) begin
            if (measure_counter_stage3 > 0)
                detected_br_stage4 <= (CLK_FREQ / (measure_counter_stage3 * 2)) - 1;
            else
                detected_br_stage4 <= 16'd0;
        end
    end
end

// ============================================================================
// Pipeline Stage 5: Baud Rate Output Register
// ============================================================================
reg [15:0] detected_br_stage5;
reg        valid_stage5;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        detected_br_stage5 <= 16'd0;
        valid_stage5       <= 1'b0;
    end else begin
        detected_br_stage5 <= detected_br_stage4;
        valid_stage5       <= valid_stage4;
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        detected_br <= 16'd0;
    else if (baud_fsm_state_stage4 == BAUD_CALC && valid_stage4)
        detected_br <= detected_br_stage4;
end

// ============================================================================
// Pipeline Stage 6: Baud Rate Selection and Tick Generation
// ============================================================================
reg [15:0] manual_br_stage6;
reg [15:0] baudrate_selected_stage6;
reg [15:0] baud_counter_stage6;
reg        baud_tick_stage6;
reg        valid_stage6;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        manual_br_stage6        <= 16'd0;
        baudrate_selected_stage6<= 16'd0;
        baud_counter_stage6     <= 16'd0;
        baud_tick_stage6        <= 1'b0;
        valid_stage6            <= 1'b0;
    end else begin
        manual_br_stage6        <= manual_br_stage6; // For compatibility, not updated here
        baudrate_selected_stage6<= auto_br_en ? detected_br_stage5 : manual_br_stage6;
        valid_stage6            <= valid_stage5;
        if (baud_counter_stage6 >= baudrate_selected_stage6) begin
            baud_counter_stage6 <= 16'd0;
            baud_tick_stage6    <= 1'b1;
        end else begin
            baud_counter_stage6 <= baud_counter_stage6 + 1;
            baud_tick_stage6    <= 1'b0;
        end
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        baud_tick <= 1'b0;
    else
        baud_tick <= baud_tick_stage6;
end

endmodule