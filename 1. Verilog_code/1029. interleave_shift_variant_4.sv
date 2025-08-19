//SystemVerilog
module interleave_shift_pipeline #(parameter W=8) (
    input                  clk,
    input                  rst_n,
    input                  din_valid,
    input  [W-1:0]         din,
    output reg             dout_valid,
    output reg [W-1:0]     dout
);

// Stage 1: Input buffer
reg [W-1:0] din_stage1;
reg        valid_stage1;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        din_stage1   <= {W{1'b0}};
        valid_stage1 <= 1'b0;
    end else begin
        din_stage1   <= din;
        valid_stage1 <= din_valid;
    end
end

// Stage 2: Second buffer
reg [W-1:0] din_stage2;
reg        valid_stage2;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        din_stage2   <= {W{1'b0}};
        valid_stage2 <= 1'b0;
    end else begin
        din_stage2   <= din_stage1;
        valid_stage2 <= valid_stage1;
    end
end

// Stage 3: Interleave and shift
reg [W-1:0] dout_stage3;
reg        valid_stage3;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        dout_stage3  <= {W{1'b0}};
        valid_stage3 <= 1'b0;
    end else begin
        dout_stage3  <= {din_stage2[6], din_stage2[4], din_stage2[2], din_stage2[0],
                         din_stage2[7], din_stage2[5], din_stage2[3], din_stage2[1]};
        valid_stage3 <= valid_stage2;
    end
end

// Output stage
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        dout       <= {W{1'b0}};
        dout_valid <= 1'b0;
    end else begin
        dout       <= dout_stage3;
        dout_valid <= valid_stage3;
    end
end

endmodule