//SystemVerilog
// Clock gating module
module clock_gate (
    input main_clk,
    input enable,
    output gated_clk
);
    assign gated_clk = main_clk & enable;
endmodule

// Parallel prefix subtractor module
module parallel_prefix_subtractor #(
    parameter WIDTH = 8
)(
    input [WIDTH-1:0] a,
    input [WIDTH-1:0] b,
    output [WIDTH-1:0] diff,
    output borrow
);
    // Generate and propagate signals
    wire [WIDTH-1:0] g, p;
    wire [WIDTH:0] c;
    
    // Initial generate and propagate
    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : gen_initial
            assign g[i] = a[i] & ~b[i];
            assign p[i] = a[i] ^ ~b[i];
        end
    endgenerate
    
    // Parallel prefix computation
    wire [WIDTH-1:0][WIDTH-1:0] g_prefix, p_prefix;
    
    // First level
    assign g_prefix[0][0] = g[0];
    assign p_prefix[0][0] = p[0];
    
    genvar j, k;
    generate
        for (j = 1; j < WIDTH; j = j + 1) begin : gen_first_level
            assign g_prefix[0][j] = g[j];
            assign p_prefix[0][j] = p[j];
        end
        
        // Remaining levels
        for (k = 1; k < $clog2(WIDTH); k = k + 1) begin : gen_levels
            for (j = 0; j < WIDTH; j = j + 1) begin : gen_nodes
                if (j < (1 << k)) begin
                    assign g_prefix[k][j] = g_prefix[k-1][j];
                    assign p_prefix[k][j] = p_prefix[k-1][j];
                end else begin
                    assign g_prefix[k][j] = g_prefix[k-1][j] | (p_prefix[k-1][j] & g_prefix[k-1][j-(1<<(k-1))]);
                    assign p_prefix[k][j] = p_prefix[k-1][j] & p_prefix[k-1][j-(1<<(k-1))];
                end
            end
        end
    endgenerate
    
    // Final carry computation
    assign c[0] = 1'b1; // Initial borrow-in
    genvar m;
    generate
        for (m = 1; m <= WIDTH; m = m + 1) begin : gen_carry
            assign c[m] = g_prefix[$clog2(WIDTH)-1][m-1] | (p_prefix[$clog2(WIDTH)-1][m-1] & c[0]);
        end
    endgenerate
    
    // Difference computation
    genvar n;
    generate
        for (n = 0; n < WIDTH; n = n + 1) begin : gen_diff
            assign diff[n] = p[n] ^ c[n];
        end
    endgenerate
    
    assign borrow = c[WIDTH];
endmodule

// Memory core module with parallel prefix subtractor
module memory_core #(
    parameter DW = 4,
    parameter AW = 3
)(
    input gated_clk,
    input we,
    input [AW-1:0] addr,
    input [DW-1:0] din,
    output reg [DW-1:0] dout
);
    reg [DW-1:0] mem [0:(1<<AW)-1];
    wire [DW-1:0] sub_result;
    wire sub_borrow;
    
    // Parallel prefix subtractor instance
    parallel_prefix_subtractor #(
        .WIDTH(DW)
    ) u_subtractor (
        .a(din),
        .b(mem[addr]),
        .diff(sub_result),
        .borrow(sub_borrow)
    );

    always @(posedge gated_clk) begin
        if (we) begin
            mem[addr] <= din;
            dout <= din;
        end else begin
            dout <= sub_result; // Using subtractor result instead of direct memory access
        end
    end
endmodule

// Top level module
module sram_clock_gated #(
    parameter DW = 4,
    parameter AW = 3
)(
    input main_clk,
    input enable,
    input we,
    input [AW-1:0] addr,
    input [DW-1:0] din,
    output [DW-1:0] dout
);
    wire gated_clk;

    clock_gate u_clock_gate (
        .main_clk(main_clk),
        .enable(enable),
        .gated_clk(gated_clk)
    );

    memory_core #(
        .DW(DW),
        .AW(AW)
    ) u_memory_core (
        .gated_clk(gated_clk),
        .we(we),
        .addr(addr),
        .din(din),
        .dout(dout)
    );
endmodule