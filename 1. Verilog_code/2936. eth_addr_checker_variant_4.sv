//SystemVerilog
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
    // Register inputs to reduce input-to-register delay
    reg [47:0] mac_addr_reg;
    reg [47:0] received_addr_reg;
    reg addr_valid_reg;
    
    // First stage - register inputs
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            mac_addr_reg <= 48'h0;
            received_addr_reg <= 48'h0;
            addr_valid_reg <= 1'b0;
        end else begin
            mac_addr_reg <= mac_addr;
            received_addr_reg <= received_addr;
            addr_valid_reg <= addr_valid;
        end
    end
    
    // Pre-compute comparison results after registers
    wire addr_equals_mac = (mac_addr_reg == received_addr_reg);
    wire is_broadcast = &received_addr_reg;
    wire is_multicast = received_addr_reg[0];
    
    // Second stage - process the registered values
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            addr_match <= 1'b0;
            broadcast_detected <= 1'b0;
            multicast_detected <= 1'b0;
        end else begin
            addr_match <= addr_valid_reg & addr_equals_mac;
            broadcast_detected <= addr_valid_reg & is_broadcast;
            multicast_detected <= addr_valid_reg & is_multicast;
        end
    end
endmodule