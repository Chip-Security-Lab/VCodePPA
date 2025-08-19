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
    
    // Parallel prefix subtractor signals
    wire [1:0] hs_clk_diff;
    wire [1:0] hs_clk_borrow;
    wire [1:0] hs_clk_propagate;
    wire [1:0] hs_clk_generate;
    
    // Parallel prefix subtractor implementation
    assign hs_clk_generate[0] = ~hs_clk[0];
    assign hs_clk_propagate[0] = hs_clk[0];
    assign hs_clk_borrow[0] = hs_clk_generate[0];
    
    assign hs_clk_generate[1] = ~hs_clk[1];
    assign hs_clk_propagate[1] = hs_clk[1];
    assign hs_clk_borrow[1] = hs_clk_generate[1] | (hs_clk_propagate[1] & hs_clk_borrow[0]);
    
    assign hs_clk_diff[0] = hs_clk[0] ^ hs_clk_borrow[0];
    assign hs_clk_diff[1] = hs_clk[1] ^ hs_clk_borrow[1];
    
    // State transition logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
        end else if (enable) begin
            case(state)
                IDLE: 
                    if (hs_clk_diff == 2'b11) begin
                        state <= ACTIVE;
                    end
                ACTIVE:
                    if (hs_clk_diff[0]) begin
                        state <= SYNC;
                    end
                SYNC: begin
                    if (hs_clk_diff == 2'b00) state <= IDLE;
                end
            endcase
        end
    end
    
    // Data output logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rx_data <= 0;
        end else if (enable && state == ACTIVE && hs_clk_diff[0]) begin
            rx_data <= hs_data[DATA_WIDTH-1:0];
        end
    end
    
    // Data valid signal logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_valid <= 0;
        end else if (enable) begin
            case(state)
                IDLE: 
                    if (hs_clk_diff == 2'b11) begin
                        data_valid <= 0;
                    end
                ACTIVE:
                    if (hs_clk_diff[0]) begin
                        data_valid <= 1;
                    end
                SYNC: begin
                    data_valid <= 0;
                end
            endcase
        end
    end
endmodule