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
    reg [$clog2(MAX_BURST)-1:0] burst_counter;
    reg [1:0] state;
    wire any_lane_enabled;
    wire burst_complete;
    wire [$clog2(MAX_BURST)-1:0] next_burst_counter;
    wire [$clog2(MAX_BURST)-1:0] max_burst_minus_1;
    
    // Optimized lane enable detection using priority encoder
    assign any_lane_enabled = |lane_enable;
    
    // Optimized burst completion check using complement addition
    assign max_burst_minus_1 = MAX_BURST - 1'b1;
    assign next_burst_counter = burst_counter + 1'b1;
    assign burst_complete = (next_burst_counter == max_burst_minus_1);
    
    // Optimized state machine with reduced logic
    always @(posedge clk) begin
        if (rst) begin
            hs_en <= {NUM_LANES{1'b0}};
            burst_counter <= '0;
            state <= 2'b00;
            data_consumed <= 1'b0;
        end else begin
            case(state)
                2'b00: begin
                    if (any_lane_enabled) begin
                        hs_en <= lane_enable;
                        state <= 2'b01;
                    end
                end
                
                2'b01: begin
                    // Optimized data assignment with replication
                    lane_data <= {NUM_LANES{tx_data}};
                    burst_counter <= next_burst_counter;
                    data_consumed <= ~burst_complete;
                    
                    if (burst_complete) begin
                        state <= 2'b10;
                    end
                end
                
                2'b10: begin
                    hs_en <= {NUM_LANES{1'b0}};
                    if (~any_lane_enabled) begin
                        state <= 2'b00;
                    end
                end
                
                default: state <= 2'b00;
            endcase
        end
    end
endmodule