//SystemVerilog
module sync_decoder_with_reset #(
    parameter ADDR_BITS = 2,
    parameter OUT_BITS = 4
)(
    input wire clk,
    input wire rst,
    input wire [ADDR_BITS-1:0] addr,
    output reg [OUT_BITS-1:0] decode
);

    reg [ADDR_BITS-1:0] addr_reg;
    reg [ADDR_BITS-1:0] addr_reg_pipe;
    reg [OUT_BITS-1:0] decode_next;
    reg [OUT_BITS-1:0] decode_pipe;
    
    always @(posedge clk) begin
        addr_reg <= rst ? 0 : addr;
        addr_reg_pipe <= rst ? 0 : addr_reg;
        decode <= rst ? 0 : decode_pipe;
        decode_pipe <= rst ? 0 : decode_next;
    end
    
    always @(*) begin
        decode_next = (addr_reg_pipe < OUT_BITS) ? (1'b1 << addr_reg_pipe) : 0;
    end

endmodule