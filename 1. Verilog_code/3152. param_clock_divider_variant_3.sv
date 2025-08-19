//SystemVerilog
module param_clock_divider #(
    parameter DIVISOR = 10
)(
    input wire clock_i,
    input wire reset_i,
    output reg clock_o
);
    localparam COUNT_WIDTH = $clog2(DIVISOR);
    localparam COUNT_MAX = DIVISOR - 1;
    
    reg [COUNT_WIDTH-1:0] count;
    wire count_eq_max;
    wire count_lt_max;
    
    assign count_eq_max = (count == COUNT_MAX);
    assign count_lt_max = (count < COUNT_MAX);
    
    always @(posedge clock_i) begin
        if (reset_i) begin
            count <= {COUNT_WIDTH{1'b0}};
            clock_o <= 1'b0;
        end else begin
            count <= count_eq_max ? {COUNT_WIDTH{1'b0}} : count + 1'b1;
            clock_o <= count_eq_max ? ~clock_o : clock_o;
        end
    end
endmodule