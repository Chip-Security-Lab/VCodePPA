//SystemVerilog
module full_adder_sync #(
    parameter WIDTH = 4,
    parameter DEPTH = 2
)(
    input wire clk,
    input wire rst_n,
    input wire en,
    input wire [WIDTH-1:0] a,
    input wire [WIDTH-1:0] b,
    input wire cin,
    output reg [WIDTH-1:0] sum,
    output reg cout
);

    wire [WIDTH-1:0] g, p;
    wire [WIDTH:0] c;
    reg [WIDTH-1:0] a_reg, b_reg;
    reg cin_reg;
    reg [WIDTH-1:0] sum_reg;
    reg cout_reg;

    // Generate and Propagate
    assign g = a_reg & b_reg;
    assign p = a_reg ^ b_reg;

    // Carry Lookahead
    assign c[0] = cin_reg;
    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin
            assign c[i+1] = g[i] | (p[i] & c[i]);
        end
    endgenerate

    // Sum calculation
    wire [WIDTH-1:0] sum_next = p ^ c[WIDTH-1:0];
    wire cout_next = c[WIDTH];

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            a_reg <= 0;
            b_reg <= 0;
            cin_reg <= 0;
            sum_reg <= 0;
            cout_reg <= 0;
        end else if (en) begin
            a_reg <= a;
            b_reg <= b;
            cin_reg <= cin;
            sum_reg <= sum_next;
            cout_reg <= cout_next;
        end
    end

    assign sum = sum_reg;
    assign cout = cout_reg;

endmodule