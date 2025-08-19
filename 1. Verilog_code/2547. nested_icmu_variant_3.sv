//SystemVerilog
module nested_icmu #(
    parameter NEST_LEVELS = 4,
    parameter WIDTH = 32
)(
    input clk, reset_n,
    input [WIDTH-1:0] irq,
    input [WIDTH*4-1:0] irq_priority_flat,
    input complete,
    output reg [4:0] active_irq,
    output reg [4:0] stack_ptr,
    output reg ctx_switch
);
    reg [4:0] irq_stack [0:NEST_LEVELS-1];
    reg [3:0] pri_stack [0:NEST_LEVELS-1];
    reg [3:0] current_priority;
    wire [3:0] irq_priority [0:WIDTH-1];
    integer i;
    reg found_irq;

    // Wires for CLA inputs and outputs
    wire [4:0] stack_ptr_plus_1_comb;
    wire cout_plus_1;
    wire [4:0] stack_ptr_minus_1_comb;
    wire cout_minus_1;

    // From flattened array extract priority
    genvar g;
    generate
        for (g = 0; g < WIDTH; g = g + 1) begin: prio_map
            assign irq_priority[g] = irq_priority_flat[g*4+3:g*4];
        end
    endgenerate

    // Instantiate CLA for increment (stack_ptr + 1)
    cla_adder_5bit adder_inc (
        .a(stack_ptr),
        .b(5'd1),
        .cin(1'b0),
        .sum(stack_ptr_plus_1_comb),
        .cout(cout_plus_1)
    );

    // Instantiate CLA for decrement (stack_ptr - 1)
    // A - B = A + (~B) + 1 (2's complement)
    // B = 1 (5'd1), ~B = 5'b11110
    // A = stack_ptr, B_comp = ~5'd1, Cin = 1
    cla_adder_5bit adder_dec (
        .a(stack_ptr),
        .b(~5'd1), // 5'b11110
        .cin(1'b1),
        .sum(stack_ptr_minus_1_comb),
        .cout(cout_minus_1)
    );

    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            stack_ptr <= 5'd0;
            active_irq <= 5'd31;
            current_priority <= 4'd0;
            ctx_switch <= 1'b0;
            found_irq <= 1'b0;

            // Initialize stack
            for (i = 0; i < NEST_LEVELS; i = i + 1) begin
                irq_stack[i] <= 5'd0;
                pri_stack[i] <= 4'd0;
            end
        end else begin
            // Default assignments for the cycle
            ctx_switch <= 1'b0;
            found_irq <= 1'b0;

            // Handle interrupt complete - Flattened nested if-else
            // Original: if (complete && stack_ptr > 0) { if (stack_ptr > 1) { ... } else { ... } }
            // Flattened:
            if (complete && stack_ptr > 1) begin
                // Use CLA for decrement
                stack_ptr <= stack_ptr_minus_1_comb;
                // Access previous stack level (stack_ptr_old - 2)
                active_irq <= irq_stack[stack_ptr_minus_1_comb-1];
                current_priority <= pri_stack[stack_ptr_minus_1_comb-1];
                ctx_switch <= 1'b1;
            end else if (complete && stack_ptr == 1) begin
                // Use CLA for decrement
                stack_ptr <= stack_ptr_minus_1_comb; // stack_ptr becomes 0
                active_irq <= 5'd31; // No active interrupt
                current_priority <= 4'd0;
                ctx_switch <= 1'b1;
            end
            // Note: If 'complete' is false or 'stack_ptr' is 0, the above blocks are skipped.
            // The registers stack_ptr, active_irq, current_priority are not updated by this block in that case.
            // ctx_switch remains 0 from the default unless updated above.


            // Use combinatorial logic to find high priority interrupt
            // This block executes if ctx_switch was 0 at the start of the cycle.
            // It follows the complete handling block, allowing its assignments to potentially override.
            if (!ctx_switch) begin
                for (i = 0; i < WIDTH; i = i + 1) begin
                    // Found a higher priority interrupt
                    if (irq[i] && irq_priority[i] > current_priority &&
                        stack_ptr < NEST_LEVELS && !found_irq) begin
                        irq_stack[stack_ptr] <= i[4:0];
                        pri_stack[stack_ptr] <= irq_priority[i];
                        // Use CLA for increment
                        stack_ptr <= stack_ptr_plus_1_comb;
                        active_irq <= i[4:0];
                        current_priority <= irq_priority[i];
                        ctx_switch <= 1'b1; // Context switch happens
                        found_irq <= 1'b1; // Use flag instead of break
                    end
                end
            end
        end
    end
endmodule

// 5-bit Carry Lookahead Adder Module
module cla_adder_5bit (
    input [4:0] a,
    input [4:0] b,
    input cin,
    output [4:0] sum,
    output cout
);
    wire [4:0] p; // Propagate
    wire [4:0] g; // Generate
    wire [5:0] c; // Carries (c[0] is cin, c[5] is cout)

    assign c[0] = cin;

    genvar i;
    for (i = 0; i < 5; i = i + 1) begin : bit_pg_sum
        assign p[i] = a[i] ^ b[i];
        assign g[i] = a[i] & b[i];
        assign sum[i] = p[i] ^ c[i];
    end

    // CLA Carry Generation - Direct expansion
    assign c[1] = g[0] | (p[0] & c[0]);
    assign c[2] = g[1] | (p[1] & c[1]);
    assign c[3] = g[2] | (p[2] & c[2]);
    assign c[4] = g[3] | (p[3] & c[3]);
    assign c[5] = g[4] | (p[4] & c[4]);

    assign cout = c[5];

endmodule