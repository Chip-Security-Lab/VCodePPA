//SystemVerilog
module RangeDetector_FaultTolerant #(
    parameter WIDTH = 8,
    parameter TOLERANCE = 3
)(
    input clk, rst_n,
    input [WIDTH-1:0] data_in,
    input [WIDTH-1:0] low_th,
    input [WIDTH-1:0] high_th,
    output reg alarm
);

// Pipeline stage 1 registers
reg [WIDTH-1:0] data_in_stage1, low_th_stage1, high_th_stage1;
reg comp_low_stage1, comp_high_stage1;
reg valid_stage1;

// Pipeline stage 2 registers
reg [WIDTH-1:0] data_in_stage2;
reg comp_low_stage2, comp_high_stage2;
reg out_of_range_stage2;
reg [1:0] err_count_stage2;
reg valid_stage2;

// Pipeline stage 3 registers
reg [1:0] err_count_stage3;
reg valid_stage3;

// Stage 1: Input registration and comparison
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        data_in_stage1 <= 0;
        low_th_stage1 <= 0;
        high_th_stage1 <= 0;
        comp_low_stage1 <= 0;
        comp_high_stage1 <= 0;
        valid_stage1 <= 0;
    end
    else begin
        data_in_stage1 <= data_in;
        low_th_stage1 <= low_th;
        high_th_stage1 <= high_th;
        comp_low_stage1 <= data_in < low_th;
        comp_high_stage1 <= data_in > high_th;
        valid_stage1 <= 1'b1;
    end
end

// Stage 2: Range detection and error counting
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        data_in_stage2 <= 0;
        comp_low_stage2 <= 0;
        comp_high_stage2 <= 0;
        out_of_range_stage2 <= 0;
        err_count_stage2 <= 0;
        valid_stage2 <= 0;
    end
    else if(valid_stage1) begin
        data_in_stage2 <= data_in_stage1;
        comp_low_stage2 <= comp_low_stage1;
        comp_high_stage2 <= comp_high_stage1;
        out_of_range_stage2 <= comp_low_stage1 || comp_high_stage1;
        
        if(out_of_range_stage2) begin
            err_count_stage2 <= (err_count_stage2 < TOLERANCE) ? err_count_stage2 + 1'b1 : TOLERANCE;
        end
        else begin
            err_count_stage2 <= (err_count_stage2 > 0) ? err_count_stage2 - 1'b1 : 0;
        end
        valid_stage2 <= valid_stage1;
    end
end

// Stage 3: Alarm generation
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        err_count_stage3 <= 0;
        alarm <= 0;
        valid_stage3 <= 0;
    end
    else if(valid_stage2) begin
        err_count_stage3 <= err_count_stage2;
        alarm <= (err_count_stage2 == TOLERANCE);
        valid_stage3 <= valid_stage2;
    end
end

endmodule