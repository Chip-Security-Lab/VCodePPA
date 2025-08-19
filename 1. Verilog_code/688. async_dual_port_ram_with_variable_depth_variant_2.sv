//SystemVerilog
module async_dual_port_ram_with_variable_depth #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 8,
    parameter RAM_DEPTH = 256
)(
    input wire [ADDR_WIDTH-1:0] addr_a, addr_b,
    input wire [DATA_WIDTH-1:0] din_a, din_b,
    output reg [DATA_WIDTH-1:0] dout_a, dout_b,
    input wire we_a, we_b,
    input wire sub_en,
    input wire [DATA_WIDTH-1:0] sub_a, sub_b,
    output reg [DATA_WIDTH-1:0] sub_result,
    output reg sub_carry
);

    // RAM storage
    reg [DATA_WIDTH-1:0] ram [0:RAM_DEPTH-1];
    
    // Pipeline stage 1: RAM read/write
    reg [DATA_WIDTH-1:0] ram_out_a, ram_out_b;
    
    // Pipeline stage 2: Subtraction
    wire [DATA_WIDTH-1:0] sub_diff;
    wire sub_borrow;
    
    // RAM access pipeline
    always @* begin
        if (we_a) ram[addr_a] = din_a;
        if (we_b) ram[addr_b] = din_b;
        ram_out_a = ram[addr_a];
        ram_out_b = ram[addr_b];
    end
    
    // Output pipeline
    always @* begin
        dout_a = ram_out_a;
        dout_b = ram_out_b;
    end
    
    // Subtraction pipeline
    carry_lookahead_subtractor #(
        .WIDTH(DATA_WIDTH)
    ) cl_sub (
        .a(sub_a),
        .b(sub_b),
        .diff(sub_diff),
        .borrow(sub_borrow)
    );
    
    // Subtraction result pipeline
    always @* begin
        if (sub_en) begin
            sub_result = sub_diff;
            sub_carry = sub_borrow;
        end else begin
            sub_result = {DATA_WIDTH{1'b0}};
            sub_carry = 1'b0;
        end
    end
endmodule

module carry_lookahead_subtractor #(
    parameter WIDTH = 8
)(
    input wire [WIDTH-1:0] a,
    input wire [WIDTH-1:0] b,
    output wire [WIDTH-1:0] diff,
    output wire borrow
);

    // Generate and propagate signals
    wire [WIDTH-1:0] g, p;
    wire [WIDTH:0] carry;
    
    assign carry[0] = 1'b0;
    
    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : sub_bit
            wire b_comp = b[i] ^ 1'b1;
            assign g[i] = ~a[i] & b_comp;
            assign p[i] = a[i] | b_comp;
            assign carry[i+1] = g[i] | (p[i] & carry[i]);
            assign diff[i] = a[i] ^ b_comp ^ carry[i];
        end
    endgenerate
    
    assign borrow = carry[WIDTH];
endmodule