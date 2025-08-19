module level_async_ismu #(parameter WIDTH = 4)(
    input [WIDTH-1:0] irq_in,
    input [WIDTH-1:0] mask,
    input clear_n,
    output [WIDTH-1:0] active_irq,
    output irq_present
);
    wire [WIDTH-1:0] masked_irq;
    
    assign masked_irq = irq_in & ~mask;
    assign active_irq = masked_irq & {WIDTH{clear_n}};
    assign irq_present = |active_irq;
endmodule