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

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stack_ptr <= 0;
            stack_full <= 0;
            context_out <= 0;
        end else begin
            if (int_save_en && !stack_full) begin
                stack[stack_ptr] <= context_in;
                stack_ptr <= stack_ptr + 1;
                stack_full <= (stack_ptr == STACK_DEPTH-1);
            end else if (int_restore_en && stack_ptr != 0) begin
                stack_ptr <= stack_ptr - 1;
                context_out <= stack[stack_ptr-1];
                stack_full <= 0;
            end
        end
    end
endmodule
