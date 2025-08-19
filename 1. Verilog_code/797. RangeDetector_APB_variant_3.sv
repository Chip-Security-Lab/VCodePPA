//SystemVerilog
module RangeDetector_APB #(
    parameter WIDTH = 8,
    parameter ADDR_WIDTH = 4
)(
    input clk, rst_n,
    input psel, penable, pwrite,
    input [ADDR_WIDTH-1:0] paddr,
    input [WIDTH-1:0] pwdata,
    input [WIDTH-1:0] data_in,
    output reg [WIDTH-1:0] prdata,
    output reg out_range
);
    // Threshold registers
    reg [WIDTH-1:0] thresholds[0:1]; // 0:lower 1:upper
    
    // Pipeline stage 1 registers
    reg [WIDTH-1:0] data_in_stage1;
    reg [WIDTH-1:0] lower_threshold_stage1;
    reg [WIDTH-1:0] upper_threshold_stage1;
    reg valid_stage1;
    
    // Pipeline stage 2 registers
    reg below_lower_stage2;
    reg above_upper_stage2;
    reg valid_stage2;
    
    // APB interface handling
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            thresholds[0] <= 0;
            thresholds[1] <= {WIDTH{1'b1}};
        end
        else if(psel && penable && pwrite) begin
            thresholds[paddr] <= pwdata;
        end
    end
    
    // Pipeline stage 1: Register inputs and prepare comparisons
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            data_in_stage1 <= 0;
            lower_threshold_stage1 <= 0;
            upper_threshold_stage1 <= 0;
            valid_stage1 <= 0;
        end
        else begin
            data_in_stage1 <= data_in;
            lower_threshold_stage1 <= thresholds[0];
            upper_threshold_stage1 <= thresholds[1];
            valid_stage1 <= 1'b1; // Input always valid, can be modified for specific protocol
        end
    end
    
    // Pipeline stage 2: Perform comparisons
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            below_lower_stage2 <= 0;
            above_upper_stage2 <= 0;
            valid_stage2 <= 0;
        end
        else begin
            below_lower_stage2 <= (data_in_stage1 < lower_threshold_stage1);
            above_upper_stage2 <= (data_in_stage1 > upper_threshold_stage1);
            valid_stage2 <= valid_stage1;
        end
    end
    
    // Pipeline stage 3: Generate final output
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            out_range <= 0;
        end
        else if(valid_stage2) begin
            out_range <= below_lower_stage2 || above_upper_stage2;
        end
    end
    
    // Read data path - also pipelined
    reg [ADDR_WIDTH-1:0] paddr_r;
    
    always @(posedge clk) begin
        paddr_r <= paddr;
        prdata <= thresholds[paddr_r];
    end
endmodule