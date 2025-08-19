module address_shadow_reg #(
    parameter WIDTH = 32,
    parameter ADDR_WIDTH = 4,
    parameter BASE_ADDR = 4'h0
)(
    input wire clk,
    input wire rst_n,
    input wire [WIDTH-1:0] data_in,
    input wire [ADDR_WIDTH-1:0] addr,
    input wire write_en,
    input wire read_en,
    output reg [WIDTH-1:0] data_out,
    output reg [WIDTH-1:0] shadow_data
);
    // Address decoding
    wire addr_match = (addr == BASE_ADDR);
    wire shadow_addr_match = (addr == BASE_ADDR + 1'b1);
    
    // Main register logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            data_out <= 0;
        else if (write_en && addr_match)
            data_out <= data_in;
    end
    
    // Shadow register with address-mapped access
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            shadow_data <= 0;
        else if (write_en && shadow_addr_match)
            shadow_data <= data_in;
        else if (write_en && addr_match)
            shadow_data <= data_out;
    end
endmodule