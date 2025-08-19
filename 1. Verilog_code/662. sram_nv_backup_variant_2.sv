//SystemVerilog
module sram_nv_backup #(
    parameter DW = 8,
    parameter AW = 10
)(
    input clk,
    input power_good,
    input we,
    input [AW-1:0] addr,
    input [DW-1:0] din,
    output [DW-1:0] dout
);

reg [DW-1:0] volatile_mem [0:(1<<AW)-1];
reg [DW-1:0] nv_mem [0:(1<<AW)-1];
reg [AW-1:0] backup_idx;
reg backup_active;

always @(posedge clk) begin
    case ({!power_good, backup_active, we})
        3'b100: begin
            backup_active <= 1'b1;
            backup_idx <= {AW{1'b0}};
        end
        3'b010: begin
            volatile_mem[backup_idx] <= nv_mem[backup_idx];
            backup_idx <= backup_idx + 1'b1;
            if (backup_idx == {(AW){1'b1}}) begin
                backup_active <= 1'b0;
            end
        end
        3'b001: begin
            volatile_mem[addr] <= din;
            nv_mem[addr] <= din;
        end
        default: begin
            backup_active <= backup_active;
            backup_idx <= backup_idx;
        end
    endcase
end

assign dout = volatile_mem[addr];

endmodule