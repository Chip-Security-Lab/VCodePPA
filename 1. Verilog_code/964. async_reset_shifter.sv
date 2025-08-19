module async_reset_shifter #(parameter WIDTH = 10) (
    input wire i_clk, i_arst_n, i_en,
    input wire i_data,
    output wire o_data
);
    reg [WIDTH-1:0] r_shifter;
    
    always @(posedge i_clk or negedge i_arst_n) begin
        if (!i_arst_n)
            r_shifter <= {WIDTH{1'b0}};
        else if (i_en)
            r_shifter <= {i_data, r_shifter[WIDTH-1:1]};
    end
    
    assign o_data = r_shifter[0];
endmodule