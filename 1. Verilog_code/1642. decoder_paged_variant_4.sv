//SystemVerilog
module decoder_paged #(PAGE_BITS=2) (
    input wire clk,                    // Added clock for pipelining
    input wire rst_n,                  // Added reset for initialization
    input wire [7:0] addr,
    input wire [PAGE_BITS-1:0] page_reg,
    output reg [3:0] select
);

// Pipeline stage 1: Address decoding
reg [3:0] decoded_addr_reg;
wire [3:0] decoded_addr_next;
wire [7-PAGE_BITS:4] addr_lower;
wire [7:8-PAGE_BITS] addr_upper;

assign addr_upper = addr[7:8-PAGE_BITS];
assign addr_lower = addr[7-PAGE_BITS:4];
assign decoded_addr_next = 1 << addr_lower;

// Pipeline stage 2: Page matching
reg page_match_reg;
wire page_match_next;

assign page_match_next = (addr_upper == page_reg);

// Pipeline stage 3: Final selection
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        decoded_addr_reg <= 4'b0;
        page_match_reg <= 1'b0;
        select <= 4'b0;
    end else begin
        decoded_addr_reg <= decoded_addr_next;
        page_match_reg <= page_match_next;
        select <= page_match_reg ? decoded_addr_reg : 4'b0;
    end
end

endmodule