module SecurityBridge #(
    parameter ADDR_MASK = 32'hFFFF_0000
)(
    input clk, rst_n,
    input [31:0] addr,
    input [1:0] priv_level,
    output reg access_grant
);
    always @(posedge clk) begin
        case(addr & ADDR_MASK)
            32'h4000_0000: access_grant <= (priv_level >= 2);
            32'h2000_0000: access_grant <= (priv_level >= 1);
            default: access_grant <= 1;
        endcase
    end
endmodule