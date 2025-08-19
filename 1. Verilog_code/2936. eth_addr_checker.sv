module eth_addr_checker (
    input clk,
    input reset_n,
    input [47:0] mac_addr,
    input [47:0] received_addr,
    input addr_valid,
    output reg addr_match,
    output reg broadcast_detected,
    output reg multicast_detected
);
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            addr_match <= 1'b0;
            broadcast_detected <= 1'b0;
            multicast_detected <= 1'b0;
        end else if (addr_valid) begin
            addr_match <= (mac_addr == received_addr);
            broadcast_detected <= &received_addr[47:0];
            multicast_detected <= received_addr[0];
        end else begin
            addr_match <= 1'b0;
            broadcast_detected <= 1'b0;
            multicast_detected <= 1'b0;
        end
    end
endmodule