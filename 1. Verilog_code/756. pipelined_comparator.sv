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
    // Break comparison into stages for better timing
    // Stage 1 registers and comparisons
    reg [WIDTH/2-1:0] x_upper_r, x_lower_r;
    reg [WIDTH/2-1:0] y_upper_r, y_lower_r;
    reg upper_eq_s1, lower_eq_s1;
    reg upper_gt_s1, lower_gt_s1;
    
    // Stage 2 registers
    reg upper_eq_s2, lower_eq_s2;
    reg upper_gt_s2, lower_gt_s2;
    
    // Pipeline Stage 1: Register inputs and compare halves
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            x_upper_r <= {(WIDTH/2){1'b0}};
            x_lower_r <= {(WIDTH/2){1'b0}};
            y_upper_r <= {(WIDTH/2){1'b0}};
            y_lower_r <= {(WIDTH/2){1'b0}};
            upper_eq_s1 <= 1'b0;
            lower_eq_s1 <= 1'b0;
            upper_gt_s1 <= 1'b0;
            lower_gt_s1 <= 1'b0;
        end else begin
            // Register input data
            x_upper_r <= data_x[WIDTH-1:WIDTH/2];
            x_lower_r <= data_x[WIDTH/2-1:0];
            y_upper_r <= data_y[WIDTH-1:WIDTH/2];
            y_lower_r <= data_y[WIDTH/2-1:0];
            
            // Compare upper and lower halves
            upper_eq_s1 <= (data_x[WIDTH-1:WIDTH/2] == data_y[WIDTH-1:WIDTH/2]);
            lower_eq_s1 <= (data_x[WIDTH/2-1:0] == data_y[WIDTH/2-1:0]);
            upper_gt_s1 <= (data_x[WIDTH-1:WIDTH/2] > data_y[WIDTH-1:WIDTH/2]);
            lower_gt_s1 <= (data_x[WIDTH/2-1:0] > data_y[WIDTH/2-1:0]);
        end
    end
    
    // Pipeline Stage 2: Process comparison results
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            upper_eq_s2 <= 1'b0;
            lower_eq_s2 <= 1'b0;
            upper_gt_s2 <= 1'b0;
            lower_gt_s2 <= 1'b0;
        end else begin
            upper_eq_s2 <= upper_eq_s1;
            lower_eq_s2 <= lower_eq_s1;
            upper_gt_s2 <= upper_gt_s1;
            lower_gt_s2 <= lower_gt_s1;
        end
    end
    
    // Pipeline Stage 3: Final comparison results
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            equal <= 1'b0;
            greater <= 1'b0;
            less <= 1'b0;
        end else begin
            equal <= upper_eq_s2 && lower_eq_s2;
            greater <= upper_gt_s2 || (upper_eq_s2 && lower_gt_s2);
            less <= !(upper_eq_s2 && lower_eq_s2) && !(upper_gt_s2 || (upper_eq_s2 && lower_gt_s2));
        end
    end
endmodule