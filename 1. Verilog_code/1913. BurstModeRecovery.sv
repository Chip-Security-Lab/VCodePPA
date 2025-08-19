module BurstModeRecovery #(parameter SYNC_WORD=64'hA5A5_5A5A_A5A5_5A5A) (
    input clk,
    input [63:0] rx_data,
    output reg [7:0] payload,
    output reg sync_detect
);
    reg [3:0] match_counter;
    always @(posedge clk) begin
        sync_detect <= (rx_data == SYNC_WORD);
        payload <= sync_detect ? rx_data[7:0] : 8'h00;
        match_counter <= sync_detect ? 4'd8 : (match_counter > 0 ? match_counter-1 : 0);
    end
endmodule
