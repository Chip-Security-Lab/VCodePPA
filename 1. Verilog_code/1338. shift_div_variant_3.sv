//SystemVerilog
//IEEE 1364-2005 Verilog
module shift_div #(parameter PATTERN = 8'b1010_1100) (
    input wire clk,
    input wire rst,
    output wire clk_out
);
    // Internal signals
    wire [7:0] shift_reg_q;
    wire [7:0] shift_reg_next;
    
    // Instantiate combinational logic module
    shift_div_comb comb_logic (
        .shift_reg_q(shift_reg_q),
        .shift_reg_next(shift_reg_next),
        .clk_out(clk_out)
    );
    
    // Instantiate sequential logic module
    shift_div_seq #(.PATTERN(PATTERN)) seq_logic (
        .clk(clk),
        .rst(rst),
        .shift_reg_next(shift_reg_next),
        .shift_reg_q(shift_reg_q)
    );
endmodule

module shift_div_comb (
    input wire [7:0] shift_reg_q,
    output wire [7:0] shift_reg_next,
    output wire clk_out
);
    // Pure combinational logic
    assign shift_reg_next = {shift_reg_q[6:0], shift_reg_q[7]};
    assign clk_out = shift_reg_q[7];
endmodule

module shift_div_seq #(parameter PATTERN = 8'b1010_1100) (
    input wire clk,
    input wire rst,
    input wire [7:0] shift_reg_next,
    output reg [7:0] shift_reg_q
);
    // Pure sequential logic
    always @(posedge clk) begin
        if (rst)
            shift_reg_q <= PATTERN;
        else
            shift_reg_q <= shift_reg_next;
    end
endmodule