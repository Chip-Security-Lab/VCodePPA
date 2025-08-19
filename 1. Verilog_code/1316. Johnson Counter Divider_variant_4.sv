//SystemVerilog
module johnson_divider #(parameter WIDTH = 4) (
    input wire clock_i, rst_i,
    output reg clock_o
);
    reg [WIDTH-2:0] johnson;
    reg feedback_reg;
    
    always @(posedge clock_i) begin
        if (rst_i) begin
            johnson <= {(WIDTH-1){1'b0}};
            feedback_reg <= 1'b1;
            clock_o <= 1'b0;
        end
        else begin
            // Moved registers backward through combinational logic
            johnson <= {feedback_reg, johnson[WIDTH-2:1]};
            feedback_reg <= ~johnson[0];
            clock_o <= johnson[0];
        end
    end
endmodule