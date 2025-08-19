module regfile_byteen #(
    parameter WIDTH = 32,
    parameter ADDRW = 4
)(
    input clk,
    input rst,
    input [3:0] byte_en,
    input [ADDRW-1:0] addr,
    input [WIDTH-1:0] din,
    output [WIDTH-1:0] dout
);
reg [WIDTH-1:0] reg_bank [0:(1<<ADDRW)-1];
wire [WIDTH-1:0] current = reg_bank[addr];
integer i;

always @(posedge clk) begin
    if (rst) begin
        for (i=0; i<(1<<ADDRW); i=i+1) reg_bank[i] <= 0;
    end else begin
        reg_bank[addr] <= {
            byte_en[3] ? din[31:24] : current[31:24],
            byte_en[2] ? din[23:16] : current[23:16],
            byte_en[1] ? din[15:8] : current[15:8],
            byte_en[0] ? din[7:0] : current[7:0]
        };
    end
end

assign dout = reg_bank[addr];
endmodule