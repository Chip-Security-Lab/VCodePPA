//SystemVerilog
module RangeDetector_AXIStream #(
    parameter WIDTH = 8
)(
    input clk, rst_n,
    input tvalid,
    input [WIDTH-1:0] tdata,
    input [WIDTH-1:0] lower,
    input [WIDTH-1:0] upper,
    output reg tvalid_out,
    output reg [WIDTH-1:0] tdata_out
);

    // Stage 1 - Calculate differences with lower and upper bounds
    reg [WIDTH:0] diff_lower_stage1;
    reg [WIDTH:0] diff_upper_stage1;
    reg [WIDTH-1:0] tdata_stage1;
    reg tvalid_stage1;
    reg [WIDTH-1:0] lower_stage1;
    reg [WIDTH-1:0] upper_stage1;
    
    // Stage 2 - Determine if in range and prepare output
    reg in_range_stage2;
    reg [WIDTH-1:0] tdata_stage2;
    reg tvalid_stage2;
    
    // Stage 1: Calculate differences with pipeline registers
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            diff_lower_stage1 <= 0;
            diff_upper_stage1 <= 0;
            tdata_stage1 <= 0;
            tvalid_stage1 <= 0;
            lower_stage1 <= 0;
            upper_stage1 <= 0;
        end
        else begin
            diff_lower_stage1 <= {1'b0, tdata} - {1'b0, lower};
            diff_upper_stage1 <= {1'b0, upper} - {1'b0, tdata};
            tdata_stage1 <= tdata;
            tvalid_stage1 <= tvalid;
            lower_stage1 <= lower;
            upper_stage1 <= upper;
        end
    end
    
    // Stage 2: Determine range check and prepare output
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            in_range_stage2 <= 0;
            tdata_stage2 <= 0;
            tvalid_stage2 <= 0;
        end
        else begin
            // Check if value is in range using MSB of differences
            // If tdata >= lower, diff_lower MSB will be 0
            // If tdata <= upper, diff_upper MSB will be 0
            in_range_stage2 <= ~diff_lower_stage1[WIDTH] & ~diff_upper_stage1[WIDTH];
            tdata_stage2 <= tdata_stage1;
            tvalid_stage2 <= tvalid_stage1;
        end
    end
    
    // Final stage: Apply range filter to data
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            tvalid_out <= 0;
            tdata_out <= 0;
        end
        else begin
            tvalid_out <= tvalid_stage2;
            tdata_out <= in_range_stage2 ? tdata_stage2 : 0;
        end
    end
endmodule