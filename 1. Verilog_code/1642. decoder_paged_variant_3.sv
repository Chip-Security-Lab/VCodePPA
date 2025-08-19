//SystemVerilog
// Top-level module
module decoder_paged #(parameter PAGE_BITS=2) (
    input [7:0] addr,
    input [PAGE_BITS-1:0] page_reg,
    output [3:0] select
);
    // Instantiate the address decoder submodule
    addr_decoder #(.PAGE_BITS(PAGE_BITS)) addr_decoder_inst (
        .addr(addr),
        .page_reg(page_reg),
        .select(select)
    );
endmodule

// Address decoder submodule with optimized subtraction
module addr_decoder #(parameter PAGE_BITS=2) (
    input [7:0] addr,
    input [PAGE_BITS-1:0] page_reg,
    output reg [3:0] select
);
    // Address comparison logic
    wire page_match;
    wire [3:0] decoded_addr;
    wire [PAGE_BITS-1:0] page_diff;
    wire [PAGE_BITS-1:0] page_comp;
    
    // Two's complement subtraction for page matching
    assign page_comp = ~page_reg + 1'b1;
    assign page_diff = addr[7:8-PAGE_BITS] + page_comp;
    assign page_match = ~|page_diff;
    
    // Address decoding logic
    assign decoded_addr = 1 << addr[7-PAGE_BITS:4];
    
    // Output selection logic
    always @* begin
        select = page_match ? decoded_addr : 4'b0;
    end
endmodule