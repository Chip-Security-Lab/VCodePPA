//SystemVerilog
module SecurityBridge #(
    parameter ADDR_MASK = 32'hFFFF_0000
)(
    input clk,
    input rst_n,
    input [31:0] addr,
    input [1:0] priv_level,
    output reg access_grant
);

    // Pipeline stage 1: Address decoding
    reg [31:0] masked_addr;
    reg [1:0] priv_level_reg;
    
    // Pipeline stage 2: Access control
    reg access_decision;
    
    // Stage 1: Address masking and privilege level registration
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            masked_addr <= 32'h0;
            priv_level_reg <= 2'b0;
        end else begin
            masked_addr <= addr & ADDR_MASK;
            priv_level_reg <= priv_level;
        end
    end
    
    // Stage 2: Access control logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            access_decision <= 1'b0;
        end else begin
            case(masked_addr)
                32'h4000_0000: access_decision <= (priv_level_reg >= 2);
                32'h2000_0000: access_decision <= (priv_level_reg >= 1);
                default: access_decision <= 1'b1;
            endcase
        end
    end
    
    // Output registration
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            access_grant <= 1'b0;
        end else begin
            access_grant <= access_decision;
        end
    end

endmodule