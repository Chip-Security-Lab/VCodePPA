//SystemVerilog
module ring_counter_bidirectional (
    input clk,
    input dir,
    input rst,
    output reg [3:0] shift_reg
);

    // Pipeline registers
    reg dir_stage1, dir_stage2;
    reg [3:0] shift_reg_stage1, shift_reg_stage2;
    
    // Buffering registers for high fanout shift_reg_stage1
    reg [3:0] shift_reg_stage1_buf1;
    reg [3:0] shift_reg_stage1_buf2;
    
    // Stage 1: Register inputs and calculate intermediate values
    always @(posedge clk) begin
        if (rst) begin
            dir_stage1 <= 1'b0;
            shift_reg_stage1 <= 4'b0001;
        end
        else begin
            dir_stage1 <= dir;
            shift_reg_stage1 <= shift_reg;
        end
    end
    
    // Buffering for high fanout signal
    always @(posedge clk) begin
        if (rst) begin
            shift_reg_stage1_buf1 <= 4'b0001;
            shift_reg_stage1_buf2 <= 4'b0001;
        end
        else begin
            shift_reg_stage1_buf1 <= shift_reg_stage1;
            shift_reg_stage1_buf2 <= shift_reg_stage1;
        end
    end

    // Stage 2: Perform shifting calculation
    always @(posedge clk) begin
        if (rst) begin
            dir_stage2 <= 1'b0;
            shift_reg_stage2 <= 4'b0001;
        end
        else begin
            dir_stage2 <= dir_stage1;
            if (dir_stage1)
                shift_reg_stage2 <= {shift_reg_stage1_buf1[2:0], shift_reg_stage1_buf1[3]};
            else
                shift_reg_stage2 <= {shift_reg_stage1_buf2[0], shift_reg_stage1_buf2[3:1]};
        end
    end

    // Final stage: Update output register
    always @(posedge clk) begin
        if (rst)
            shift_reg <= 4'b0001;
        else
            shift_reg <= shift_reg_stage2;
    end

endmodule