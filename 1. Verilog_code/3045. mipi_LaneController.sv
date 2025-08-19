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
    
    always @(posedge clk) begin
        if (rst) begin
            hs_en <= 0;
            burst_counter <= 0;
            state <= 0;
        end else begin
            case(state)
                0: if (|lane_enable) begin
                    hs_en <= lane_enable;
                    state <= 1;
                end
                1: begin
                    lane_data <= {NUM_LANES{tx_data}};
                    burst_counter <= burst_counter + 1;
                    data_consumed <= 1;
                    if (burst_counter == MAX_BURST-1) begin
                        state <= 2;
                        data_consumed <= 0;
                    end
                end
                2: begin
                    hs_en <= 0;
                    if (!(|lane_enable)) state <= 0;
                end
            endcase
        end
    end
endmodule
