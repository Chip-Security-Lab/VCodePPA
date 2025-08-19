//SystemVerilog
module crc_gated_clock (
    input clk, en,
    input [7:0] data,
    output reg [15:0] crc
);
    reg en_latch;
    wire gated_clk;
    reg [15:0] shifted_crc_reg;
    reg [15:0] poly_mask_reg;
    reg [15:0] data_extended_reg;
    
    always @(negedge clk) begin
        en_latch <= en;
    end
    
    assign gated_clk = clk & en_latch;
    
    always @(posedge gated_clk) begin
        shifted_crc_reg <= {crc[14:0], 1'b0};
        poly_mask_reg <= {16{crc[15]}} & 16'h8005;
        data_extended_reg <= {8'h00, data};
    end
    
    always @(posedge gated_clk) begin
        crc <= shifted_crc_reg ^ poly_mask_reg ^ data_extended_reg;
    end
endmodule