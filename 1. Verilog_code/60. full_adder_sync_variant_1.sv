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

    wire [WIDTH:0] temp;

    // 优化后的加法器核心
    adder_core #(
        .WIDTH(WIDTH)
    ) u_adder_core (
        .a(a),
        .b(b),
        .cin(cin),
        .temp(temp)
    );

    // 优化后的寄存器控制
    reg_control #(
        .WIDTH(WIDTH)
    ) u_reg_control (
        .clk(clk),
        .rst_n(rst_n),
        .en(en),
        .temp(temp),
        .sum(sum),
        .cout(cout)
    );

endmodule

module adder_core #(
    parameter WIDTH = 4
)(
    input wire [WIDTH-1:0] a,
    input wire [WIDTH-1:0] b,
    input wire cin,
    output reg [WIDTH:0] temp
);
    wire [WIDTH:0] carry;
    wire [WIDTH-1:0] sum_bits;
    
    assign carry[0] = cin;
    
    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : adder_chain
            assign sum_bits[i] = a[i] ^ b[i] ^ carry[i];
            assign carry[i+1] = (a[i] & b[i]) | (a[i] & carry[i]) | (b[i] & carry[i]);
        end
    endgenerate
    
    always @(*) begin
        temp = {carry[WIDTH], sum_bits};
    end
endmodule

module reg_control #(
    parameter WIDTH = 4
)(
    input wire clk,
    input wire rst_n,
    input wire en,
    input wire [WIDTH:0] temp,
    output reg [WIDTH-1:0] sum,
    output reg cout
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sum <= {WIDTH{1'b0}};
            cout <= 1'b0;
        end else if (en) begin
            {cout, sum} <= temp;
        end
    end
endmodule