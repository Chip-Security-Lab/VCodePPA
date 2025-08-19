//SystemVerilog
module atomic_regfile #(
    parameter DW = 64,
    parameter AW = 3
)(
    input clk,
    input start,
    input [AW-1:0] addr,
    input [DW-1:0] modify_mask,
    input [DW-1:0] modify_val,
    output [DW-1:0] original_val,
    output busy
);

reg [DW-1:0] mem [0:7];
reg [1:0] state;  // Reduced state bits
reg [DW-1:0] temp;
wire [DW-1:0] masked_val;

// Simplified state machine and logic
assign busy = |state;
assign masked_val = modify_val & modify_mask;
assign original_val = temp;

always @(posedge clk) begin
    case(state)
        2'b00: if (start) begin
            temp <= mem[addr];
            state <= 2'b01;
        end
        2'b01: begin
            mem[addr] <= (temp & ~modify_mask) | masked_val;
            state <= 2'b10;
        end
        2'b10: state <= 2'b00;
        default: state <= 2'b00;
    endcase
end

endmodule