//SystemVerilog
module BiDirShift #(parameter BITS=8) (
    input clk, rst, dir, s_in,
    output [BITS-1:0] q
);

    reg [BITS-1:0] q_reg;
    reg dir_reg, s_in_reg;
    reg [BITS-1:0] next_q_reg;
    wire [BITS-1:0] next_q_comb;
    
    // Input register block
    always @(posedge clk) begin
        if (rst) begin
            dir_reg <= 1'b0;
            s_in_reg <= 1'b0;
        end else begin
            dir_reg <= dir;
            s_in_reg <= s_in;
        end
    end
    
    // First stage combinational logic
    assign next_q_comb = dir_reg ? {q_reg[BITS-2:0], s_in_reg} : {s_in_reg, q_reg[BITS-1:1]};
    
    // Pipeline register
    always @(posedge clk) begin
        if (rst)
            next_q_reg <= {BITS{1'b0}};
        else
            next_q_reg <= next_q_comb;
    end
    
    // Output register block
    always @(posedge clk) begin
        if (rst) 
            q_reg <= {BITS{1'b0}};
        else 
            q_reg <= next_q_reg;
    end
    
    assign q = q_reg;
    
endmodule