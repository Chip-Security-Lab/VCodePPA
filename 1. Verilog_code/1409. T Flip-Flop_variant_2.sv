//SystemVerilog
module t_flip_flop (
    input wire clk,
    input wire t,
    output wire q
);
    reg t_reg;
    reg q_internal;
    
    // Register the input control signal
    always @(posedge clk) begin
        t_reg <= t;
    end
    
    // Move the flip-flop logic after input registration
    always @(posedge clk) begin
        q_internal <= t_reg ? ~q_internal : q_internal;
    end
    
    // Connect to output
    assign q = q_internal;
    
endmodule