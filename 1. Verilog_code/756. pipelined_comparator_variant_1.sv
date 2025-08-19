//SystemVerilog
module pipelined_comparator #(
    parameter WIDTH = 64
)(
    input wire clk,
    input wire rst,
    input wire [WIDTH-1:0] data_x,
    input wire [WIDTH-1:0] data_y,
    output reg equal,
    output reg greater,
    output reg less
);

    // Stage 1 registers
    reg [WIDTH/4-1:0] x_upper_r, x_upper_mid_r, x_lower_mid_r, x_lower_r;
    reg [WIDTH/4-1:0] y_upper_r, y_upper_mid_r, y_lower_mid_r, y_lower_r;
    
    // Intermediate comparison results
    reg upper_eq_s1, upper_mid_eq_s1, lower_mid_eq_s1, lower_eq_s1;
    reg upper_gt_s1, upper_mid_gt_s1, lower_mid_gt_s1, lower_gt_s1;
    
    // Stage 2 intermediate results
    reg upper_eq_s2, upper_mid_eq_s2;
    reg upper_gt_s2, upper_mid_gt_s2;
    
    // Stage 3 intermediate results
    reg upper_eq_s3, lower_eq_s3;
    reg upper_gt_s3, lower_gt_s3;
    
    // Stage 1: Input registration and quarter comparisons
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            {x_upper_r, x_upper_mid_r, x_lower_mid_r, x_lower_r} <= 0;
            {y_upper_r, y_upper_mid_r, y_lower_mid_r, y_lower_r} <= 0;
            {upper_eq_s1, upper_mid_eq_s1, lower_mid_eq_s1, lower_eq_s1} <= 0;
            {upper_gt_s1, upper_mid_gt_s1, lower_mid_gt_s1, lower_gt_s1} <= 0;
        end else begin
            // Register inputs
            x_upper_r <= data_x[WIDTH-1:3*WIDTH/4];
            x_upper_mid_r <= data_x[3*WIDTH/4-1:WIDTH/2];
            x_lower_mid_r <= data_x[WIDTH/2-1:WIDTH/4];
            x_lower_r <= data_x[WIDTH/4-1:0];
            
            y_upper_r <= data_y[WIDTH-1:3*WIDTH/4];
            y_upper_mid_r <= data_y[3*WIDTH/4-1:WIDTH/2];
            y_lower_mid_r <= data_y[WIDTH/2-1:WIDTH/4];
            y_lower_r <= data_y[WIDTH/4-1:0];
            
            // Quarter comparisons
            upper_eq_s1 <= (x_upper_r == y_upper_r);
            upper_mid_eq_s1 <= (x_upper_mid_r == y_upper_mid_r);
            lower_mid_eq_s1 <= (x_lower_mid_r == y_lower_mid_r);
            lower_eq_s1 <= (x_lower_r == y_lower_r);
            
            upper_gt_s1 <= (x_upper_r > y_upper_r);
            upper_mid_gt_s1 <= (x_upper_mid_r > y_upper_mid_r);
            lower_mid_gt_s1 <= (x_lower_mid_r > y_lower_mid_r);
            lower_gt_s1 <= (x_lower_r > y_lower_r);
        end
    end
    
    // Stage 2: Combine quarter comparisons
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            {upper_eq_s2, upper_mid_eq_s2} <= 0;
            {upper_gt_s2, upper_mid_gt_s2} <= 0;
        end else begin
            // Upper half comparison
            upper_eq_s2 <= upper_eq_s1 && upper_mid_eq_s1;
            upper_gt_s2 <= upper_gt_s1 || (upper_eq_s1 && upper_mid_gt_s1);
            
            // Lower half comparison
            upper_mid_eq_s2 <= lower_mid_eq_s1 && lower_eq_s1;
            upper_mid_gt_s2 <= lower_mid_gt_s1 || (lower_mid_eq_s1 && lower_gt_s1);
        end
    end
    
    // Stage 3: Combine half comparisons
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            {upper_eq_s3, lower_eq_s3} <= 0;
            {upper_gt_s3, lower_gt_s3} <= 0;
        end else begin
            upper_eq_s3 <= upper_eq_s2;
            lower_eq_s3 <= upper_mid_eq_s2;
            upper_gt_s3 <= upper_gt_s2;
            lower_gt_s3 <= upper_mid_gt_s2;
        end
    end
    
    // Stage 4: Final comparison results
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            {equal, greater, less} <= 0;
        end else begin
            equal <= upper_eq_s3 && lower_eq_s3;
            greater <= upper_gt_s3 || (upper_eq_s3 && lower_gt_s3);
            less <= !equal && !greater;
        end
    end
endmodule