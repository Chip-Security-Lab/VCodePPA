module johnson_divider #(parameter WIDTH = 4) (
    input clock_i, rst_i,
    output clock_o
);
    reg [WIDTH-1:0] johnson;
    
    always @(posedge clock_i) begin
        if (rst_i)
            johnson <= {WIDTH{1'b0}};
        else
            johnson <= {~johnson[0], johnson[WIDTH-1:1]};
    end
    
    assign clock_o = johnson[0];
endmodule