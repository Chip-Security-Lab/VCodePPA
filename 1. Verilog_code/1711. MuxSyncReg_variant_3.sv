//SystemVerilog
module MuxSyncReg #(parameter W=8, N=4) (
    input clk, rst_n,
    input [N-1:0][W-1:0] data_in,
    input [$clog2(N)-1:0] sel,
    output reg [W-1:0] data_out
);

// LUT-based subtraction helper
reg [W-1:0] lut_sub [0:255];
reg [W-1:0] lut_add [0:255];

// Initialize LUTs
integer i;
initial begin
    for (i = 0; i < 256; i = i + 1) begin
        lut_sub[i] = i;
        lut_add[i] = i;
    end
end

// Pipeline registers
reg [W-1:0] data_in_reg [N-1:0];
reg [$clog2(N)-1:0] sel_reg;
reg [W-1:0] data_out_reg;

// Pipeline stage 1 - Input registration
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        for (i = 0; i < N; i = i + 1) begin
            data_in_reg[i] <= 0;
        end
        sel_reg <= 0;
    end else begin
        for (i = 0; i < N; i = i + 1) begin
            data_in_reg[i] <= data_in[i];
        end
        sel_reg <= sel;
    end
end

// Pipeline stage 2 - LUT-based selection
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        data_out_reg <= 0;
    end else begin
        data_out_reg <= data_in_reg[sel_reg];
    end
end

// Pipeline stage 3 - Output registration
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        data_out <= 0;
    end else begin
        data_out <= data_out_reg;
    end
end

endmodule