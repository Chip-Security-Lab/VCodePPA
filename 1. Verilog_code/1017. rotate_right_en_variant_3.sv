//SystemVerilog
module rotate_right_en_pipeline #(parameter W=8) (
    input                  clk,
    input                  en,
    input                  rst_n,
    input      [W-1:0]     din,
    output reg [W-1:0]     dout,
    output reg             dout_valid
);

// Stage 1: Input register and valid signal
reg [W-1:0] din_stage1;
reg         en_stage1;
reg         valid_stage1;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        din_stage1   <= {W{1'b0}};
        en_stage1    <= 1'b0;
        valid_stage1 <= 1'b0;
    end else begin
        din_stage1   <= din;
        en_stage1    <= en;
        valid_stage1 <= en;
    end
end

// Stage 2: Rotate operation and valid signal
reg [W-1:0] rot_stage2;
reg         valid_stage2;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        rot_stage2   <= {W{1'b0}};
        valid_stage2 <= 1'b0;
    end else begin
        if (en_stage1) begin
            rot_stage2 <= {din_stage1[0], din_stage1[W-1:1]};
        end else begin
            rot_stage2 <= rot_stage2;
        end
        valid_stage2 <= valid_stage1;
    end
end

// Stage 3: Output register and valid signal
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        dout       <= {W{1'b0}};
        dout_valid <= 1'b0;
    end else begin
        if (valid_stage2) begin
            dout       <= rot_stage2;
            dout_valid <= 1'b1;
        end else begin
            dout_valid <= 1'b0;
        end
    end
end

endmodule