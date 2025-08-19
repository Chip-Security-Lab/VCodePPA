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

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            rx_data <= 0;
            data_valid <= 0;
        end else if (enable) begin
            case(state)
                IDLE: 
                    if (&hs_clk) begin
                        state <= ACTIVE;
                        data_valid <= 0;
                    end
                ACTIVE:
                    if (hs_clk[0]) begin
                        rx_data <= hs_data[DATA_WIDTH-1:0];
                        data_valid <= 1;
                        state <= SYNC;
                    end
                SYNC: begin
                    data_valid <= 0;
                    if (!(|hs_clk)) state <= IDLE;
                end
            endcase
        end
    end
endmodule
