//SystemVerilog
module Par2SerMux #(parameter DW=8) (
    input  wire              clk,
    input  wire              rst_n,
    input  wire              load,
    input  wire [DW-1:0]     par_in,
    output wire              ser_out,
    output wire              valid_out
);

// Stage 1: Combination logic for parallel input loading and shifting
wire [DW-1:0] shift_reg_stage1_next;
wire          valid_stage1_next;

assign shift_reg_stage1_next = load ? par_in :
                               valid_stage1_reg ? {1'b0, shift_reg_stage1_reg[DW-1:1]} :
                               shift_reg_stage1_reg;

assign valid_stage1_next = load ? 1'b1 :
                           valid_stage1_reg ? |shift_reg_stage1_reg[DW-1:1] :
                           1'b0;

// Stage 2: Registers moved after combination logic (forward retiming)
reg [DW-1:0] shift_reg_stage1_reg;
reg          valid_stage1_reg;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        shift_reg_stage1_reg <= {DW{1'b0}};
        valid_stage1_reg     <= 1'b0;
    end else begin
        shift_reg_stage1_reg <= shift_reg_stage1_next;
        valid_stage1_reg     <= valid_stage1_next;
    end
end

// Stage 3: Register serial output and valid, unchanged
reg        ser_out_reg;
reg        valid_out_reg;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        ser_out_reg   <= 1'b0;
        valid_out_reg <= 1'b0;
    end else begin
        ser_out_reg   <= shift_reg_stage1_next[0];
        valid_out_reg <= valid_stage1_next;
    end
end

assign ser_out   = ser_out_reg;
assign valid_out = valid_out_reg;

endmodule