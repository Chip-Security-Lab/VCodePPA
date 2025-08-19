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
    reg [ADDR_WIDTH-1:0] stack_ptr_stage1, stack_ptr_stage2;
    reg [1:0] operation_state_stage1, operation_state_stage2;
    reg [DATA_WIDTH-1:0] context_in_stage1;
    reg int_save_en_stage1, int_restore_en_stage1;
    reg stack_full_stage1, stack_full_stage2;

    localparam IDLE = 2'b00;
    localparam SAVE = 2'b01;
    localparam RESTORE = 2'b10;

    // Stage 1: Input and State Decoding
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            operation_state_stage1 <= IDLE;
            stack_ptr_stage1 <= 0;
            stack_full_stage1 <= 0;
            context_in_stage1 <= 0;
            int_save_en_stage1 <= 0;
            int_restore_en_stage1 <= 0;
        end else begin
            context_in_stage1 <= context_in;
            int_save_en_stage1 <= int_save_en;
            int_restore_en_stage1 <= int_restore_en;
            
            if (int_save_en && !stack_full)
                operation_state_stage1 <= SAVE;
            else if (int_restore_en && stack_ptr_stage1 != 0)
                operation_state_stage1 <= RESTORE;
            else
                operation_state_stage1 <= IDLE;
        end
    end

    // Stage 2: Stack Operations
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            operation_state_stage2 <= IDLE;
            stack_ptr_stage2 <= 0;
            stack_full_stage2 <= 0;
            context_out <= 0;
        end else begin
            operation_state_stage2 <= operation_state_stage1;
            stack_ptr_stage2 <= stack_ptr_stage1;
            stack_full_stage2 <= stack_full_stage1;
            
            case (operation_state_stage1)
                SAVE: begin
                    stack[stack_ptr_stage1] <= context_in_stage1;
                    stack_ptr_stage2 <= stack_ptr_stage1 + 1;
                    stack_full_stage2 <= (stack_ptr_stage1 == STACK_DEPTH-1);
                end
                
                RESTORE: begin
                    stack_ptr_stage2 <= stack_ptr_stage1 - 1;
                    context_out <= stack[stack_ptr_stage1-1];
                    stack_full_stage2 <= 0;
                end
            endcase
        end
    end

    // Stage 3: Output Update
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stack_full <= 0;
        end else begin
            stack_full <= stack_full_stage2;
        end
    end
endmodule