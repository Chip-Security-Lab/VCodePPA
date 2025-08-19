//SystemVerilog
module SoftClipper #(
    parameter W = 8,              // Bit width of input/output
    parameter THRESH = 8'hF0      // Threshold value for clipping
) (
    input wire clk,               // Clock signal (added)
    input wire rst_n,             // Reset signal (added)
    input wire [W-1:0] din,       // Input data
    output reg [W-1:0] dout       // Output data (changed to reg)
);
    // Internal signals for pipelined implementation
    reg [W-1:0] din_reg;
    reg din_gt_thresh, din_lt_neg_thresh;
    reg [W-1:0] pos_offset, neg_offset;
    reg [W-1:0] thresh_reg, neg_thresh_reg;
    
    // Stage 1: Register inputs and compute comparisons
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            din_reg <= {W{1'b0}};
            thresh_reg <= THRESH;
            neg_thresh_reg <= -{THRESH};
            din_gt_thresh <= 1'b0;
            din_lt_neg_thresh <= 1'b0;
        end else begin
            din_reg <= din;
            thresh_reg <= THRESH;
            neg_thresh_reg <= -{THRESH};
            din_gt_thresh <= din > THRESH;
            din_lt_neg_thresh <= din < -{THRESH};
        end
    end
    
    // Stage 2: Calculate offsets
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pos_offset <= {W{1'b0}};
            neg_offset <= {W{1'b0}};
        end else begin
            pos_offset <= (din_reg - thresh_reg) >> 1;
            neg_offset <= (neg_thresh_reg - din_reg) >> 1;
        end
    end
    
    // Stage 3: Final output selection
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            dout <= {W{1'b0}};
        end else begin
            if (din_gt_thresh)
                dout <= thresh_reg + pos_offset;
            else if (din_lt_neg_thresh)
                dout <= neg_thresh_reg - neg_offset;
            else
                dout <= din_reg;
        end
    end
endmodule