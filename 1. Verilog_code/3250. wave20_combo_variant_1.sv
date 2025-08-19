//SystemVerilog
module wave20_combo(
    input  wire         clk,
    input  wire         rst_n,
    input  wire [1:0]   sel,
    input  wire [7:0]   in_sin,
    input  wire [7:0]   in_tri,
    input  wire [7:0]   in_saw,
    output wire [7:0]   wave_out
);

// Stage 1: Input latching
reg [1:0]   sel_stage1;
reg [7:0]   sin_stage1;
reg [7:0]   tri_stage1;
reg [7:0]   saw_stage1;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        sel_stage1   <= 2'b00;
        sin_stage1   <= 8'd0;
        tri_stage1   <= 8'd0;
        saw_stage1   <= 8'd0;
    end else begin
        sel_stage1   <= sel;
        sin_stage1   <= in_sin;
        tri_stage1   <= in_tri;
        saw_stage1   <= in_saw;
    end
end

// Stage 2: Multiplexer logic
reg [7:0] wave_mux_stage2;

always @(*) begin
    case (sel_stage1)
        2'b00: wave_mux_stage2 = sin_stage1;
        2'b01: wave_mux_stage2 = tri_stage1;
        2'b10: wave_mux_stage2 = saw_stage1;
        default: wave_mux_stage2 = 8'd0;
    endcase
end

// Stage 3: Output register for pipeline clarity and timing
reg [7:0] wave_out_stage3;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        wave_out_stage3 <= 8'd0;
    end else begin
        wave_out_stage3 <= wave_mux_stage2;
    end
end

assign wave_out = wave_out_stage3;

endmodule