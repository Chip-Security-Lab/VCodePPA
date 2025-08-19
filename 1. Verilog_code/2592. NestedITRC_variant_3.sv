//SystemVerilog
module NestedITRC #(parameter DEPTH=2) (
    input wire clk, reset,
    input wire [7:0] irq_sources,
    input wire push, pop,
    output reg current_irq_valid,
    output reg [2:0] current_irq_id
);
    reg [2:0] irq_stack [0:DEPTH-1];
    reg [1:0] stack_ptr;
    wire [2:0] next_irq_id;
    wire has_irq;
    wire can_push;
    wire can_pop;
    
    // Priority encoder logic
    assign next_irq_id = irq_sources[7] ? 3'd7 :
                        irq_sources[6] ? 3'd6 :
                        irq_sources[5] ? 3'd5 :
                        irq_sources[4] ? 3'd4 :
                        irq_sources[3] ? 3'd3 :
                        irq_sources[2] ? 3'd2 :
                        irq_sources[1] ? 3'd1 :
                        irq_sources[0] ? 3'd0 : 3'd0;
                        
    assign has_irq = |irq_sources;
    assign can_push = push && has_irq && (stack_ptr < DEPTH);
    assign can_pop = pop && (stack_ptr > 0);
    
    always @(posedge clk) begin
        if (reset) begin
            stack_ptr <= 0;
            current_irq_valid <= 0;
            current_irq_id <= 0;
            irq_stack[0] <= 0;
            irq_stack[1] <= 0;
        end else begin
            if (can_push) begin
                irq_stack[stack_ptr] <= next_irq_id;
                stack_ptr <= stack_ptr + 1;
                current_irq_valid <= 1;
                current_irq_id <= next_irq_id;
            end else if (can_pop) begin
                stack_ptr <= stack_ptr - 1;
                current_irq_valid <= (stack_ptr > 1);
                current_irq_id <= irq_stack[0];
            end
        end
    end
endmodule