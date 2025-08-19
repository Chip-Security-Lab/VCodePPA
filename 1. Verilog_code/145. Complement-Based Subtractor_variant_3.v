module complement_converter_pipelined (
    input wire clk,
    input wire rst_n,
    input wire [7:0] in,
    output reg [7:0] out
);
    reg [7:0] in_reg;
    reg [7:0] complement_reg;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            in_reg <= 8'b0;
            complement_reg <= 8'b0;
            out <= 8'b0;
        end else begin
            in_reg <= in;
            complement_reg <= ~in_reg;
            out <= complement_reg + 1;
        end
    end
endmodule

module adder_8bit_pipelined (
    input wire clk,
    input wire rst_n,
    input wire [7:0] a,
    input wire [7:0] b,
    output reg [7:0] sum
);
    reg [7:0] a_reg;
    reg [7:0] b_reg;
    reg [7:0] sum_reg;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            a_reg <= 8'b0;
            b_reg <= 8'b0;
            sum_reg <= 8'b0;
            sum <= 8'b0;
        end else begin
            a_reg <= a;
            b_reg <= b;
            sum_reg <= a_reg + b_reg;
            sum <= sum_reg;
        end
    end
endmodule

module subtractor_complement_pipelined (
    input wire clk,
    input wire rst_n,
    input wire [7:0] a,
    input wire [7:0] b,
    output wire [7:0] res
);
    wire [7:0] b_complement;
    
    complement_converter_pipelined comp_conv (
        .clk(clk),
        .rst_n(rst_n),
        .in(b),
        .out(b_complement)
    );
    
    adder_8bit_pipelined adder (
        .clk(clk),
        .rst_n(rst_n),
        .a(a),
        .b(b_complement),
        .sum(res)
    );
endmodule