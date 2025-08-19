module NestedITRC #(parameter DEPTH=2) (
    input wire clk, reset,
    input wire [7:0] irq_sources,
    input wire push, pop,
    output reg current_irq_valid,
    output reg [2:0] current_irq_id
);
    reg [2:0] irq_stack [0:DEPTH-1];
    reg [1:0] stack_ptr; // 2 bits for DEPTH=2
    
    always @(posedge clk) begin
        if (reset) begin
            stack_ptr <= 0;
            current_irq_valid <= 0;
            current_irq_id <= 0;
            irq_stack[0] <= 0;
            irq_stack[1] <= 0;
        end else begin
            if (push && |irq_sources && stack_ptr < DEPTH) begin
                // Priority encoder instead of loop
                if (irq_sources[7]) begin
                    irq_stack[stack_ptr] <= 7;
                    stack_ptr <= stack_ptr + 1;
                    current_irq_valid <= 1;
                    current_irq_id <= 7;
                end
                else if (irq_sources[6]) begin
                    irq_stack[stack_ptr] <= 6;
                    stack_ptr <= stack_ptr + 1;
                    current_irq_valid <= 1;
                    current_irq_id <= 6;
                end
                else if (irq_sources[5]) begin
                    irq_stack[stack_ptr] <= 5;
                    stack_ptr <= stack_ptr + 1;
                    current_irq_valid <= 1;
                    current_irq_id <= 5;
                end
                else if (irq_sources[4]) begin
                    irq_stack[stack_ptr] <= 4;
                    stack_ptr <= stack_ptr + 1;
                    current_irq_valid <= 1;
                    current_irq_id <= 4;
                end
                else if (irq_sources[3]) begin
                    irq_stack[stack_ptr] <= 3;
                    stack_ptr <= stack_ptr + 1;
                    current_irq_valid <= 1;
                    current_irq_id <= 3;
                end
                else if (irq_sources[2]) begin
                    irq_stack[stack_ptr] <= 2;
                    stack_ptr <= stack_ptr + 1;
                    current_irq_valid <= 1;
                    current_irq_id <= 2;
                end
                else if (irq_sources[1]) begin
                    irq_stack[stack_ptr] <= 1;
                    stack_ptr <= stack_ptr + 1;
                    current_irq_valid <= 1;
                    current_irq_id <= 1;
                end
                else if (irq_sources[0]) begin
                    irq_stack[stack_ptr] <= 0;
                    stack_ptr <= stack_ptr + 1;
                    current_irq_valid <= 1;
                    current_irq_id <= 0;
                end
            end else if (pop && stack_ptr > 0) begin
                stack_ptr <= stack_ptr - 1;
                if (stack_ptr > 1) begin
                    current_irq_id <= irq_stack[0];
                    current_irq_valid <= 1;
                end else begin
                    current_irq_valid <= 0;
                end
            end
        end
    end
endmodule