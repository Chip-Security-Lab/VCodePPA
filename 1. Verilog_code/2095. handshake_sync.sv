module handshake_sync #(parameter DW=32) (
    input src_clk, dst_clk, rst,
    input [DW-1:0] data_in,
    output reg [DW-1:0] data_out,
    output reg ack
);
    reg req_sync1, req_sync2;
    reg ack_sync1, ack_sync2;
    reg req_flag, ack_flag;
    
    always @(posedge src_clk) begin
        ack_sync2 <= ack_sync1;
        ack_flag <= ack_sync2;
        if(!req_flag && !ack_flag) begin
            data_out <= data_in;
            req_flag <= 1;
        end
    end
    
    always @(posedge dst_clk) begin
        req_sync2 <= req_sync1;
        if(req_sync2) begin
            ack_flag <= 1;
            req_sync2 <= 0;
        end
        ack <= ack_flag;
    end
endmodule