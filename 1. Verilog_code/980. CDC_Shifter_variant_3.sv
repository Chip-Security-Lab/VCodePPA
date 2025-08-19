//SystemVerilog
module CDC_Shifter_Pipelined #(parameter WIDTH=8) (
    input  wire                  src_clk,
    input  wire                  src_rst_n,
    input  wire                  dst_clk,
    input  wire                  dst_rst_n,
    input  wire [WIDTH-1:0]      data_in,
    input  wire                  valid_in,
    output wire [WIDTH-1:0]      data_out,
    output wire                  valid_out
);

//----------------------
// Source Clock Domain
//----------------------
reg [WIDTH-1:0] data_src_stage1;
reg             valid_src_stage1;
always @(posedge src_clk or negedge src_rst_n) begin
    if (!src_rst_n) begin
        data_src_stage1  <= {WIDTH{1'b0}};
        valid_src_stage1 <= 1'b0;
    end else begin
        data_src_stage1  <= data_in;
        valid_src_stage1 <= valid_in;
    end
end

reg [WIDTH-1:0] data_src_stage2;
reg             valid_src_stage2;
always @(posedge src_clk or negedge src_rst_n) begin
    if (!src_rst_n) begin
        data_src_stage2  <= {WIDTH{1'b0}};
        valid_src_stage2 <= 1'b0;
    end else begin
        data_src_stage2  <= data_src_stage1;
        valid_src_stage2 <= valid_src_stage1;
    end
end

//----------------------
// CDC: Metastability Filtering (src->dst)
//----------------------
reg [WIDTH-1:0] data_cdc_stage1;
reg             valid_cdc_stage1;
always @(posedge dst_clk or negedge dst_rst_n) begin
    if (!dst_rst_n) begin
        data_cdc_stage1  <= {WIDTH{1'b0}};
        valid_cdc_stage1 <= 1'b0;
    end else begin
        data_cdc_stage1  <= data_src_stage2;
        valid_cdc_stage1 <= valid_src_stage2;
    end
end

reg [WIDTH-1:0] data_cdc_stage2;
reg             valid_cdc_stage2;
always @(posedge dst_clk or negedge dst_rst_n) begin
    if (!dst_rst_n) begin
        data_cdc_stage2  <= {WIDTH{1'b0}};
        valid_cdc_stage2 <= 1'b0;
    end else begin
        data_cdc_stage2  <= data_cdc_stage1;
        valid_cdc_stage2 <= valid_cdc_stage1;
    end
end

//----------------------
// Destination Domain Pipeline
//----------------------
reg [WIDTH-1:0] data_dst_stage1;
reg             valid_dst_stage1;
always @(posedge dst_clk or negedge dst_rst_n) begin
    if (!dst_rst_n) begin
        data_dst_stage1  <= {WIDTH{1'b0}};
        valid_dst_stage1 <= 1'b0;
    end else begin
        data_dst_stage1  <= data_cdc_stage2;
        valid_dst_stage1 <= valid_cdc_stage2;
    end
end

reg [WIDTH-1:0] data_dst_stage2;
reg             valid_dst_stage2;
always @(posedge dst_clk or negedge dst_rst_n) begin
    if (!dst_rst_n) begin
        data_dst_stage2  <= {WIDTH{1'b0}};
        valid_dst_stage2 <= 1'b0;
    end else begin
        data_dst_stage2  <= data_dst_stage1;
        valid_dst_stage2 <= valid_dst_stage1;
    end
end

assign data_out  = data_dst_stage2;
assign valid_out = valid_dst_stage2;

endmodule