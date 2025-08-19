//SystemVerilog
module MuxAsync #(parameter DW=8, AW=3) (
    input                      clk,
    input                      rst_n,
    input      [AW-1:0]        channel,
    input      [2**AW-1:0][DW-1:0] din,
    output reg [DW-1:0]        dout
);

// Stage 1: Pipeline register for channel and din
reg [AW-1:0] channel_stage1;
reg [2**AW-1:0][DW-1:0] din_stage1;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        channel_stage1 <= {AW{1'b0}};
        din_stage1 <= {((2**AW)*DW){1'b0}};
    end else begin
        channel_stage1 <= channel;
        din_stage1 <= din;
    end
end

// Stage 2: Register for selected data index (split mux into two stages)
reg [DW-1:0] mux_pre_stage2;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        mux_pre_stage2 <= {DW{1'b0}};
    else
        mux_pre_stage2 <= din_stage1[channel_stage1];
end

// Stage 3: Output register (additional pipeline stage for timing improvement)
reg [DW-1:0] mux_out_stage3;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        mux_out_stage3 <= {DW{1'b0}};
    else
        mux_out_stage3 <= mux_pre_stage2;
end

// Final output register
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        dout <= {DW{1'b0}};
    else
        dout <= mux_out_stage3;
end

endmodule