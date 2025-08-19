//SystemVerilog
module base_addr_decoder #(
    parameter BASE_ADDR = 4'h0
)(
    input clk,
    input rst_n,
    input [3:0] addr,
    output reg cs
);

    // Pipeline stage 1: Address comparison
    reg [3:0] addr_stage1;
    reg valid_stage1;
    
    // Pipeline stage 2: Chip select generation
    reg valid_stage2;
    reg cs_stage2;
    
    // Stage 1: Address capture and validation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            addr_stage1 <= 4'h0;
            valid_stage1 <= 1'b0;
        end else begin
            addr_stage1 <= addr;
            valid_stage1 <= 1'b1;
        end
    end
    
    // Stage 2: Chip select generation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            valid_stage2 <= 1'b0;
            cs_stage2 <= 1'b0;
        end else begin
            valid_stage2 <= valid_stage1;
            cs_stage2 <= (addr_stage1[3:2] == BASE_ADDR[3:2]) & valid_stage1;
        end
    end
    
    // Output assignment
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cs <= 1'b0;
        end else begin
            cs <= cs_stage2 & valid_stage2;
        end
    end

endmodule