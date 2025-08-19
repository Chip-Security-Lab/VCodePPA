//SystemVerilog
module MIPI_SyncReceiver #(
    parameter DATA_WIDTH = 8,
    parameter LANE_COUNT = 2
)(
    input wire clk,
    input wire rst_n,
    input wire enable,
    input wire [LANE_COUNT-1:0] hs_clk,
    input wire [LANE_COUNT*DATA_WIDTH-1:0] hs_data,
    output reg [DATA_WIDTH-1:0] rx_data,
    output reg data_valid
);
    reg [1:0] state;
    localparam IDLE = 2'b00, ACTIVE = 2'b01, SYNC = 2'b10;
    
    // Optimized lane status detection using two's complement approach
    wire [LANE_COUNT-1:0] lane_status;
    wire all_lanes_high;
    wire any_lane_low;
    wire lane0_active;
    
    // Two's complement approach for lane status detection
    assign lane_status = hs_clk;
    assign all_lanes_high = &lane_status;
    assign any_lane_low = ~(|lane_status);
    assign lane0_active = lane_status[0];
    
    // Optimized state machine with improved timing
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            rx_data <= {DATA_WIDTH{1'b0}};
            data_valid <= 1'b0;
        end else if (enable) begin
            case (state)
                IDLE: begin
                    if (all_lanes_high) begin
                        state <= ACTIVE;
                        data_valid <= 1'b0;
                    end
                end
                
                ACTIVE: begin
                    if (lane0_active) begin
                        rx_data <= hs_data[DATA_WIDTH-1:0];
                        data_valid <= 1'b1;
                        state <= SYNC;
                    end
                end
                
                SYNC: begin
                    data_valid <= 1'b0;
                    if (any_lane_low) state <= IDLE;
                end
                
                default: state <= IDLE;
            endcase
        end
    end
endmodule