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
    reg [WIDTH:0] temp;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sum <= 0;
            cout <= 0;
        end else if (en) begin
            temp <= a + b + cin;
            {cout, sum} <= temp;
        end
    end
endmodule