//SystemVerilog
module level_async_ismu #(parameter WIDTH = 8)(
    input [WIDTH-1:0] irq_in,
    input [WIDTH-1:0] mask,
    input clear_n,
    output [WIDTH-1:0] active_irq,
    output irq_present
);
    wire [WIDTH-1:0] masked_irq;
    wire [WIDTH-1:0] inverted_mask;
    wire [WIDTH:0] subtraction_result;
    wire carry_out;
    
    // Two's complement implementation for mask operation
    assign inverted_mask = ~mask;
    assign subtraction_result = irq_in + inverted_mask + 1'b1;
    assign masked_irq = (subtraction_result[WIDTH-1:0] & irq_in) & inverted_mask;
    
    // Apply clear signal
    assign active_irq = masked_irq & {WIDTH{clear_n}};
    
    // Generate irq_present signal using reduction
    reg irq_flag;
    integer i;
    
    always @(*) begin
        irq_flag = 1'b0;
        i = 0;
        while (i < WIDTH) begin
            irq_flag = irq_flag | active_irq[i];
            i = i + 1;
        end
    end
    
    assign irq_present = irq_flag;
endmodule