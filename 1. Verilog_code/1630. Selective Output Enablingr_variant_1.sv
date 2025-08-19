//SystemVerilog
module selective_decoder #(
    parameter ADDR_WIDTH = 4,
    parameter OUT_WIDTH = 16,
    parameter ENABLE_MASK = 16'hFFFF
)(
    input wire clk,
    input wire rst_n,
    input [ADDR_WIDTH-1:0] addr,
    input enable,
    output reg [OUT_WIDTH-1:0] select
);

    // Pipeline registers
    reg [ADDR_WIDTH-1:0] addr_reg;
    reg enable_reg;
    reg [OUT_WIDTH-1:0] decode_reg;
    
    // Decode stage
    wire [OUT_WIDTH-1:0] decode_out;
    assign decode_out = enable_reg ? (1 << addr_reg) : {OUT_WIDTH{1'b0}};
    
    // Input address register
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            addr_reg <= {ADDR_WIDTH{1'b0}};
        end else begin
            addr_reg <= addr;
        end
    end
    
    // Input enable register
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            enable_reg <= 1'b0;
        end else begin
            enable_reg <= enable;
        end
    end
    
    // Decode result register
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            decode_reg <= {OUT_WIDTH{1'b0}};
        end else begin
            decode_reg <= decode_out;
        end
    end
    
    // Final output with mask
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            select <= {OUT_WIDTH{1'b0}};
        end else begin
            select <= decode_reg & ENABLE_MASK;
        end
    end

endmodule