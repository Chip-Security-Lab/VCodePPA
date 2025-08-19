//SystemVerilog
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
            if (push && |irq_sources && (stack_ptr < DEPTH)) begin
                casez (irq_sources)
                    8'b1???????: begin
                        irq_stack[stack_ptr] <= 7;
                        current_irq_id <= 7;
                    end
                    8'b01??????: begin
                        irq_stack[stack_ptr] <= 6;
                        current_irq_id <= 6;
                    end
                    8'b001?????: begin
                        irq_stack[stack_ptr] <= 5;
                        current_irq_id <= 5;
                    end
                    8'b0001????: begin
                        irq_stack[stack_ptr] <= 4;
                        current_irq_id <= 4;
                    end
                    8'b00001???: begin
                        irq_stack[stack_ptr] <= 3;
                        current_irq_id <= 3;
                    end
                    8'b000001??: begin
                        irq_stack[stack_ptr] <= 2;
                        current_irq_id <= 2;
                    end
                    8'b0000001?: begin
                        irq_stack[stack_ptr] <= 1;
                        current_irq_id <= 1;
                    end
                    8'b00000001: begin
                        irq_stack[stack_ptr] <= 0;
                        current_irq_id <= 0;
                    end
                endcase
                stack_ptr <= stack_ptr + 1;
                current_irq_valid <= 1;
            end else if (pop && (stack_ptr > 0)) begin
                stack_ptr <= stack_ptr - 1;
                current_irq_valid <= (stack_ptr > 1);
                if (current_irq_valid) begin
                    current_irq_id <= irq_stack[stack_ptr - 1];
                end
            end
        end
    end
endmodule