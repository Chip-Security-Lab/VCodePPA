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
    reg [ADDR_WIDTH-1:0] stack_ptr_next;
    reg [DATA_WIDTH-1:0] context_out_next;
    reg stack_full_next;
    reg [DATA_WIDTH-1:0] stack_data_out;
    wire stack_empty;
    wire stack_almost_full;
    wire save_valid;
    wire restore_valid;

    assign stack_empty = (stack_ptr == 0);
    assign stack_almost_full = (stack_ptr == STACK_DEPTH-1);
    assign save_valid = int_save_en && !stack_full;
    assign restore_valid = int_restore_en && !stack_empty;

    always @(*) begin
        stack_ptr_next = stack_ptr;
        context_out_next = context_out;
        stack_full_next = stack_full;
        stack_data_out = stack[stack_ptr-1];

        case ({save_valid, restore_valid})
            2'b10: begin
                stack_ptr_next = stack_ptr + 1;
                stack_full_next = stack_almost_full;
            end
            2'b01: begin
                stack_ptr_next = stack_ptr - 1;
                context_out_next = stack_data_out;
                stack_full_next = 1'b0;
            end
            default: begin
                stack_ptr_next = stack_ptr;
                stack_full_next = stack_full;
            end
        endcase
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stack_ptr <= 0;
            stack_full <= 0;
            context_out <= 0;
        end else begin
            stack_ptr <= stack_ptr_next;
            stack_full <= stack_full_next;
            context_out <= context_out_next;
            
            if (save_valid) begin
                stack[stack_ptr] <= context_in;
            end
        end
    end
endmodule