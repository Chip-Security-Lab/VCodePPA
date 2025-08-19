//SystemVerilog
// IEEE 1364-2005 Verilog standard
module AsyncRstSyncEn #(parameter W=6) (
    input sys_clk, async_rst_n, en_shift,
    input serial_data,
    output reg [W-1:0] shift_reg
);
    // Pipeline stage registers
    reg [W-1:0] shift_reg_stage1;
    reg [W-1:0] shift_reg_stage2;
    
    // Pipeline control signals
    reg valid_stage1, valid_stage2;
    reg serial_data_stage1;
    
    // Stage 1: Capture input and prepare shift operation
    always @(posedge sys_clk or negedge async_rst_n) begin
        if (!async_rst_n) begin
            shift_reg_stage1 <= {W{1'b0}};
            serial_data_stage1 <= 1'b0;
            valid_stage1 <= 1'b0;
        end else begin
            valid_stage1 <= en_shift;
            serial_data_stage1 <= serial_data;
            if (en_shift)
                shift_reg_stage1 <= shift_reg;
        end
    end
    
    // Stage 2: Perform the actual shift operation
    always @(posedge sys_clk or negedge async_rst_n) begin
        if (!async_rst_n) begin
            shift_reg_stage2 <= {W{1'b0}};
            valid_stage2 <= 1'b0;
        end else begin
            valid_stage2 <= valid_stage1;
            if (valid_stage1)
                shift_reg_stage2 <= {shift_reg_stage1[W-2:0], serial_data_stage1};
        end
    end
    
    // Final stage: Update the output register
    always @(posedge sys_clk or negedge async_rst_n) begin
        if (!async_rst_n) begin
            shift_reg <= {W{1'b0}};
        end else if (valid_stage2) begin
            shift_reg <= shift_reg_stage2;
        end
    end
endmodule