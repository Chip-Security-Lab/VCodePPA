//SystemVerilog
module PipeMux #(
    parameter DW = 8,
    parameter STAGES = 2
)(
    input  wire               clk,
    input  wire               rst,
    input  wire [3:0]         sel,
    input  wire [(16*DW)-1:0] din,
    output wire [DW-1:0]      dout
);

wire [DW-1:0] mux_data_comb;

// Combinational logic for input mux
PipeMuxComb #(
    .DW(DW)
) u_pipe_mux_comb (
    .sel(sel),
    .din(din),
    .mux_out(mux_data_comb)
);

// Synchronous pipeline registers
reg [DW-1:0] stage_data_0;
reg [DW-1:0] stage_data_1;

always @(posedge clk or posedge rst) begin
    if (rst) begin
        stage_data_0 <= {DW{1'b0}};
        stage_data_1 <= {DW{1'b0}};
    end else begin
        stage_data_0 <= mux_data_comb;
        stage_data_1 <= stage_data_0;
    end
end

// Output logic
assign dout = (STAGES <= 1) ? stage_data_0 : stage_data_1;

endmodule

// Combinational MUX module
module PipeMuxComb #(
    parameter DW = 8
)(
    input  wire [3:0]         sel,
    input  wire [(16*DW)-1:0] din,
    output wire [DW-1:0]      mux_out
);

generate
    if (DW == 8) begin : gen_mux8
        reg [DW-1:0] mux_data_r;
        always @(*) begin
            case (sel)
                4'd0:  mux_data_r = din[7:0];
                4'd1:  mux_data_r = din[15:8];
                4'd2:  mux_data_r = din[23:16];
                4'd3:  mux_data_r = din[31:24];
                4'd4:  mux_data_r = din[39:32];
                4'd5:  mux_data_r = din[47:40];
                4'd6:  mux_data_r = din[55:48];
                4'd7:  mux_data_r = din[63:56];
                4'd8:  mux_data_r = din[71:64];
                4'd9:  mux_data_r = din[79:72];
                4'd10: mux_data_r = din[87:80];
                4'd11: mux_data_r = din[95:88];
                4'd12: mux_data_r = din[103:96];
                4'd13: mux_data_r = din[111:104];
                4'd14: mux_data_r = din[119:112];
                4'd15: mux_data_r = din[127:120];
                default: mux_data_r = {DW{1'b0}};
            endcase
        end
        assign mux_out = mux_data_r;
    end else begin : gen_mux_generic
        reg [DW-1:0] mux_data_r;
        integer i;
        always @(*) begin
            mux_data_r = {DW{1'b0}};
            for (i = 0; i < 16; i = i + 1) begin
                if (sel == i[3:0])
                    mux_data_r = din[(i+1)*DW-1 -: DW];
            end
        end
        assign mux_out = mux_data_r;
    end
endgenerate

endmodule