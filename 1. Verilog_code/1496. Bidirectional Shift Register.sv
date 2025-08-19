module bidir_shift_reg #(parameter WIDTH = 8) (
    input wire clk, rst, en, dir, data_in,
    output wire [WIDTH-1:0] q_out
);
    reg [WIDTH-1:0] shiftreg;
    
    always @(posedge clk) begin
        if (rst)
            shiftreg <= 0;
        else if (en) begin
            if (dir)  // shift left
                shiftreg <= {shiftreg[WIDTH-2:0], data_in};
            else      // shift right
                shiftreg <= {data_in, shiftreg[WIDTH-1:1]};
        end
    end
    
    assign q_out = shiftreg;
endmodule