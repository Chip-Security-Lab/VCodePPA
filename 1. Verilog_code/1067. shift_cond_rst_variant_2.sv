//SystemVerilog
module shift_cond_rst_pipeline #(parameter WIDTH=8) (
    input  wire                    clk,
    input  wire                    cond_rst,
    input  wire [WIDTH-1:0]        din,
    input  wire                    valid_in,
    input  wire                    flush,
    output reg  [WIDTH-1:0]        dout,
    output reg                     valid_out
);

// Stage 1: Capture inputs and control
reg [WIDTH-1:0] data_stage1;
reg             cond_rst_stage1;
reg             valid_stage1;

always @(posedge clk) begin
    if (flush) begin
        data_stage1      <= {WIDTH{1'b0}};
        cond_rst_stage1  <= 1'b0;
        valid_stage1     <= 1'b0;
    end else begin
        data_stage1      <= din;
        cond_rst_stage1  <= cond_rst;
        valid_stage1     <= valid_in;
    end
end

// Stage 2: Optimized shift or pass-through
reg [WIDTH-1:0] data_stage2;
reg             valid_stage2;

always @(posedge clk) begin
    if (flush) begin
        data_stage2  <= {WIDTH{1'b0}};
        valid_stage2 <= 1'b0;
    end else begin
        data_stage2  <= (cond_rst_stage1) ? data_stage1 : {dout[WIDTH-2:0], data_stage1[WIDTH-1]};
        valid_stage2 <= valid_stage1;
    end
end

// Stage 3: Output register
always @(posedge clk) begin
    if (flush) begin
        dout      <= {WIDTH{1'b0}};
        valid_out <= 1'b0;
    end else begin
        dout      <= data_stage2;
        valid_out <= valid_stage2;
    end
end

endmodule