//SystemVerilog
// Combinational logic module for parity generation
module parity_generator #(
    parameter WIDTH = 4
)(
    input [WIDTH-1:0] data,
    output parity
);
    wire [WIDTH-1:0] diff;
    wire borrow;
    
    carry_lookahead_subtractor #(
        .WIDTH(WIDTH)
    ) subtractor_inst (
        .a(data),
        .b({WIDTH{1'b0}}),
        .diff(diff),
        .borrow(borrow)
    );
    
    assign parity = ^diff;
endmodule

// Memory array module with separated combinational and sequential logic
module mem_array #(
    parameter DATA_BITS = 8
)(
    input clk,
    input we,
    input [3:0] addr,
    input [DATA_BITS:0] din,
    output [DATA_BITS:0] dout
);
    reg [DATA_BITS:0] mem [0:15];
    reg [DATA_BITS:0] mem_out;
    
    // Sequential logic
    always @(posedge clk) begin
        if (we) begin
            mem[addr] <= din;
        end
        mem_out <= mem[addr];
    end
    
    // Combinational logic
    assign dout = mem_out;
endmodule

// Top level module with separated combinational and sequential logic
module sram_parity #(
    parameter DATA_BITS = 8
)(
    input clk,
    input we,
    input [3:0] addr,
    input [DATA_BITS-1:0] din,
    output [DATA_BITS:0] dout
);
    wire parity_bit;
    wire [DATA_BITS:0] mem_in;
    
    // Combinational logic
    parity_generator #(
        .WIDTH(4)
    ) parity_gen_inst (
        .data(din[3:0]),
        .parity(parity_bit)
    );
    
    assign mem_in = {parity_bit, din};
    
    // Sequential logic
    mem_array #(
        .DATA_BITS(DATA_BITS)
    ) mem_array_inst (
        .clk(clk),
        .we(we),
        .addr(addr),
        .din(mem_in),
        .dout(dout)
    );
endmodule

// Carry-lookahead subtractor module with separated combinational logic
module carry_lookahead_subtractor #(
    parameter WIDTH = 4
)(
    input [WIDTH-1:0] a,
    input [WIDTH-1:0] b,
    output [WIDTH-1:0] diff,
    output borrow
);
    wire [WIDTH:0] carry;
    wire [WIDTH-1:0] p, g;
    
    // Generate and propagate signals
    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : gen_prop
            assign p[i] = a[i] ^ b[i];
            assign g[i] = ~a[i] & b[i];
        end
    endgenerate
    
    // Carry lookahead logic
    assign carry[0] = 1'b1;
    
    genvar j;
    generate
        for (j = 0; j < WIDTH; j = j + 1) begin : gen_carry
            assign carry[j+1] = g[j] | (p[j] & carry[j]);
        end
    endgenerate
    
    // Difference calculation
    genvar k;
    generate
        for (k = 0; k < WIDTH; k = k + 1) begin : gen_diff
            assign diff[k] = p[k] ^ carry[k];
        end
    endgenerate
    
    assign borrow = carry[WIDTH];
endmodule