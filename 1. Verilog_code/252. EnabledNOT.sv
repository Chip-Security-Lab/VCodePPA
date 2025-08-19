module EnabledNOT(
    input en,
    input [3:0] src,
    output reg [3:0] result
);
    always @(*) begin
        result = en ? ~src : 4'bzzzz;
    end
endmodule
