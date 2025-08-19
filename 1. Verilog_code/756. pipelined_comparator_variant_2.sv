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
    // Break comparison into more stages for better timing
    // Stage 1 registers
    reg [WIDTH/4-1:0] x_upper1_r, x_upper2_r, x_lower1_r, x_lower2_r;
    reg [WIDTH/4-1:0] y_upper1_r, y_upper2_r, y_lower1_r, y_lower2_r;
    
    // Stage 2 comparisons and registers
    reg upper1_eq_s2, upper2_eq_s2, lower1_eq_s2, lower2_eq_s2;
    reg upper1_gt_s2, upper2_gt_s2, lower1_gt_s2, lower2_gt_s2;
    
    // Stage 3 registers - combine quarter results to half results
    reg upper_eq_s3, lower_eq_s3;
    reg upper_gt_s3, lower_gt_s3;
    
    // Stage 4 registers
    reg upper_eq_s4, lower_eq_s4;
    reg upper_gt_s4, lower_gt_s4;
    
    // Pipeline Stage 1: Register inputs and divide into quarters
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            x_upper1_r <= {(WIDTH/4){1'b0}};
            x_upper2_r <= {(WIDTH/4){1'b0}};
            x_lower1_r <= {(WIDTH/4){1'b0}};
            x_lower2_r <= {(WIDTH/4){1'b0}};
            y_upper1_r <= {(WIDTH/4){1'b0}};
            y_upper2_r <= {(WIDTH/4){1'b0}};
            y_lower1_r <= {(WIDTH/4){1'b0}};
            y_lower2_r <= {(WIDTH/4){1'b0}};
        end else begin
            // Register input data in quarters
            x_upper1_r <= data_x[WIDTH-1:3*WIDTH/4];
            x_upper2_r <= data_x[3*WIDTH/4-1:WIDTH/2];
            x_lower1_r <= data_x[WIDTH/2-1:WIDTH/4];
            x_lower2_r <= data_x[WIDTH/4-1:0];
            
            y_upper1_r <= data_y[WIDTH-1:3*WIDTH/4];
            y_upper2_r <= data_y[3*WIDTH/4-1:WIDTH/2];
            y_lower1_r <= data_y[WIDTH/2-1:WIDTH/4];
            y_lower2_r <= data_y[WIDTH/4-1:0];
        end
    end
    
    // Pipeline Stage 2: Compare quarters
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            upper1_eq_s2 <= 1'b0;
            upper2_eq_s2 <= 1'b0;
            lower1_eq_s2 <= 1'b0;
            lower2_eq_s2 <= 1'b0;
            
            upper1_gt_s2 <= 1'b0;
            upper2_gt_s2 <= 1'b0;
            lower1_gt_s2 <= 1'b0;
            lower2_gt_s2 <= 1'b0;
        end else begin
            // Compare quarters
            upper1_eq_s2 <= (x_upper1_r == y_upper1_r);
            upper2_eq_s2 <= (x_upper2_r == y_upper2_r);
            lower1_eq_s2 <= (x_lower1_r == y_lower1_r);
            lower2_eq_s2 <= (x_lower2_r == y_lower2_r);
            
            upper1_gt_s2 <= (x_upper1_r > y_upper1_r);
            upper2_gt_s2 <= (x_upper2_r > y_upper2_r);
            lower1_gt_s2 <= (x_lower1_r > y_lower1_r);
            lower2_gt_s2 <= (x_lower2_r > y_lower2_r);
        end
    end
    
    // Pipeline Stage 3: Combine quarter results into half results
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            upper_eq_s3 <= 1'b0;
            lower_eq_s3 <= 1'b0;
            upper_gt_s3 <= 1'b0;
            lower_gt_s3 <= 1'b0;
        end else begin
            // Upper half equality requires both upper quarters to be equal
            upper_eq_s3 <= upper1_eq_s2 && upper2_eq_s2;
            // Lower half equality requires both lower quarters to be equal
            lower_eq_s3 <= lower1_eq_s2 && lower2_eq_s2;
            
            // Upper half is greater if:
            // - first quarter is greater, OR
            // - first quarters are equal AND second quarter is greater
            upper_gt_s3 <= upper1_gt_s2 || (upper1_eq_s2 && upper2_gt_s2);
            
            // Lower half is greater if:
            // - first quarter is greater, OR
            // - first quarters are equal AND second quarter is greater
            lower_gt_s3 <= lower1_gt_s2 || (lower1_eq_s2 && lower2_gt_s2);
        end
    end
    
    // Pipeline Stage 4: Register half results for final stage
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            upper_eq_s4 <= 1'b0;
            lower_eq_s4 <= 1'b0;
            upper_gt_s4 <= 1'b0;
            lower_gt_s4 <= 1'b0;
        end else begin
            upper_eq_s4 <= upper_eq_s3;
            lower_eq_s4 <= lower_eq_s3;
            upper_gt_s4 <= upper_gt_s3;
            lower_gt_s4 <= lower_gt_s3;
        end
    end
    
    // Pipeline Stage 5: Final comparison results
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            equal <= 1'b0;
            greater <= 1'b0;
            less <= 1'b0;
        end else begin
            // Numbers are equal only if both halves are equal
            equal <= upper_eq_s4 && lower_eq_s4;
            
            // X is greater than Y if:
            // - upper half of X is greater than upper half of Y, OR
            // - upper halves are equal AND lower half of X is greater than lower half of Y
            greater <= upper_gt_s4 || (upper_eq_s4 && lower_gt_s4);
            
            // X is less than Y if it's neither equal nor greater
            less <= !(upper_eq_s4 && lower_eq_s4) && !(upper_gt_s4 || (upper_eq_s4 && lower_gt_s4));
        end
    end
endmodule