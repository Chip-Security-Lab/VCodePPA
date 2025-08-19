//SystemVerilog
module dual_d_flip_flop (
    input wire clk,
    input wire rst_n,
    input wire d1,
    input wire d2,
    output wire q1,
    output wire q2
);
    reg q1_reg, q2_reg;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            q1_reg <= 1'b0;
            q2_reg <= 1'b0;
        end else begin
            q1_reg <= d1;
            q2_reg <= d2;
        end
    end
    
    assign q1 = q1_reg;
    assign q2 = q2_reg;
endmodule