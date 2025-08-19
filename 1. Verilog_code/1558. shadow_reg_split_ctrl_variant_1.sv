//SystemVerilog
module shadow_reg_split_ctrl #(parameter DW=12) (
    input clk, load, update,
    input [DW-1:0] datain,
    output reg [DW-1:0] dataout
);
    reg [DW-1:0] shadow_stage1, shadow_stage2;
    reg valid_stage1, valid_stage2;
    reg [DW-1:0] complement_data;
    reg [DW-1:0] subtraction_result;
    
    // Binary complement subtraction implementation
    // For subtraction: datain - shadow_stage1
    always @(*) begin
        complement_data = ~shadow_stage1 + 1'b1; // Two's complement
        subtraction_result = datain + complement_data; // Adding two's complement is equivalent to subtraction
    end

    // Stage 1: Load data into shadow register
    always @(posedge clk) begin
        if (load) begin
            shadow_stage1 <= subtraction_result; // Store subtraction result instead of direct datain
            valid_stage1 <= 1'b1;
        end else begin
            valid_stage1 <= 1'b0;
        end
    end

    // Stage 2: Update output from shadow register
    always @(posedge clk) begin
        shadow_stage2 <= shadow_stage1; // Forward shadow_stage1 to stage 2
        valid_stage2 <= valid_stage1; // Propagate valid signal
    end

    // Final stage: Output data
    always @(posedge clk) begin
        if (valid_stage2 && update) begin
            dataout <= shadow_stage2;
        end
    end
endmodule