//SystemVerilog
module serialize_reg(
    input clk, reset,
    input [7:0] parallel_in,
    input load, shift_out,
    output [7:0] p_out,
    output serial_out
);
    // Pipeline stage 1 - Input capture and processing
    reg [7:0] shift_reg_stage1;
    reg load_stage1, shift_out_stage1;
    
    // Pipeline stage 2 - Shifting operation
    reg [7:0] shift_reg_stage2;
    reg serial_out_stage2;
    
    // Pipeline stage 3 - Output preparation
    reg [7:0] shift_reg_stage3;
    reg serial_out_stage3;
    
    // Assign final outputs
    assign p_out = shift_reg_stage3;
    assign serial_out = serial_out_stage3;
    
    // Pipeline stage 1 - Input capture
    always @(posedge clk) begin
        if (reset) begin
            shift_reg_stage1 <= 8'b0;
            load_stage1 <= 1'b0;
            shift_out_stage1 <= 1'b0;
        end else begin
            load_stage1 <= load;
            shift_out_stage1 <= shift_out;
            
            if (load) begin
                shift_reg_stage1 <= parallel_in;
            end else if (shift_out) begin
                shift_reg_stage1 <= {shift_reg_stage3[6:0], 1'b0};
            end else begin
                shift_reg_stage1 <= shift_reg_stage3;
            end
        end
    end
    
    // Pipeline stage 2 - Computation
    always @(posedge clk) begin
        if (reset) begin
            shift_reg_stage2 <= 8'b0;
            serial_out_stage2 <= 1'b0;
        end else begin
            shift_reg_stage2 <= shift_reg_stage1;
            
            if (load_stage1) begin
                serial_out_stage2 <= shift_reg_stage1[7];
            end else if (shift_out_stage1) begin
                serial_out_stage2 <= shift_reg_stage1[6];
            end else begin
                serial_out_stage2 <= serial_out_stage3;
            end
        end
    end
    
    // Pipeline stage 3 - Output
    always @(posedge clk) begin
        if (reset) begin
            shift_reg_stage3 <= 8'b0;
            serial_out_stage3 <= 1'b0;
        end else begin
            shift_reg_stage3 <= shift_reg_stage2;
            serial_out_stage3 <= serial_out_stage2;
        end
    end
endmodule