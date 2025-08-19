//SystemVerilog
///////////////////////////////////////////////////////////////////////////////
// Module: pipelined_xnor
// Description: Fully pipelined XNOR implementation with proper flow control
// Standard: IEEE 1364-2005
///////////////////////////////////////////////////////////////////////////////
module combo_logic_xnor (
    input  wire        clk,          // System clock
    input  wire        rst_n,        // Active low reset
    input  wire        in_valid,     // Input data valid signal
    input  wire        in_data1,     // First input operand 
    input  wire        in_data2,     // Second input operand
    output wire        in_ready,     // Ready to accept new input
    output wire        out_valid,    // Output data valid
    output wire        out_data,     // XNOR result output
    input  wire        out_ready     // Downstream ready to accept output
);

    // Pipeline stage valid signals
    reg stage1_valid, stage2_valid, stage3_valid;
    
    // Pipeline data registers
    reg stage1_in_data1, stage1_in_data2;
    reg stage2_nand1_out, stage2_nand2_out;
    reg stage3_out_data;
    
    // Intermediate combinational signals
    wire nand1_out, nand2_out, or_out;
    
    // Pipeline flow control - ready signals propagate backward
    wire stage3_ready;
    wire stage2_ready;
    wire stage1_ready;
    
    assign stage3_ready = out_ready || !stage3_valid;
    assign stage2_ready = !stage2_valid || stage3_ready;
    assign stage1_ready = !stage1_valid || stage2_ready;
    assign in_ready = stage1_ready;
    
    // First pipeline stage - register inputs
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage1_valid <= 1'b0;
            stage1_in_data1 <= 1'b0;
            stage1_in_data2 <= 1'b0;
        end else if (stage1_ready) begin
            stage1_valid <= in_valid;
            if (in_valid) begin
                stage1_in_data1 <= in_data1;
                stage1_in_data2 <= in_data2;
            end
        end
    end
    
    // Combinational logic for first pipeline stage
    assign nand1_out = ~(~stage1_in_data1 & ~stage1_in_data2); // NAND of inverted inputs
    assign nand2_out = ~(stage1_in_data1 & stage1_in_data2);   // NAND of original inputs
    
    // Second pipeline stage - register intermediate results
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage2_valid <= 1'b0;
            stage2_nand1_out <= 1'b0;
            stage2_nand2_out <= 1'b0;
        end else if (stage2_ready) begin
            stage2_valid <= stage1_valid;
            if (stage1_valid) begin
                stage2_nand1_out <= nand1_out;
                stage2_nand2_out <= nand2_out;
            end
        end
    end
    
    // Combinational logic for second pipeline stage
    assign or_out = ~(stage2_nand1_out & stage2_nand2_out); // XNOR result
    
    // Output register stage
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage3_valid <= 1'b0;
            stage3_out_data <= 1'b0;
        end else if (stage3_ready) begin
            stage3_valid <= stage2_valid;
            if (stage2_valid) begin
                stage3_out_data <= or_out;
            end
        end
    end
    
    // Connect outputs
    assign out_valid = stage3_valid;
    assign out_data = stage3_out_data;

endmodule