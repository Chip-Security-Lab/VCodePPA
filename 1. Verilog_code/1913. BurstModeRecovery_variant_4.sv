//SystemVerilog
module SyncDetector #(parameter SYNC_WORD=64'hA5A5_5A5A_A5A5_5A5A) (
    input [63:0] rx_data,
    output sync_match
);
    assign sync_match = (rx_data == SYNC_WORD);
endmodule

module PayloadExtractor (
    input sync_match,
    input [63:0] rx_data,
    output reg [7:0] payload
);
    always @* begin
        if (sync_match) begin
            payload = rx_data[7:0];
        end
        else begin
            payload = 8'h00;
        end
    end
endmodule

module MatchCounter (
    input clk,
    input sync_match,
    output reg [3:0] match_counter
);
    always @(posedge clk) begin
        if (sync_match) begin
            match_counter <= 4'd8;
        end
        else begin
            if (match_counter > 0) begin
                match_counter <= match_counter - 1;
            end
            else begin
                match_counter <= 0;
            end
        end
    end
endmodule

module BurstModeRecovery #(parameter SYNC_WORD=64'hA5A5_5A5A_A5A5_5A5A) (
    input clk,
    input [63:0] rx_data,
    output [7:0] payload,
    output sync_detect
);
    wire sync_match;
    
    SyncDetector #(.SYNC_WORD(SYNC_WORD)) sync_detector_inst (
        .rx_data(rx_data),
        .sync_match(sync_match)
    );
    
    PayloadExtractor payload_extractor_inst (
        .sync_match(sync_match),
        .rx_data(rx_data),
        .payload(payload)
    );
    
    MatchCounter match_counter_inst (
        .clk(clk),
        .sync_match(sync_match),
        .match_counter()
    );
    
    assign sync_detect = sync_match;
endmodule