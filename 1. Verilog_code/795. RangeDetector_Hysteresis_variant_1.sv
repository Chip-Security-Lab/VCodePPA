//SystemVerilog
module RangeDetector_Hysteresis #(
    parameter WIDTH = 8,
    parameter HYST = 3
)(
    input clk, rst_n,
    input [WIDTH-1:0] data_in,
    input [WIDTH-1:0] center,
    output reg out_high
);

    // Pipeline registers
    reg [WIDTH-1:0] data_in_stage1, center_stage1;
    reg [WIDTH-1:0] data_in_stage2, center_stage2;
    reg [WIDTH-1:0] upper_threshold_stage2, lower_threshold_stage2;
    reg compare_upper_stage3, compare_lower_stage3;
    reg compare_upper_stage4, compare_lower_stage4;
    
    // Pipeline stage 1: Register inputs
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            data_in_stage1 <= {WIDTH{1'b0}};
            center_stage1 <= {WIDTH{1'b0}};
        end else begin
            data_in_stage1 <= data_in;
            center_stage1 <= center;
        end
    end
    
    // Pipeline stage 2: Calculate thresholds
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            data_in_stage2 <= {WIDTH{1'b0}};
            center_stage2 <= {WIDTH{1'b0}};
            upper_threshold_stage2 <= {WIDTH{1'b0}};
            lower_threshold_stage2 <= {WIDTH{1'b0}};
        end else begin
            data_in_stage2 <= data_in_stage1;
            center_stage2 <= center_stage1;
            upper_threshold_stage2 <= center_stage1 + HYST;
            lower_threshold_stage2 <= center_stage1 - HYST;
        end
    end
    
    // Pipeline stage 3: First comparison stage
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            compare_upper_stage3 <= 1'b0;
            compare_lower_stage3 <= 1'b0;
        end else begin
            compare_upper_stage3 <= (data_in_stage2 >= upper_threshold_stage2);
            compare_lower_stage3 <= (data_in_stage2 <= lower_threshold_stage2);
        end
    end
    
    // Pipeline stage 4: Second comparison stage
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            compare_upper_stage4 <= 1'b0;
            compare_lower_stage4 <= 1'b0;
        end else begin
            compare_upper_stage4 <= compare_upper_stage3;
            compare_lower_stage4 <= compare_lower_stage3;
        end
    end
    
    // Pipeline stage 5: Output stage
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            out_high <= 1'b0;
        end else begin
            if(compare_upper_stage4) out_high <= 1'b1;
            else if(compare_lower_stage4) out_high <= 1'b0;
        end
    end
endmodule