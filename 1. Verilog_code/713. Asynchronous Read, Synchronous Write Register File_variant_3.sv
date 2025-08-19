//SystemVerilog
module async_read_regfile #(
    parameter DW = 64,             // Data width
    parameter AW = 6,              // Address width
    parameter SIZE = (1 << AW)     // Register file size
)(
    input  wire           clock,
    input  wire           wr_en,
    input  wire [AW-1:0]  wr_addr,
    input  wire [DW-1:0]  wr_data,
    input  wire [AW-1:0]  rd_addr,
    output wire [DW-1:0]  rd_data
);

    // Storage element
    reg [DW-1:0] registers [0:SIZE-1];
    
    // Asynchronous read (combinational output)
    assign rd_data = registers[rd_addr];
    
    // Parallel Prefix Subtractor signals
    wire [DW-1:0] a, b, result;
    wire [DW:0] p, g, c;
    wire [DW-1:0] p_xor_c;

    // Operand assignment
    assign a = registers[rd_addr];
    assign b = wr_data;

    // Generate Propagate and Generate signals with balanced logic
    genvar i;
    generate
        for (i = 0; i < DW; i = i + 1) begin : pg_gen
            wire p_temp, g_temp;
            assign p_temp = a[i] ^ b[i];
            assign g_temp = ~a[i] & b[i];
            assign p[i] = p_temp;
            assign g[i] = g_temp;
        end
    endgenerate

    // Carry generation using parallel prefix with balanced tree structure
    assign c[0] = 1'b0;
    generate
        for (i = 0; i < DW; i = i + 1) begin : carry_gen
            wire carry_temp;
            assign carry_temp = g[i] | (p[i] & c[i]);
            assign c[i + 1] = carry_temp;
        end
    endgenerate

    // Result calculation with balanced XOR
    generate
        for (i = 0; i < DW; i = i + 1) begin : result_gen
            assign p_xor_c[i] = p[i] ^ c[i];
        end
    endgenerate
    assign result = p_xor_c;

    // Synchronous write with result
    always @(posedge clock) begin
        if (wr_en) begin
            registers[wr_addr] <= result;
        end
    end
endmodule