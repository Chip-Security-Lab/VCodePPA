//SystemVerilog
module async_dual_port_ram_with_enable #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 8
)(
    input wire [ADDR_WIDTH-1:0] addr_a, addr_b,
    input wire [DATA_WIDTH-1:0] din_a, din_b,
    output reg [DATA_WIDTH-1:0] dout_a, dout_b,
    input wire we_a, we_b,
    input wire en_a, en_b
);

    reg [DATA_WIDTH-1:0] ram [(2**ADDR_WIDTH)-1:0];
    wire write_en_a, write_en_b;
    wire [DATA_WIDTH-1:0] carry_chain;
    wire [DATA_WIDTH-1:0] borrow_out;
    wire [DATA_WIDTH-1:0] sub_result;

    assign write_en_a = en_a & we_a;
    assign write_en_b = en_b & we_b;

    // Carry lookahead subtractor implementation
    genvar i;
    generate
        for (i = 0; i < DATA_WIDTH; i = i + 1) begin : sub_gen
            if (i == 0) begin
                assign carry_chain[0] = 1'b1;  // Initial borrow in
                assign sub_result[0] = din_a[0] ^ din_b[0] ^ carry_chain[0];
                assign borrow_out[0] = (~din_a[0] & din_b[0]) | ((~din_a[0] ^ din_b[0]) & carry_chain[0]);
            end else begin
                assign carry_chain[i] = borrow_out[i-1];
                assign sub_result[i] = din_a[i] ^ din_b[i] ^ carry_chain[i];
                assign borrow_out[i] = (~din_a[i] & din_b[i]) | ((~din_a[i] ^ din_b[i]) & carry_chain[i]);
            end
        end
    endgenerate

    always @* begin
        if (write_en_a) ram[addr_a] = sub_result;
        if (write_en_b) ram[addr_b] = din_b;
        dout_a = ram[addr_a];
        dout_b = ram[addr_b];
    end
endmodule