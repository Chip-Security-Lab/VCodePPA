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
    // Clock buffering for high fan-out reduction
    wire clk_buf1, clk_buf2, clk_buf3;
    
    // Clock buffer tree
    assign clk_buf1 = clk;
    assign clk_buf2 = clk;
    assign clk_buf3 = clk;
    
    // Input data buffering for high fan-out reduction
    reg [WIDTH-1:0] data_x_buf1, data_x_buf2;
    reg [WIDTH-1:0] data_y_buf1, data_y_buf2;
    
    // Register data_x and data_y to create buffers
    always @(posedge clk_buf1 or posedge rst) begin
        if (rst) begin
            data_x_buf1 <= {WIDTH{1'b0}};
            data_y_buf1 <= {WIDTH{1'b0}};
        end else begin
            data_x_buf1 <= data_x;
            data_y_buf1 <= data_y;
        end
    end
    
    always @(posedge clk_buf1 or posedge rst) begin
        if (rst) begin
            data_x_buf2 <= {WIDTH{1'b0}};
            data_y_buf2 <= {WIDTH{1'b0}};
        end else begin
            data_x_buf2 <= data_x_buf1;
            data_y_buf2 <= data_y_buf1;
        end
    end

    // Break comparison into stages for better timing
    // Stage 1 registers and comparisons
    reg [WIDTH/2-1:0] x_upper_r, x_lower_r;
    reg [WIDTH/2-1:0] y_upper_r, y_lower_r;
    reg upper_eq_s1, lower_eq_s1;
    reg upper_gt_s1, lower_gt_s1;
    
    // Stage 2 registers
    reg upper_eq_s2, lower_eq_s2;
    reg upper_gt_s2, lower_gt_s2;
    
    // Buffered copies of upper_eq_s2 (high fan-out signal)
    reg upper_eq_s2_buf1, upper_eq_s2_buf2, upper_eq_s2_buf3;
    
    // Bus connections for b0 (implicitly created in stage 3)
    wire b0_equal, b0_greater;
    reg b0_buf1, b0_buf2;
    
    // Pipeline Stage 1: Register inputs and compare halves
    always @(posedge clk_buf2 or posedge rst) begin
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
            x_upper_r <= data_x_buf1[WIDTH-1:WIDTH/2];
            x_lower_r <= data_x_buf1[WIDTH/2-1:0];
            y_upper_r <= data_y_buf1[WIDTH-1:WIDTH/2];
            y_lower_r <= data_y_buf1[WIDTH/2-1:0];
            
            // Compare upper and lower halves
            upper_eq_s1 <= (data_x_buf2[WIDTH-1:WIDTH/2] == data_y_buf2[WIDTH-1:WIDTH/2]);
            lower_eq_s1 <= (data_x_buf2[WIDTH/2-1:0] == data_y_buf2[WIDTH/2-1:0]);
            upper_gt_s1 <= (data_x_buf2[WIDTH-1:WIDTH/2] > data_y_buf2[WIDTH-1:WIDTH/2]);
            lower_gt_s1 <= (data_x_buf2[WIDTH/2-1:0] > data_y_buf2[WIDTH/2-1:0]);
        end
    end
    
    // Pipeline Stage 2: Process comparison results
    always @(posedge clk_buf2 or posedge rst) begin
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
    
    // Buffer registers for high fan-out signals
    always @(posedge clk_buf3 or posedge rst) begin
        if (rst) begin
            upper_eq_s2_buf1 <= 1'b0;
            upper_eq_s2_buf2 <= 1'b0;
            upper_eq_s2_buf3 <= 1'b0;
            b0_buf1 <= 1'b0;
            b0_buf2 <= 1'b0;
        end else begin
            upper_eq_s2_buf1 <= upper_eq_s2;
            upper_eq_s2_buf2 <= upper_eq_s2;
            upper_eq_s2_buf3 <= upper_eq_s2;
            b0_buf1 <= upper_gt_s2;
            b0_buf2 <= upper_eq_s2 && lower_gt_s2;
        end
    end
    
    // Create buffered comparison signals
    assign b0_equal = upper_eq_s2_buf1 && lower_eq_s2;
    assign b0_greater = b0_buf1 || (upper_eq_s2_buf2 && lower_gt_s2);
    
    // Pipeline Stage 3: Final comparison results
    always @(posedge clk_buf3 or posedge rst) begin
        if (rst) begin
            equal <= 1'b0;
            greater <= 1'b0;
            less <= 1'b0;
        end else begin
            equal <= b0_equal;
            greater <= b0_greater;
            less <= !(upper_eq_s2_buf3 && lower_eq_s2) && !(b0_buf1 || (upper_eq_s2_buf3 && b0_buf2));
        end
    end
endmodule