//SystemVerilog
module binary_to_decimal_ascii #(parameter WIDTH=8)(
    input  wire                  clk,
    input  wire                  rst_n,
    input  wire [WIDTH-1:0]      binary_in,
    output reg  [8*3-1:0]        ascii_out // 最多3位十进制数的ASCII
);

// Pipeline Stage 1: Input Register
reg [WIDTH-1:0] binary_stage1;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        binary_stage1 <= {WIDTH{1'b0}};
    else
        binary_stage1 <= binary_in;
end

// Pipeline Stage 2: Compute Hundreds, Tens, Ones and Register Results
reg [3:0] hundreds_stage2;
reg [3:0] tens_stage2;
reg [3:0] ones_stage2;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        hundreds_stage2 <= 4'd0;
        tens_stage2     <= 4'd0;
        ones_stage2     <= 4'd0;
    end else begin
        hundreds_stage2 <= binary_stage1 / 100;
        tens_stage2     <= (binary_stage1 / 10) % 10;
        ones_stage2     <= binary_stage1 % 10;
    end
end

// Pipeline Stage 3: Register ASCII Encoding Inputs
reg [3:0] hundreds_stage3;
reg [3:0] tens_stage3;
reg [3:0] ones_stage3;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        hundreds_stage3 <= 4'd0;
        tens_stage3     <= 4'd0;
        ones_stage3     <= 4'd0;
    end else begin
        hundreds_stage3 <= hundreds_stage2;
        tens_stage3     <= tens_stage2;
        ones_stage3     <= ones_stage2;
    end
end

// Pipeline Stage 4: ASCII Encoding (move registers before output, remove output reg stage)
reg [7:0] ascii_hundreds_stage4;
reg [7:0] ascii_tens_stage4;
reg [7:0] ascii_ones_stage4;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        ascii_hundreds_stage4 <= 8'h20;
        ascii_tens_stage4     <= 8'h20;
        ascii_ones_stage4     <= 8'h30;
    end else begin
        ascii_hundreds_stage4 <= (hundreds_stage3 != 4'd0) ? (8'h30 + hundreds_stage3) : 8'h20;
        ascii_tens_stage4     <= ((hundreds_stage3 != 4'd0) || (tens_stage3 != 4'd0)) ? (8'h30 + tens_stage3) : 8'h20;
        ascii_ones_stage4     <= 8'h30 + ones_stage3;
    end
end

// Output assignment, fully combinational (output reg is updated immediately from last stage registers)
always @(*) begin
    if (!rst_n)
        ascii_out = 24'h202030;
    else
        ascii_out = {ascii_hundreds_stage4, ascii_tens_stage4, ascii_ones_stage4};
end

endmodule