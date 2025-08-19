module PreloadSub(input clk, ld, [7:0] d, output [7:0] res);
    reg [7:0] acc;
    always @(posedge clk) begin
        if(ld) acc <= d;
        else acc <= acc - 1;
    end
    assign res = acc;
endmodule