//SystemVerilog
module ICMU_StackSync #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 8,
    parameter STACK_DEPTH = 16
)(
    input clk,
    input rst_n,
    input int_save_en,
    input int_restore_en,
    input [DATA_WIDTH-1:0] context_in,
    output reg [DATA_WIDTH-1:0] context_out,
    output reg stack_full
);

    reg [DATA_WIDTH-1:0] stack [0:STACK_DEPTH-1];
    reg [ADDR_WIDTH-1:0] stack_ptr;
    reg [ADDR_WIDTH-1:0] next_stack_ptr;
    reg [DATA_WIDTH-1:0] next_context_out;
    reg next_stack_full;
    reg [ADDR_WIDTH-1:0] stack_ptr_plus_1;
    reg [ADDR_WIDTH-1:0] stack_ptr_minus_1;
    reg stack_ptr_is_max;
    reg stack_ptr_is_zero;

    // LUT-based subtractor for stack_ptr_minus_1
    reg [ADDR_WIDTH-1:0] lut_sub [0:255];
    reg [ADDR_WIDTH-1:0] stack_ptr_minus_1_lut;
    
    // Initialize LUT
    integer j;
    initial begin
        for (j = 0; j < 256; j = j + 1) begin
            lut_sub[j] = j - 1;
        end
    end

    // Combinational logic for next state calculation
    always @(*) begin
        stack_ptr_plus_1 = stack_ptr + 1;
        stack_ptr_minus_1 = lut_sub[stack_ptr];
        stack_ptr_is_max = (stack_ptr == STACK_DEPTH-1);
        stack_ptr_is_zero = (stack_ptr == 0);
        
        if (int_save_en && !stack_full) begin
            next_stack_ptr = stack_ptr_plus_1;
            next_stack_full = stack_ptr_is_max;
        end else if (int_restore_en && !stack_ptr_is_zero) begin
            next_stack_ptr = stack_ptr_minus_1;
            next_stack_full = 1'b0;
        end else begin
            next_stack_ptr = stack_ptr;
            next_stack_full = stack_full;
        end
    end

    // Sequential logic for state update
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stack_ptr <= 0;
            stack_full <= 0;
            context_out <= 0;
        end else begin
            stack_ptr <= next_stack_ptr;
            stack_full <= next_stack_full;
            
            if (int_save_en && !stack_full) begin
                stack[stack_ptr] <= context_in;
            end else if (int_restore_en && !stack_ptr_is_zero) begin
                context_out <= stack[stack_ptr_minus_1];
            end
        end
    end

endmodule