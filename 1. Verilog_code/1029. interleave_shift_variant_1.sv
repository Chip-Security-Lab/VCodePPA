//SystemVerilog
module interleave_shift_pipeline #(parameter W=8) (
    input                  clk,
    input                  rst_n,
    input                  din_valid,
    input      [W-1:0]     din,
    output reg             dout_valid,
    output reg [W-1:0]     dout
);

// Stage 1: Input register
reg  [W-1:0] din_stage1;
reg          valid_stage1;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        din_stage1   <= {W{1'b0}};
        valid_stage1 <= 1'b0;
    end else begin
        din_stage1   <= din;
        valid_stage1 <= din_valid;
    end
end

// Stage 2: Extract even and odd bits
reg [3:0] even_bits_stage2;
reg [3:0] odd_bits_stage2;
reg       valid_stage2;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        even_bits_stage2 <= 4'b0;
        odd_bits_stage2  <= 4'b0;
        valid_stage2     <= 1'b0;
    end else begin
        even_bits_stage2 <= {din_stage1[6], din_stage1[4], din_stage1[2], din_stage1[0]};
        odd_bits_stage2  <= {din_stage1[7], din_stage1[5], din_stage1[3], din_stage1[1]};
        valid_stage2     <= valid_stage1;
    end
end

// Stage 3: Output register
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        dout       <= {W{1'b0}};
        dout_valid <= 1'b0;
    end else begin
        dout       <= {even_bits_stage2, odd_bits_stage2};
        dout_valid <= valid_stage2;
    end
end

endmodule