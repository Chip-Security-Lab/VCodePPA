module multiphase_clock(
    input sys_clk,
    input rst,
    output [7:0] phase_clks
);
    reg [7:0] shift_reg;
    
    always @(posedge sys_clk or posedge rst) begin
        if (rst)
            shift_reg <= 8'b00000001;
        else
            shift_reg <= {shift_reg[6:0], shift_reg[7]};
    end
    
    assign phase_clks = shift_reg;
endmodule
