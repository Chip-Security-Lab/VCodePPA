//SystemVerilog
// SystemVerilog
// IEEE 1364-2005
module logical_shifter #(parameter W = 16) (
    input wire clock, reset_n, load, shift,
    input wire [W-1:0] data,
    output wire [W-1:0] q_out
);
    reg [W-1:0] q_reg;
    
    // Combinational logic for next state calculation
    reg [W-1:0] next_q;
    
    // Move logic before the register (forward retiming)
    always @(*) begin
        if (load) begin
            next_q = data;
        end
        else if (shift) begin
            next_q = {1'b0, q_reg[W-1:1]};
        end
        else begin
            next_q = q_reg;
        end
    end
    
    // Single register stage after the combinational logic
    always @(posedge clock or negedge reset_n) begin
        if (!reset_n)
            q_reg <= {W{1'b0}};
        else
            q_reg <= next_q;
    end
    
    assign q_out = q_reg;
endmodule