//SystemVerilog
module MIPI_LaneController #(
    parameter NUM_LANES = 4,
    parameter MAX_BURST = 16
)(
    input wire clk,
    input wire rst,
    input wire [NUM_LANES-1:0] lane_enable,
    input wire [7:0] tx_data,
    output reg [NUM_LANES-1:0] hs_en,
    output reg [NUM_LANES*8-1:0] lane_data,
    output reg data_consumed
);

    reg [3:0] burst_counter;
    reg [1:0] state;
    reg [1:0] next_state;
    reg [NUM_LANES-1:0] next_hs_en;
    reg [NUM_LANES*8-1:0] next_lane_data;
    reg next_data_consumed;
    reg [3:0] next_burst_counter;

    // State transition logic
    always @(*) begin
        next_state = state;
        case(state)
            0: next_state = (|lane_enable) ? 1 : state;
            1: next_state = (burst_counter == MAX_BURST-1) ? 2 : state;
            2: next_state = (|lane_enable) ? state : 0;
        endcase
    end

    // HS enable control
    always @(*) begin
        next_hs_en = (state == 0 && |lane_enable) ? lane_enable : 
                    (state == 2) ? 0 : hs_en;
    end

    // Data and burst counter control
    always @(*) begin
        next_lane_data = lane_data;
        next_burst_counter = burst_counter;
        next_data_consumed = 0;
        
        if (state == 1) begin
            next_lane_data = {NUM_LANES{tx_data}};
            next_burst_counter = burst_counter + 1;
            next_data_consumed = ~(burst_counter == MAX_BURST-1);
        end
    end

    // Sequential logic
    always @(posedge clk) begin
        if (rst) begin
            state <= 0;
            hs_en <= 0;
            burst_counter <= 0;
            lane_data <= 0;
            data_consumed <= 0;
        end else begin
            state <= next_state;
            hs_en <= next_hs_en;
            burst_counter <= next_burst_counter;
            lane_data <= next_lane_data;
            data_consumed <= next_data_consumed;
        end
    end

endmodule