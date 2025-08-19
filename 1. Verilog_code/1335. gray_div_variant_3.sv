//SystemVerilog
module gray_div #(parameter WIDTH=4) (
    input clk, rst,
    output reg clk_div
);
    // Gray counter register
    reg [WIDTH-1:0] gray_cnt;
    reg [WIDTH-1:0] gray_cnt_buf1, gray_cnt_buf2; // Buffer registers for high fan-out signal
    
    // Pipeline the gray counter for fan-out reduction
    always @(posedge clk) begin
        if (rst) begin
            gray_cnt_buf1 <= {WIDTH{1'b0}};
            gray_cnt_buf2 <= {WIDTH{1'b0}};
        end
        else begin
            gray_cnt_buf1 <= gray_cnt;
            gray_cnt_buf2 <= gray_cnt;
        end
    end
    
    // Binary conversion using XOR with shifted value
    // Using buffered version of gray_cnt to reduce fan-out
    wire [WIDTH-1:0] bin_cnt = gray_cnt_buf1 ^ (gray_cnt_buf1 >> 1);
    
    // Maximum binary count pattern used for clock division
    wire [WIDTH-1:0] max_bin_count = {WIDTH{1'b1}};
    
    // Gray counter update logic
    always @(posedge clk) begin
        if (rst)
            gray_cnt <= {WIDTH{1'b0}};
        else
            gray_cnt <= gray_cnt + 1'b1;
    end
    
    // Clock divider output logic
    // Using buffered version of gray_cnt_buf2 to balance load
    reg bin_max_match;
    
    always @(posedge clk) begin
        if (rst)
            bin_max_match <= 1'b0;
        else
            bin_max_match <= (bin_cnt == max_bin_count);
    end
    
    always @(posedge clk) begin
        if (rst)
            clk_div <= 1'b0;
        else
            clk_div <= bin_max_match;
    end
endmodule