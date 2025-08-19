//SystemVerilog
//IEEE 1364-2005 Verilog
module param_decoder #(
    parameter ADDR_WIDTH = 4,
    parameter OUT_WIDTH = 16
)(
    input wire clk,
    input wire rst_n,
    input wire [ADDR_WIDTH-1:0] address,
    input wire enable,
    output reg [OUT_WIDTH-1:0] select
);
    // Pipeline registers
    reg [ADDR_WIDTH-1:0] address_r;
    reg enable_r;
    
    // Optimized intermediate results
    reg [OUT_WIDTH-1:0] decode_stage;
    
    // First pipeline stage - address and enable registration
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            address_r <= {ADDR_WIDTH{1'b0}};
            enable_r <= 1'b0;
        end else begin
            address_r <= address;
            enable_r <= enable;
        end
    end
    
    // Second pipeline stage - optimized decoder implementation
    // Uses one-hot encoding with simplified shift operation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            decode_stage <= {OUT_WIDTH{1'b0}};
        end else begin
            // Use conditional assignment to avoid unnecessary shifts when address is out of range
            decode_stage <= (address_r < OUT_WIDTH) ? ({{(OUT_WIDTH-1){1'b0}}, 1'b1} << address_r) : {OUT_WIDTH{1'b0}};
        end
    end
    
    // Final pipeline stage - output selection with enable gating
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            select <= {OUT_WIDTH{1'b0}};
        end else begin
            // Use bit-wise AND instead of conditional operator for better gate-level implementation
            select <= decode_stage & {OUT_WIDTH{enable_r}};
        end
    end
    
endmodule