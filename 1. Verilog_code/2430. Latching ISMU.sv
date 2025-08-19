module latch_ismu #(parameter WIDTH = 16)(
    input wire i_clk, i_rst_b,
    input wire [WIDTH-1:0] i_int_src,
    input wire i_latch_en,
    input wire [WIDTH-1:0] i_int_clr,
    output reg [WIDTH-1:0] o_latched_int
);
    wire [WIDTH-1:0] int_set;
    
    assign int_set = i_int_src & {WIDTH{i_latch_en}};
    
    always @(posedge i_clk or negedge i_rst_b) begin
        if (!i_rst_b)
            o_latched_int <= {WIDTH{1'b0}};
        else
            o_latched_int <= (o_latched_int | int_set) & ~i_int_clr;
    end
endmodule