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
    
    // Priority encoder using if-else
    reg [2:0] priority_encoded;
    always @(*) begin
        if (irq_sources[7]) begin
            priority_encoded = 3'd7;
        end else if (irq_sources[6]) begin
            priority_encoded = 3'd6;
        end else if (irq_sources[5]) begin
            priority_encoded = 3'd5;
        end else if (irq_sources[4]) begin
            priority_encoded = 3'd4;
        end else if (irq_sources[3]) begin
            priority_encoded = 3'd3;
        end else if (irq_sources[2]) begin
            priority_encoded = 3'd2;
        end else if (irq_sources[1]) begin
            priority_encoded = 3'd1;
        end else if (irq_sources[0]) begin
            priority_encoded = 3'd0;
        end else begin
            priority_encoded = 3'd0;
        end
    end
    
    always @(posedge clk) begin
        if (reset) begin
            stack_ptr <= 0;
            current_irq_valid <= 0;
            current_irq_id <= 0;
            irq_stack[0] <= 0;
            irq_stack[1] <= 0;
        end else begin
            if (push && |irq_sources && stack_ptr < DEPTH) begin
                irq_stack[stack_ptr] <= priority_encoded;
                stack_ptr <= stack_ptr + 1;
                current_irq_valid <= 1;
                current_irq_id <= priority_encoded;
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