//SystemVerilog
module BurstModeRecovery #(parameter SYNC_WORD=64'hA5A5_5A5A_A5A5_5A5A) (
    input clk,
    input [63:0] rx_data,
    output reg [7:0] payload,
    output reg sync_detect
);
    reg [3:0] match_counter;
    wire [3:0] match_counter_next;
    wire match_detected;
    
    // Precompute sync detection
    assign match_detected = (rx_data == SYNC_WORD);
    
    // Optimized counter logic
    wire counter_decrement = (|match_counter) & ~sync_detect;
    assign match_counter_next = sync_detect ? 4'd8 : 
                              (counter_decrement ? (match_counter - 4'b1) : 4'b0);

    always @(posedge clk) begin
        sync_detect <= match_detected;
        payload <= match_detected ? rx_data[7:0] : 8'h00;
        match_counter <= match_counter_next;
    end
endmodule