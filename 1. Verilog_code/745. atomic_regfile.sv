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
reg [2:0] state;
reg [DW-1:0] temp;

assign busy = (state != 0);

always @(posedge clk) begin
    case(state)
        0: if (start) begin
            temp <= mem[addr];
            state <= 1;
        end
        1: begin
            mem[addr] <= (temp & ~modify_mask) | modify_val;
            state <= 2;
        end
        2: state <= 0;
    endcase
end

assign original_val = temp;
endmodule