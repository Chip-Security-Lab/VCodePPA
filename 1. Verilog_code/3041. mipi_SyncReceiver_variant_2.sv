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
    localparam IDLE = 0, ACTIVE = 1, SYNC = 2;
    
    wire all_clks_high = &hs_clk;
    wire any_clk_high = |hs_clk;
    wire clk0_rising = hs_clk[0] & ~state[1];
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            rx_data <= 0;
            data_valid <= 0;
        end else if (enable) begin
            if (state == IDLE && all_clks_high) begin
                state <= ACTIVE;
                data_valid <= 0;
            end else if (state == ACTIVE && clk0_rising) begin
                rx_data <= hs_data[DATA_WIDTH-1:0];
                data_valid <= 1;
                state <= SYNC;
            end else if (state == SYNC) begin
                data_valid <= 0;
                if (!any_clk_high) state <= IDLE;
            end
        end
    end
endmodule