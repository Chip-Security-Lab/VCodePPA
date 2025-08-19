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
    reg [ADDR_WIDTH-1:0] next_ptr;
    wire [ADDR_WIDTH-1:0] ptr_inv;
    wire [ADDR_WIDTH-1:0] ptr_plus1;
    wire [ADDR_WIDTH-1:0] ptr_minus1;
    wire ptr_sel;
    
    // Pipeline stage 1: Address calculation
    reg [ADDR_WIDTH-1:0] stack_ptr_stage1;
    reg [ADDR_WIDTH-1:0] ptr_inv_stage1;
    reg [ADDR_WIDTH-1:0] ptr_plus1_stage1;
    reg [ADDR_WIDTH-1:0] ptr_minus1_stage1;
    reg ptr_sel_stage1;
    reg int_save_en_stage1;
    reg int_restore_en_stage1;
    reg [DATA_WIDTH-1:0] context_in_stage1;
    
    // Pipeline stage 2: Stack access
    reg [ADDR_WIDTH-1:0] stack_ptr_stage2;
    reg [ADDR_WIDTH-1:0] next_ptr_stage2;
    reg int_save_en_stage2;
    reg int_restore_en_stage2;
    reg [DATA_WIDTH-1:0] context_in_stage2;
    reg [DATA_WIDTH-1:0] stack_data_stage2;
    
    // Pipeline stage 3: Output generation
    reg [ADDR_WIDTH-1:0] stack_ptr_stage3;
    reg int_save_en_stage3;
    reg int_restore_en_stage3;
    reg [DATA_WIDTH-1:0] context_in_stage3;
    reg [DATA_WIDTH-1:0] stack_data_stage3;
    reg stack_full_stage3;

    // Stage 1: Address calculation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stack_ptr_stage1 <= 0;
            ptr_inv_stage1 <= 0;
            ptr_plus1_stage1 <= 0;
            ptr_minus1_stage1 <= 0;
            ptr_sel_stage1 <= 0;
            int_save_en_stage1 <= 0;
            int_restore_en_stage1 <= 0;
            context_in_stage1 <= 0;
        end else begin
            stack_ptr_stage1 <= stack_ptr;
            ptr_inv_stage1 <= ~stack_ptr;
            ptr_plus1_stage1 <= stack_ptr + 1'b1;
            ptr_minus1_stage1 <= stack_ptr + (~stack_ptr) + 1'b1;
            ptr_sel_stage1 <= int_restore_en && stack_ptr != 0;
            int_save_en_stage1 <= int_save_en;
            int_restore_en_stage1 <= int_restore_en;
            context_in_stage1 <= context_in;
        end
    end

    // Stage 2: Stack access
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stack_ptr_stage2 <= 0;
            next_ptr_stage2 <= 0;
            int_save_en_stage2 <= 0;
            int_restore_en_stage2 <= 0;
            context_in_stage2 <= 0;
            stack_data_stage2 <= 0;
        end else begin
            stack_ptr_stage2 <= stack_ptr_stage1;
            next_ptr_stage2 <= ptr_sel_stage1 ? ptr_minus1_stage1 : ptr_plus1_stage1;
            int_save_en_stage2 <= int_save_en_stage1;
            int_restore_en_stage2 <= int_restore_en_stage1;
            context_in_stage2 <= context_in_stage1;
            stack_data_stage2 <= stack[ptr_minus1_stage1];
        end
    end

    // Stage 3: Output generation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stack_ptr_stage3 <= 0;
            int_save_en_stage3 <= 0;
            int_restore_en_stage3 <= 0;
            context_in_stage3 <= 0;
            stack_data_stage3 <= 0;
            stack_full_stage3 <= 0;
        end else begin
            stack_ptr_stage3 <= stack_ptr_stage2;
            int_save_en_stage3 <= int_save_en_stage2;
            int_restore_en_stage3 <= int_restore_en_stage2;
            context_in_stage3 <= context_in_stage2;
            stack_data_stage3 <= stack_data_stage2;
            stack_full_stage3 <= (stack_ptr_stage2 == STACK_DEPTH-1);
        end
    end

    // Final output stage
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stack_ptr <= 0;
            stack_full <= 0;
            context_out <= 0;
        end else begin
            if (int_save_en_stage3 && !stack_full_stage3) begin
                stack[stack_ptr_stage3] <= context_in_stage3;
                stack_ptr <= next_ptr_stage2;
                stack_full <= (stack_ptr_stage3 == STACK_DEPTH-1);
            end else if (int_restore_en_stage3 && stack_ptr_stage3 != 0) begin
                stack_ptr <= next_ptr_stage2;
                context_out <= stack_data_stage3;
                stack_full <= 0;
            end
        end
    end

endmodule