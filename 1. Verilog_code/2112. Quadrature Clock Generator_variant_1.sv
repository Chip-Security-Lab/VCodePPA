//SystemVerilog
module quadrature_clk_gen(
    input  wire reference_clk,
    input  wire reset_n,
    output reg  I_clk,  // In-phase clock
    output reg  Q_clk   // Quadrature clock (90° phase shift)
);
    // Counter for clock division and phase generation
    reg [1:0] clk_counter;
    
    // Counter update process
    always @(posedge reference_clk or negedge reset_n) begin
        if (!reset_n) begin
            clk_counter <= 2'b00;
        end else begin
            clk_counter <= clk_counter + 1'b1;
        end
    end
    
    // I_clk generation process
    always @(posedge reference_clk or negedge reset_n) begin
        if (!reset_n) begin
            I_clk <= 1'b0;
        end else if (clk_counter[0] == 1'b1) begin
            I_clk <= ~I_clk;
        end
    end
    
    // Q_clk generation process with 90° phase shift
    always @(posedge reference_clk or negedge reset_n) begin
        if (!reset_n) begin
            Q_clk <= 1'b0;
        end else if (clk_counter == 2'b01) begin
            Q_clk <= ~Q_clk;
        end
    end
    
endmodule