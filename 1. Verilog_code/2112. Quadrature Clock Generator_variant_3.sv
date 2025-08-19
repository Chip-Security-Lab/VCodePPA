//SystemVerilog
module quadrature_clk_gen(
    input reference_clk,
    input reset_n,
    output reg I_clk,  // In-phase clock
    output reg Q_clk   // Quadrature clock (90° phase shift)
);
    reg toggle_p, toggle_n;
    reg next_I_clk;
    reg next_Q_clk;
    
    // Pre-compute next state logic
    always @(*) begin
        next_I_clk = toggle_p ? ~I_clk : I_clk;
        next_Q_clk = toggle_n ? ~Q_clk : Q_clk;
    end
    
    // Positive edge domain
    always @(posedge reference_clk or negedge reset_n) begin
        if (!reset_n) begin
            toggle_p <= 1'b0;
            I_clk <= 1'b0;
        end else begin
            toggle_p <= ~toggle_p;
            I_clk <= next_I_clk;
        end
    end
    
    // Negative edge domain
    always @(negedge reference_clk or negedge reset_n) begin
        if (!reset_n) begin
            toggle_n <= 1'b0;
            Q_clk <= 1'b0;
        end else begin
            toggle_n <= toggle_p;
            Q_clk <= next_Q_clk;
        end
    end
endmodule