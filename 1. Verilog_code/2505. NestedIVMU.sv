module NestedIVMU (
    input wire clk, rst_n,
    input wire [3:0] irq,
    input wire ack, ret,
    output reg [31:0] vec_addr,
    output reg irq_active
);
    reg [31:0] vec_table [0:3];
    reg [1:0] stack_ptr;
    reg [31:0] ret_stack [0:3];
    reg [3:0] pri_level, active_irqs;
    integer i;
    
    initial for (i = 0; i < 4; i = i + 1) 
        vec_table[i] = 32'h4000_0000 + (i << 4);
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stack_ptr <= 0; pri_level <= 0;
            active_irqs <= 0; irq_active <= 0;
        end else if (ret && stack_ptr > 0) begin
            stack_ptr <= stack_ptr - 1;
            vec_addr <= ret_stack[stack_ptr-1];
            pri_level <= stack_ptr > 1 ? stack_ptr - 1 : 0;
        end else if (|irq && stack_ptr < 4) begin
            for (i = 3; i >= 0; i = i - 1) begin
                if (irq[i] && i > pri_level) begin
                    ret_stack[stack_ptr] <= vec_addr;
                    vec_addr <= vec_table[i];
                    stack_ptr <= stack_ptr + 1;
                    pri_level <= i;
                    irq_active <= 1;
                    active_irqs[i] <= 1;
                end
            end
        end else if (ack) begin
            active_irqs[pri_level] <= 0;
            if (stack_ptr == 1) irq_active <= 0;
        end
    end
endmodule