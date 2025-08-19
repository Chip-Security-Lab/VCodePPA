//SystemVerilog
module hamming_parity_precalc (
    input clk, en,
    input [3:0] data,
    output [6:0] code
);
    // Internal signals
    wire [2:0] parity_bits;
    
    // Parity calculation submodule
    parity_calculator parity_calc_inst (
        .clk(clk),
        .en(en),
        .data(data),
        .parity_bits(parity_bits)
    );
    
    // Code word assembly submodule
    code_assembler code_asm_inst (
        .clk(clk),
        .en(en),
        .data(data),
        .parity_bits(parity_bits),
        .code(code)
    );
endmodule

module parity_calculator (
    input clk, en,
    input [3:0] data,
    output reg [2:0] parity_bits // {p4, p2, p1}
);
    always @(posedge clk) begin
        if (en) begin
            // Pre-calculate parity bits using parallel logic
            // p1 (bit 0) - covers positions 1,3,5,7
            parity_bits[0] <= data[0] ^ data[1] ^ data[3];
            // p2 (bit 1) - covers positions 2,3,6,7
            parity_bits[1] <= data[0] ^ data[2] ^ data[3];
            // p4 (bit 2) - covers positions 4,5,6,7
            parity_bits[2] <= data[1] ^ data[2] ^ data[3];
        end
    end
endmodule

module code_assembler (
    input clk, en,
    input [3:0] data,
    input [2:0] parity_bits, // {p4, p2, p1}
    output reg [6:0] code
);
    always @(posedge clk) begin
        if (en) begin
            // Assemble hamming code in the order: {d3, d2, d1, p4, d0, p2, p1}
            code <= {data[3:1], parity_bits[2], data[0], parity_bits[1:0]};
        end
    end
endmodule