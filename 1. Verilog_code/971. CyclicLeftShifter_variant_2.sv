//SystemVerilog
module CyclicLeftShifter #(parameter WIDTH=8) (
    input clk, rst_n, en,
    input serial_in,
    input flush,  // Pipeline flush control
    output ready, // Ready to accept new data
    input valid_in, // Input data valid
    output valid_out, // Output data valid
    output reg [WIDTH-1:0] parallel_out
);

    // Pipeline stage registers
    reg [WIDTH-1:0] stage1_data, stage2_data;
    reg stage1_valid, stage2_valid;
    
    // Conditional inverse subtractor signals
    wire [WIDTH-1:0] shift_result;
    wire cin, cout;
    wire [WIDTH-1:0] operand_a, operand_b;
    wire [WIDTH-1:0] b_adjusted;
    wire operation_sub;
    
    // Pipeline ready signal
    assign ready = 1'b1; // Always ready to accept data in this design
    
    // Pipeline valid output signal
    assign valid_out = stage2_valid;
    
    // Conditional inverse subtractor implementation
    assign operation_sub = 1'b1; // We're performing subtraction
    assign operand_a = {parallel_out[WIDTH-2:WIDTH/2], serial_in, parallel_out[WIDTH/2-2:0]};
    assign operand_b = {WIDTH{1'b0}}; // Second operand is 0 for shift operation
    assign b_adjusted = operation_sub ? ~operand_b : operand_b;
    assign cin = operation_sub ? 1'b1 : 1'b0;
    
    // Perform subtraction using conditional inverse method
    assign {cout, shift_result} = operand_a + b_adjusted + cin;
    
    // Stage 1: Capture input and perform first half of shift
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage1_data <= {WIDTH{1'b0}};
            stage1_valid <= 1'b0;
        end
        else if (flush) begin
            stage1_data <= {WIDTH{1'b0}};
            stage1_valid <= 1'b0;
        end
        else if (en && valid_in) begin
            // First half of shift operation using conditional inverse subtractor
            stage1_data <= shift_result;
            stage1_valid <= 1'b1;
        end
        else if (en) begin
            stage1_valid <= 1'b0;
        end
    end
    
    // Stage 2: Complete shift operation and prepare output
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage2_data <= {WIDTH{1'b0}};
            stage2_valid <= 1'b0;
        end
        else if (flush) begin
            stage2_data <= {WIDTH{1'b0}};
            stage2_valid <= 1'b0;
        end
        else if (en) begin
            // Second half of shift operation (data alignment)
            stage2_data <= stage1_data;
            stage2_valid <= stage1_valid;
        end
    end
    
    // Final output assignment
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            parallel_out <= {WIDTH{1'b0}};
        end
        else if (flush) begin
            parallel_out <= {WIDTH{1'b0}};
        end
        else if (en && stage2_valid) begin
            parallel_out <= stage2_data;
        end
    end

endmodule