//SystemVerilog
module shift_preset_pipeline #(parameter W=8) (
    input               clk,
    input               rst_n,
    input               preset,
    input  [W-1:0]      preset_val,
    input               din_valid,
    output              dout_valid,
    output [W-1:0]      dout
);

// Stage 1: Latch preset and preset_val
reg                    preset_stage1;
reg [W-1:0]            preset_val_stage1;
reg [W-1:0]            dout_stage1;
reg                    valid_stage1;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        preset_stage1      <= 1'b0;
        preset_val_stage1  <= {W{1'b0}};
        dout_stage1        <= {W{1'b0}};
        valid_stage1       <= 1'b0;
    end else begin
        preset_stage1      <= preset;
        preset_val_stage1  <= preset_val;
        dout_stage1        <= dout;
        valid_stage1       <= din_valid;
    end
end

// Stage 2: Compute new value
reg [W-1:0]            dout_stage2;
reg                    valid_stage2;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        dout_stage2   <= {W{1'b0}};
        valid_stage2  <= 1'b0;
    end else begin
        if (valid_stage1) begin
            dout_stage2  <= preset_stage1 ? preset_val_stage1 : {dout_stage1[W-2:0], 1'b1};
            valid_stage2 <= 1'b1;
        end else begin
            dout_stage2  <= dout_stage2;
            valid_stage2 <= 1'b0;
        end
    end
end

// Output register (optional, for timing closure)
reg [W-1:0]            dout_stage3;
reg                    valid_stage3;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        dout_stage3   <= {W{1'b0}};
        valid_stage3  <= 1'b0;
    end else begin
        dout_stage3   <= dout_stage2;
        valid_stage3  <= valid_stage2;
    end
end

assign dout       = dout_stage3;
assign dout_valid = valid_stage3;

endmodule