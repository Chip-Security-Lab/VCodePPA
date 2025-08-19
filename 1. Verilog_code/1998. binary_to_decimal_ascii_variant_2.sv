//SystemVerilog
module binary_to_decimal_ascii #(parameter WIDTH=8)(
    input  wire                  clk,
    input  wire                  rst_n,
    input  wire [WIDTH-1:0]      binary_in,
    output reg  [8*3-1:0]        ascii_out // 3 ASCII chars: hundreds, tens, ones
);

// Stage 1: Extract hundreds (moved reg after combinational logic)
wire [3:0]    hundreds_comb;
wire [WIDTH-1:0] rem_after_hundreds_comb;

assign hundreds_comb = binary_in / 100;
assign rem_after_hundreds_comb = binary_in % 100;

reg [3:0]    hundreds_stage2;
reg [WIDTH-1:0] rem_after_hundreds_stage2;

// Stage 2: Extract tens (moved reg after combinational logic)
wire [3:0]    tens_comb;
wire [WIDTH-1:0] rem_after_tens_comb;

assign tens_comb = rem_after_hundreds_stage2 / 10;
assign rem_after_tens_comb = rem_after_hundreds_stage2 % 10;

reg [3:0]    hundreds_stage3;
reg [3:0]    tens_stage3;
reg [3:0]    ones_stage3;

// Stage 1: Register hundreds and rem_after_hundreds
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        hundreds_stage2          <= 4'd0;
        rem_after_hundreds_stage2<= {WIDTH{1'b0}};
    end else begin
        hundreds_stage2          <= hundreds_comb;
        rem_after_hundreds_stage2<= rem_after_hundreds_comb;
    end
end

// Stage 2: Register tens and rem_after_tens
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        hundreds_stage3          <= 4'd0;
        tens_stage3              <= 4'd0;
        ones_stage3              <= 4'd0;
    end else begin
        hundreds_stage3          <= hundreds_stage2;
        tens_stage3              <= tens_comb;
        ones_stage3              <= rem_after_tens_comb[3:0];
    end
end

// Stage 3: Output ASCII
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        ascii_out <= 24'h202020;
    end else begin
        // ascii_out[23:16] - hundreds, ascii_out[15:8] - tens, ascii_out[7:0] - ones
        ascii_out[23:16] <= (hundreds_stage3 != 0) ? (8'h30 + hundreds_stage3) : 8'h20;
        ascii_out[15:8]  <= ((hundreds_stage3 != 0) || (tens_stage3 != 0)) ? (8'h30 + tens_stage3) : 8'h20;
        ascii_out[7:0]   <= 8'h30 + ones_stage3;
    end
end

endmodule