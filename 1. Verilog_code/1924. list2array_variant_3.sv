//SystemVerilog
module list2array #(parameter DW=8, MAX_LEN=8) (
    input clk, rst_n,
    input [DW-1:0] node_data,
    input node_valid,
    output [DW*MAX_LEN-1:0] array_out,
    output reg [3:0] length
);
    reg [DW-1:0] mem [0:MAX_LEN-1];
    reg [3:0] idx_reg;
    reg [3:0] length_reg;
    reg [DW-1:0] node_data_reg;
    reg node_valid_reg;
    wire [3:0] idx_next;
    wire [3:0] length_next;
    integer i;

    // Carry Lookahead Adder for 4-bit increment
    cla4 idx_cla_inc (
        .a(idx_reg),
        .b(4'b0001),
        .cin(1'b0),
        .sum(idx_next),
        .cout()
    );

    cla4 length_cla_inc (
        .a(length_reg),
        .b(4'b0001),
        .cin(1'b0),
        .sum(length_next),
        .cout()
    );

    // Forward retiming: input registers after combination logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            node_data_reg <= {DW{1'b0}};
            node_valid_reg <= 1'b0;
        end else begin
            node_data_reg <= node_data;
            node_valid_reg <= node_valid;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            idx_reg <= 4'd0;
            length_reg <= 4'd0;
            for (i = 0; i < MAX_LEN; i = i + 1) begin
                mem[i] <= {DW{1'b0}};
            end
        end else if (node_valid_reg) begin
            mem[idx_reg] <= node_data_reg;
            idx_reg <= (idx_reg == MAX_LEN-1) ? 4'd0 : idx_next;
            length_reg <= (length_reg == MAX_LEN) ? 4'd8 : length_next;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            length <= 4'd0;
        else
            length <= length_reg;
    end

    genvar g;
    generate
        for (g = 0; g < MAX_LEN; g = g + 1) begin: mem_to_array
            assign array_out[g*DW +: DW] = mem[g];
        end
    endgenerate
endmodule

// 4-bit Carry Lookahead Adder
module cla4 (
    input  [3:0] a,
    input  [3:0] b,
    input        cin,
    output [3:0] sum,
    output       cout
);
    wire [3:0] p, g;
    wire [4:0] c;

    assign p = a ^ b;         // Propagate
    assign g = a & b;         // Generate

    assign c[0] = cin;
    assign c[1] = g[0] | (p[0] & c[0]);
    assign c[2] = g[1] | (p[1] & g[0]) | (p[1] & p[0] & c[0]);
    assign c[3] = g[2] | (p[2] & g[1]) | (p[2] & p[1] & g[0]) | (p[2] & p[1] & p[0] & c[0]);
    assign c[4] = g[3] | (p[3] & g[2]) | (p[3] & p[2] & g[1]) | (p[3] & p[2] & p[1] & g[0]) | (p[3] & p[2] & p[1] & p[0] & c[0]);

    assign sum = p ^ c[3:0];
    assign cout = c[4];
endmodule