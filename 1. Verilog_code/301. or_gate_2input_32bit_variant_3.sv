//SystemVerilog
module or_gate_2input_32bit (
    input wire clk,              // Clock input added for pipelining
    input wire rst_n,            // Active-low reset added for pipeline control
    input wire [31:0] a,
    input wire [31:0] b,
    output wire [31:0] y
);
    // Split the 32-bit operation into four 8-bit stages for better timing
    wire [7:0] slice1_a, slice1_b, slice2_a, slice2_b, slice3_a, slice3_b, slice4_a, slice4_b;
    
    // Pipeline stage registers
    reg [7:0] slice1_result_stage1, slice2_result_stage1, slice3_result_stage1, slice4_result_stage1;
    reg [15:0] lower_result_stage2, upper_result_stage2;
    reg [31:0] final_result_stage3;
    
    // Input stage - split inputs into 8-bit slices
    assign slice1_a = a[7:0];
    assign slice1_b = b[7:0];
    assign slice2_a = a[15:8];
    assign slice2_b = b[15:8];
    assign slice3_a = a[23:16];
    assign slice3_b = b[23:16];
    assign slice4_a = a[31:24];
    assign slice4_b = b[31:24];
    
    // Pipeline stage 1 - process each 8-bit slice separately
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            slice1_result_stage1 <= 8'b0;
            slice2_result_stage1 <= 8'b0;
            slice3_result_stage1 <= 8'b0;
            slice4_result_stage1 <= 8'b0;
        end else begin
            slice1_result_stage1 <= slice1_a | slice1_b;
            slice2_result_stage1 <= slice2_a | slice2_b;
            slice3_result_stage1 <= slice3_a | slice3_b;
            slice4_result_stage1 <= slice4_a | slice4_b;
        end
    end
    
    // Pipeline stage 2 - combine into 16-bit results
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            lower_result_stage2 <= 16'b0;
            upper_result_stage2 <= 16'b0;
        end else begin
            lower_result_stage2 <= {slice2_result_stage1, slice1_result_stage1};
            upper_result_stage2 <= {slice4_result_stage1, slice3_result_stage1};
        end
    end
    
    // Pipeline stage 3 - combine into final 32-bit result
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            final_result_stage3 <= 32'b0;
        end else begin
            final_result_stage3 <= {upper_result_stage2, lower_result_stage2};
        end
    end
    
    // Output assignment
    assign y = final_result_stage3;
    
endmodule