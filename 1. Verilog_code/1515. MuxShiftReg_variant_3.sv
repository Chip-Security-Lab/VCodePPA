//SystemVerilog
module MuxShiftReg #(parameter DEPTH=4, WIDTH=8) (
    input clk,
    input [1:0] sel,
    input [WIDTH-1:0] din,
    output reg [WIDTH-1:0] dout
);

reg [WIDTH-1:0] regs [0:DEPTH-1];
reg [1:0] sel_reg;
reg [1:0] sel_sub_reg;
reg [1:0] sel_add_reg;
reg [1:0] sel_rot_reg;
reg [1:0] sel_hold_reg;

wire [1:0] sel_sub;
wire [1:0] sel_add;
wire [1:0] sel_rot;
wire [1:0] sel_hold;

// Register input selection signals
always @(posedge clk) begin
    sel_reg <= sel;
end

// Look-ahead carry subtractor for sel calculation with registered outputs
assign sel_sub[1] = ~sel_reg[1] & ~sel_reg[0];
assign sel_sub[0] = sel_reg[1] & ~sel_reg[0];
assign sel_add[1] = ~sel_reg[1] & sel_reg[0];
assign sel_add[0] = sel_reg[1] & sel_reg[0];
assign sel_rot[1] = sel_reg[1] & ~sel_reg[0];
assign sel_rot[0] = ~sel_reg[1] & sel_reg[0];
assign sel_hold[1] = sel_reg[1] & sel_reg[0];
assign sel_hold[0] = ~sel_reg[1] & ~sel_reg[0];

// Register control signals
always @(posedge clk) begin
    sel_sub_reg <= sel_sub;
    sel_add_reg <= sel_add;
    sel_rot_reg <= sel_rot;
    sel_hold_reg <= sel_hold;
end

integer i;

always @(posedge clk) begin
    if (sel_sub_reg[1]) begin  // Shift left
        for (i=DEPTH-1; i>0; i=i-1)
            regs[i] <= regs[i-1];
        regs[0] <= din;
    end
    else if (sel_add_reg[1]) begin  // Shift right
        for (i=0; i<DEPTH-1; i=i+1)
            regs[i] <= regs[i+1];
        regs[DEPTH-1] <= din;
    end
    else if (sel_rot_reg[1]) begin  // Rotate right
        for (i=0; i<DEPTH-1; i=i+1)
            regs[i] <= regs[i+1];
        regs[DEPTH-1] <= regs[0];
    end
    else begin  // Hold values
        for (i=0; i<DEPTH; i=i+1)
            regs[i] <= regs[i];
    end
    dout <= regs[DEPTH-1];
end

endmodule