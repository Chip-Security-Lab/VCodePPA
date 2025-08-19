//SystemVerilog
module SecurityBridge #(
    parameter ADDR_MASK = 32'hFFFF_0000
)(
    input clk, rst_n,
    input [31:0] addr,
    input [1:0] priv_level,
    input valid_in,
    output reg valid_out,
    output reg access_grant
);

    // Stage 1 registers
    reg [31:0] addr_stage1;
    reg [1:0] priv_level_stage1;
    reg valid_stage1;
    
    // Stage 2 registers
    reg [31:0] masked_addr_stage2;
    reg [1:0] priv_level_stage2;
    reg valid_stage2;
    
    // Stage 3 registers
    reg [31:0] masked_addr_stage3;
    reg [1:0] priv_level_stage3;
    reg valid_stage3;
    
    // Stage 4 registers
    reg [31:0] masked_addr_stage4;
    reg [1:0] priv_level_stage4;
    reg valid_stage4;
    reg access_decision_stage4;
    
    // Stage 1: Input registration
    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            addr_stage1 <= 32'h0;
            priv_level_stage1 <= 2'b0;
            valid_stage1 <= 1'b0;
        end else begin
            addr_stage1 <= addr;
            priv_level_stage1 <= priv_level;
            valid_stage1 <= valid_in;
        end
    end
    
    // Stage 2: Address masking
    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            masked_addr_stage2 <= 32'h0;
            priv_level_stage2 <= 2'b0;
            valid_stage2 <= 1'b0;
        end else begin
            masked_addr_stage2 <= addr_stage1 & ADDR_MASK;
            priv_level_stage2 <= priv_level_stage1;
            valid_stage2 <= valid_stage1;
        end
    end
    
    // Stage 3: Address comparison preparation
    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            masked_addr_stage3 <= 32'h0;
            priv_level_stage3 <= 2'b0;
            valid_stage3 <= 1'b0;
        end else begin
            masked_addr_stage3 <= masked_addr_stage2;
            priv_level_stage3 <= priv_level_stage2;
            valid_stage3 <= valid_stage2;
        end
    end
    
    // Stage 4: Access decision
    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            masked_addr_stage4 <= 32'h0;
            priv_level_stage4 <= 2'b0;
            valid_stage4 <= 1'b0;
            access_decision_stage4 <= 1'b0;
        end else begin
            masked_addr_stage4 <= masked_addr_stage3;
            priv_level_stage4 <= priv_level_stage3;
            valid_stage4 <= valid_stage3;
            
            case(masked_addr_stage3)
                32'h4000_0000: access_decision_stage4 <= (priv_level_stage3 >= 2);
                32'h2000_0000: access_decision_stage4 <= (priv_level_stage3 >= 1);
                default: access_decision_stage4 <= 1'b1;
            endcase
        end
    end
    
    // Stage 5: Output registration
    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            access_grant <= 1'b0;
            valid_out <= 1'b0;
        end else begin
            access_grant <= access_decision_stage4;
            valid_out <= valid_stage4;
        end
    end

endmodule