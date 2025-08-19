//SystemVerilog
module UniversalShifter #(parameter WIDTH=8) (
    input  wire                clk,
    input  wire                rst_n,
    input  wire                start,
    input  wire [1:0]          mode,          // 00:hold 01:left 10:right 11:load
    input  wire                serial_in,
    input  wire [WIDTH-1:0]    parallel_in,
    output reg  [WIDTH-1:0]    data_out,
    output reg                 valid_out
);

// Stage 1: Decode and prepare inputs (removed input-side registers, move after combinational logic)
wire [1:0]             mode_stage1_w;
wire                   serial_in_stage1_w;
wire [WIDTH-1:0]       parallel_in_stage1_w;
wire [WIDTH-1:0]       data_reg_stage1_w;
wire                   valid_stage1_w;

// Internal register to hold state across cycles
reg [WIDTH-1:0]        data_reg_internal;

// Combinational logic for Stage 1 (input preparation)
assign mode_stage1_w        = mode;
assign serial_in_stage1_w   = serial_in;
assign parallel_in_stage1_w = parallel_in;
assign data_reg_stage1_w    = data_reg_internal;
assign valid_stage1_w       = start ? 1'b1 : 1'b0;

// Stage 2: Register after combinational logic (moved registers forward)
reg [1:0]             mode_stage2;
reg                   serial_in_stage2;
reg [WIDTH-1:0]       parallel_in_stage2;
reg [WIDTH-1:0]       data_reg_stage2;
reg                   valid_stage2;

// Stage 3: Compute shift/load operation (combinational logic)
wire [WIDTH-1:0]      shift_result_stage3_w;
wire                  valid_stage3_w;

// Stage 4: Register the result and update internal state
reg [WIDTH-1:0]       data_reg_stage4;
reg                   valid_stage4;

// Pipeline Stage 2: Latch inputs and previous data after combinational logic
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        mode_stage2         <= 2'b00;
        serial_in_stage2    <= 1'b0;
        parallel_in_stage2  <= {WIDTH{1'b0}};
        data_reg_stage2     <= {WIDTH{1'b0}};
        valid_stage2        <= 1'b0;
    end else begin
        mode_stage2         <= mode_stage1_w;
        serial_in_stage2    <= serial_in_stage1_w;
        parallel_in_stage2  <= parallel_in_stage1_w;
        data_reg_stage2     <= data_reg_stage1_w;
        valid_stage2        <= valid_stage1_w;
    end
end

// Pipeline Stage 3: Perform shift/load operation (combinational)
assign shift_result_stage3_w =
    (mode_stage2 == 2'b01) ? {data_reg_stage2[WIDTH-2:0], serial_in_stage2} :
    (mode_stage2 == 2'b10) ? {serial_in_stage2, data_reg_stage2[WIDTH-1:1]} :
    (mode_stage2 == 2'b11) ? parallel_in_stage2 :
                             data_reg_stage2;

assign valid_stage3_w = valid_stage2;

// Pipeline Stage 4: Register the result and update internal state
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        data_reg_stage4      <= {WIDTH{1'b0}};
        valid_stage4         <= 1'b0;
        data_reg_internal    <= {WIDTH{1'b0}};
    end else begin
        data_reg_stage4   <= shift_result_stage3_w;
        valid_stage4      <= valid_stage3_w;
        if (valid_stage3_w)
            data_reg_internal <= shift_result_stage3_w;
    end
end

// Output assignments
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        data_out   <= {WIDTH{1'b0}};
        valid_out  <= 1'b0;
    end else begin
        data_out   <= data_reg_stage4;
        valid_out  <= valid_stage4;
    end
end

endmodule