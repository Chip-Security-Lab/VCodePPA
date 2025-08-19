//SystemVerilog
module shift_thermometer #(
    parameter WIDTH = 8
)(
    input                  clk,
    input                  rst_n,
    input                  dir,
    input                  valid_in,
    input  [WIDTH-1:0]     therm_in,
    output                 valid_out,
    output [WIDTH-1:0]     therm_out
);

// Stage 1: Capture inputs and direction
reg [WIDTH-1:0] therm_stage1;
reg             dir_stage1;
reg             valid_stage1;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        therm_stage1 <= {WIDTH{1'b0}};
        dir_stage1   <= 1'b0;
        valid_stage1 <= 1'b0;
    end else begin
        therm_stage1 <= therm_in;
        dir_stage1   <= dir;
        valid_stage1 <= valid_in;
    end
end

// Stage 2: Perform shift operation
reg [WIDTH-1:0] therm_shifted_stage2;
reg             valid_stage2;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        therm_shifted_stage2 <= {WIDTH{1'b0}};
        valid_stage2         <= 1'b0;
    end else begin
        if (dir_stage1) begin
            therm_shifted_stage2 <= (therm_stage1 >> 1) | (1'b1 << (WIDTH - 1));
        end else begin
            therm_shifted_stage2 <= (therm_stage1 << 1) | 1'b1;
        end
        valid_stage2 <= valid_stage1;
    end
end

assign therm_out  = therm_shifted_stage2;
assign valid_out  = valid_stage2;

endmodule