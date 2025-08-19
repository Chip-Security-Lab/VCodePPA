//SystemVerilog
module sync_rst_decoder(
    input clk,
    input rst,
    input [3:0] addr,
    output reg [15:0] select
);
    // Pipeline stage 1 registers
    reg [3:0] addr_stage1;
    reg valid_stage1;
    
    // Pipeline stage 2 registers
    reg [15:0] decode_stage2;
    reg valid_stage2;
    
    // Stage 1: Register inputs and validate
    always @(posedge clk) begin
        if (rst) begin
            addr_stage1 <= 4'b0;
            valid_stage1 <= 1'b0;
        end
        else begin
            addr_stage1 <= addr;
            valid_stage1 <= 1'b1;
        end
    end
    
    // Stage 2: Perform decode operation with optimized implementation
    always @(posedge clk) begin
        if (rst) begin
            decode_stage2 <= 16'b0;
            valid_stage2 <= 1'b0;
        end
        else if (valid_stage1) begin
            // Use one-hot encoder with pre-computed values for faster decoding
            case (addr_stage1)
                4'h0: decode_stage2 <= 16'h0001;
                4'h1: decode_stage2 <= 16'h0002;
                4'h2: decode_stage2 <= 16'h0004;
                4'h3: decode_stage2 <= 16'h0008;
                4'h4: decode_stage2 <= 16'h0010;
                4'h5: decode_stage2 <= 16'h0020;
                4'h6: decode_stage2 <= 16'h0040;
                4'h7: decode_stage2 <= 16'h0080;
                4'h8: decode_stage2 <= 16'h0100;
                4'h9: decode_stage2 <= 16'h0200;
                4'hA: decode_stage2 <= 16'h0400;
                4'hB: decode_stage2 <= 16'h0800;
                4'hC: decode_stage2 <= 16'h1000;
                4'hD: decode_stage2 <= 16'h2000;
                4'hE: decode_stage2 <= 16'h4000;
                4'hF: decode_stage2 <= 16'h8000;
                default: decode_stage2 <= 16'h0000;
            endcase
            valid_stage2 <= valid_stage1;
        end
        else begin
            decode_stage2 <= 16'b0;
            valid_stage2 <= 1'b0;
        end
    end
    
    // Final output assignment with conditional update
    always @(posedge clk) begin
        if (rst) begin
            select <= 16'b0;
        end
        else if (valid_stage2) begin
            select <= decode_stage2;
        end
    end
endmodule