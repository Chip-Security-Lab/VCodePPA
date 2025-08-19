//SystemVerilog
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

// Buffers for high fanout signals
reg [WIDTH-1:0] current_buf;
reg [3:0] byte_en_buf;
reg [ADDRW-1:0] addr_buf;
reg [WIDTH-1:0] din_buf;

always @(posedge clk) begin
    if (rst) begin
        for (integer i = 0; i < (1 << ADDRW); i = i + 1) begin
            reg_bank[i] <= 0;
        end
    end else begin
        // Buffering high fanout signals
        current_buf <= reg_bank[addr_buf];
        byte_en_buf <= byte_en;
        din_buf <= din;

        if (byte_en_buf[3]) begin
            reg_bank[addr_buf][31:24] <= din_buf[31:24];
        end else begin
            reg_bank[addr_buf][31:24] <= current_buf[31:24];
        end

        if (byte_en_buf[2]) begin
            reg_bank[addr_buf][23:16] <= din_buf[23:16];
        end else begin
            reg_bank[addr_buf][23:16] <= current_buf[23:16];
        end

        if (byte_en_buf[1]) begin
            reg_bank[addr_buf][15:8] <= din_buf[15:8];
        end else begin
            reg_bank[addr_buf][15:8] <= current_buf[15:8];
        end

        if (byte_en_buf[0]) begin
            reg_bank[addr_buf][7:0] <= din_buf[7:0];
        end else begin
            reg_bank[addr_buf][7:0] <= current_buf[7:0];
        end
    end
end

assign dout = reg_bank[addr];
endmodule