//SystemVerilog
module BurstModeRecovery #(parameter SYNC_WORD=64'hA5A5_5A5A_A5A5_5A5A) (
    input clk,
    input [63:0] rx_data,
    output reg [7:0] payload,
    output reg sync_detect
);
    reg [3:0] match_counter;
    wire sync_detect_comb = (rx_data == SYNC_WORD);
    wire [7:0] payload_comb = sync_detect_comb ? rx_data[7:0] : 8'h00;
    
    wire [3:0] match_counter_sub;
    wire [3:0] match_counter_mux;
    wire [3:0] match_counter_ones = 4'b0001;
    
    // Binary two's complement subtraction: match_counter - 1
    assign match_counter_sub = match_counter + (~match_counter_ones + 1);
    assign match_counter_mux = (match_counter > 0) ? match_counter_sub : 4'b0000;
    assign match_counter_comb = sync_detect_comb ? 4'd8 : match_counter_mux;

    always @(posedge clk) begin
        sync_detect <= sync_detect_comb;
        payload <= payload_comb;
        match_counter <= match_counter_comb;
    end
endmodule