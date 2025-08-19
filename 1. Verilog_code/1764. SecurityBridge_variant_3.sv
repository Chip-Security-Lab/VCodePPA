//SystemVerilog
module SecurityBridge #(
    parameter ADDR_MASK = 32'hFFFF_0000
)(
    input clk, rst_n,
    input [31:0] addr,
    input [1:0] priv_level,
    output reg access_grant
);

// Always block for address matching and access grant logic
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        access_grant <= 1; // Default access grant on reset
    end else begin
        case(addr & ADDR_MASK)
            32'h4000_0000: access_grant <= (priv_level >= 2); // High privilege access
            32'h2000_0000: access_grant <= (priv_level >= 1); // Medium privilege access
            default: access_grant <= 1; // Default access grant
        endcase
    end
end

endmodule