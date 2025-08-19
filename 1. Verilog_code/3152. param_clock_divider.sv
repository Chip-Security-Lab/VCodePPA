module param_clock_divider #(
    parameter DIVISOR = 10
)(
    input wire clock_i,
    input wire reset_i,
    output reg clock_o
);
    reg [$clog2(DIVISOR)-1:0] count;
    
    always @(posedge clock_i) begin
        if (reset_i) begin
            count <= 0;
            clock_o <= 0;
        end else if (count == DIVISOR-1) begin
            count <= 0;
            clock_o <= ~clock_o;
        end else
            count <= count + 1;
    end
endmodule