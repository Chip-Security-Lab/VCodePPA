//SystemVerilog
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

    initial begin
        vec_table[0] = 32'h4000_0000 + (0 << 4);
        vec_table[1] = 32'h4000_0000 + (1 << 4);
        vec_table[2] = 32'h4000_0000 + (2 << 4);
        vec_table[3] = 32'h4000_0000 + (3 << 4);
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stack_ptr <= 0;
            pri_level <= 0;
            active_irqs <= 0;
            irq_active <= 0;
            // vec_addr initialization is missing in original reset, assuming it retains old value or is don't care on reset
        end else if (ret && stack_ptr > 0) begin
            stack_ptr <= stack_ptr - 1;
            vec_addr <= ret_stack[stack_ptr-1];
            pri_level <= stack_ptr > 1 ? stack_ptr - 1 : 0;
        end else if (|irq && stack_ptr < 4) begin
            // Unrolled loop for i = 3 down to 0
            // Note: Non-blocking assignments within sequential if blocks
            // evaluate RHS based on values at the start of the always block
            // and updates are scheduled. If multiple conditions are true,
            // the last scheduled assignment for a variable wins.
            
            // i = 3
            if (irq[3] && 3 > pri_level) begin
                ret_stack[stack_ptr] <= vec_addr;
                vec_addr <= vec_table[3];
                stack_ptr <= stack_ptr + 1;
                pri_level <= 3;
                irq_active <= 1;
                active_irqs[3] <= 1;
            end
            
            // i = 2
            if (irq[2] && 2 > pri_level) begin
                ret_stack[stack_ptr] <= vec_addr; // RHS uses value from start of block
                vec_addr <= vec_table[2];       // Overwrites vec_table[3] if i=3 condition was true
                stack_ptr <= stack_ptr + 1;     // Schedules increment based on value from start of block
                pri_level <= 2;                 // Overwrites 3 if i=3 condition was true
                irq_active <= 1;                // Schedules 1
                active_irqs[2] <= 1;            // Schedules 1
            end
            
            // i = 1
            if (irq[1] && 1 > pri_level) begin
                ret_stack[stack_ptr] <= vec_addr; // RHS uses value from start of block
                vec_addr <= vec_table[1];       // Overwrites vec_table[2] if i=2 condition was true
                stack_ptr <= stack_ptr + 1;     // Schedules increment based on value from start of block
                pri_level <= 1;                 // Overwrites 2 if i=2 condition was true
                irq_active <= 1;                // Schedules 1
                active_irqs[1] <= 1;            // Schedules 1
            end
            
            // i = 0
            if (irq[0] && 0 > pri_level) begin
                ret_stack[stack_ptr] <= vec_addr; // RHS uses value from start of block
                vec_addr <= vec_table[0];       // Overwrites vec_table[1] if i=1 condition was true
                stack_ptr <= stack_ptr + 1;     // Schedules increment based on value from start of block
                pri_level <= 0;                 // Overwrites 1 if i=1 condition was true
                irq_active <= 1;                // Schedules 1
                active_irqs[0] <= 1;            // Schedules 1
            end
        end else if (ack) begin
            active_irqs[pri_level] <= 0;
            if (stack_ptr == 1) begin
                irq_active <= 0;
            end
        end
    end
endmodule