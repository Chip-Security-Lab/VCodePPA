//SystemVerilog
module t_ff_async_reset (
    input wire clk,
    input wire rst_n,
    input wire t,
    output wire q
);
    // Internal registered signals
    reg q_internal;
    reg t_reg;
    
    // Register the input t
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            t_reg <= 1'b0;
        else
            t_reg <= t;
    end
    
    // Implementation with retimed logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            q_internal <= 1'b0;
        else
            q_internal <= (t_reg == 1'b1) ? ~q_internal : q_internal;
    end
    
    // Connect internal register to output
    assign q = q_internal;
    
endmodule