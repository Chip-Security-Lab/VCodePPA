module Sub5(
    input  [3:0] A,
    input  [3:0] B,
    output [3:0] D,
    output Bout
);

    reg [3:0] B_comp;
    reg [4:0] B_comp_plus_1;
    reg [4:0] sum_result;

    always @(*) begin
        B_comp = ~B;
        B_comp_plus_1 = {1'b1, B_comp} + 5'b00001;
        sum_result = {1'b0, A} + B_comp_plus_1;
    end

    assign D = sum_result[3:0];
    assign Bout = sum_result[4];

endmodule