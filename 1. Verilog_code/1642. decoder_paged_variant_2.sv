//SystemVerilog
module decoder_paged #(PAGE_BITS=2) (
    input [7:0] addr,
    input [PAGE_BITS-1:0] page_reg,
    output reg [3:0] select
);
    wire [7:0] addr_upper = {addr[7:8-PAGE_BITS], {(8-(8-PAGE_BITS+1)){1'b0}}};
    wire [7:0] page_reg_extended = {{(8-PAGE_BITS){1'b0}}, page_reg};
    wire [7:0] diff = addr_upper - page_reg_extended;
    wire [3:0] shift_amount = addr[7-PAGE_BITS:4];
    
    always @* begin
        if (diff == 8'b0) begin
            select = 4'b1 << shift_amount;
        end else begin
            select = 4'b0;
        end
    end
endmodule