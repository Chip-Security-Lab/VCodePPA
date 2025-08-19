//SystemVerilog
module pipelined_ashift (
    input clk, rst,
    input [31:0] din,
    input [4:0] shift,
    input valid_in,
    output reg valid_out,
    output reg [31:0] dout,
    output reg ready_in
);

    // Pipeline stage registers for data path
    reg [31:0] data_stage1, data_stage2, data_stage3;
    
    // Pipeline stage registers for shift amounts
    reg [4:0] shift_stage1, shift_stage2, shift_stage3;
    
    // Valid signals for pipeline control
    reg valid_stage1, valid_stage2, valid_stage3;
    
    // Intermediate computation results
    wire [31:0] stage1_result, stage2_result, stage3_result;
    
    // Stage 1: Process high 2 bits of shift amount
    assign stage1_result = din >>> (shift_stage1[4:3] * 8);
    
    // Stage 2: Process middle 2 bits of shift amount
    assign stage2_result = data_stage1 >>> (shift_stage2[2:1] * 2);
    
    // Stage 3: Process the last bit of shift amount
    assign stage3_result = data_stage2 >>> shift_stage3[0];
    
    // Ready signal generation - always ready when not in reset
    always @(posedge clk or posedge rst) begin
        if (rst)
            ready_in <= 1'b0;
        else
            ready_in <= 1'b1;
    end
    
    // Pipeline registers and control logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            // Reset all pipeline registers
            data_stage1 <= 32'b0;
            data_stage2 <= 32'b0;
            data_stage3 <= 32'b0;
            shift_stage1 <= 5'b0;
            shift_stage2 <= 5'b0;
            shift_stage3 <= 5'b0;
            valid_stage1 <= 1'b0;
            valid_stage2 <= 1'b0;
            valid_stage3 <= 1'b0;
            valid_out <= 1'b0;
            dout <= 32'b0;
        end else begin
            // Stage 1
            if (ready_in) begin
                data_stage1 <= stage1_result;
                shift_stage1 <= shift;
                valid_stage1 <= valid_in;
            end
            
            // Stage 2
            data_stage2 <= stage2_result;
            shift_stage2 <= shift_stage1;
            valid_stage2 <= valid_stage1;
            
            // Stage 3
            data_stage3 <= stage3_result;
            shift_stage3 <= shift_stage2;
            valid_stage3 <= valid_stage2;
            
            // Output stage
            dout <= stage3_result;
            valid_out <= valid_stage3;
        end
    end
    
endmodule