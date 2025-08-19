//SystemVerilog
module enabled_pattern_compare #(parameter DWIDTH = 16) (
    input clk, rst_n, en,
    input [DWIDTH-1:0] in_data, in_pattern,
    output reg match
);
    // Pipeline registers
    reg [1:0] control;
    reg [1:0] control_r;
    reg pattern_match_r;
    
    // First pipeline stage - compute control and pattern comparison
    always @(*) begin
        control = {rst_n, en};
    end
    
    // Second pipeline stage - register control and comparison result
    always @(posedge clk) begin
        control_r <= control;
        pattern_match_r <= (in_data == in_pattern);
    end
    
    // Final stage - update match output with pipelined signals
    always @(posedge clk) begin
        case(control_r)
            2'b00, 2'b01: match <= 1'b0;      // !rst_n
            2'b10:        match <= match;      // rst_n && !en
            2'b11:        match <= pattern_match_r; // rst_n && en
        endcase
    end
endmodule