module quadrature_clk_gen(
    input reference_clk,
    input reset_n,
    output reg I_clk,  // In-phase clock
    output reg Q_clk   // Quadrature clock (90° phase shift)
);
    reg toggle;
    
    always @(posedge reference_clk or negedge reset_n) begin
        if (!reset_n) begin
            toggle <= 1'b0;
            I_clk <= 1'b0;
        end else begin
            toggle <= ~toggle;
            if (toggle)
                I_clk <= ~I_clk;
        end
    end
    
    always @(negedge reference_clk or negedge reset_n) begin
        if (!reset_n)
            Q_clk <= 1'b0;
        else if (toggle)
            Q_clk <= ~Q_clk;
    end
endmodule