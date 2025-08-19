//SystemVerilog
module async_sawtooth(
    input clock,
    input arst,
    input [7:0] increment,
    output reg [9:0] sawtooth_out
);
    wire [9:0] sum;
    wire [9:0] extended_increment = {2'b00, increment};
    
    manchester_adder #(.WIDTH(10)) ma (
        .a(sawtooth_out),
        .b(extended_increment),
        .cin(1'b0),
        .sum(sum),
        .cout()
    );
    
    always @(posedge clock or posedge arst) begin
        if (arst)
            sawtooth_out <= 10'h000;
        else
            sawtooth_out <= sum;
    end
endmodule

module manchester_adder #(
    parameter WIDTH = 10
)(
    input [WIDTH-1:0] a,
    input [WIDTH-1:0] b,
    input cin,
    output [WIDTH-1:0] sum,
    output cout
);
    wire [WIDTH-1:0] p, g;
    wire [WIDTH:0] c;
    
    assign c[0] = cin;
    
    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin: manchester_chain
            // Generate and propagate signals
            assign p[i] = a[i] ^ b[i];
            assign g[i] = a[i] & b[i];
            
            // Manchester carry chain
            assign c[i+1] = g[i] | (p[i] & c[i]);
            
            // Sum calculation
            assign sum[i] = p[i] ^ c[i];
        end
    endgenerate
    
    assign cout = c[WIDTH];
endmodule