module sram_mixed_width #(
    parameter MAX_WIDTH = 64,
    parameter AW = 5
)(
    input clk,
    input [1:0] width_mode, // 00:64b, 01:32b, 10:16b, 11:8b
    input we,
    input [AW-1:0] addr,
    input [MAX_WIDTH-1:0] din,
    output [MAX_WIDTH-1:0] dout
);
localparam BYTE_NUM = MAX_WIDTH/8;
reg [7:0] mem [0:(1<<AW)*BYTE_NUM-1];
reg [MAX_WIDTH-1:0] read_data;
integer i;

// Address generation logic for byte-addressable memory
wire [AW+$clog2(BYTE_NUM)-1:0] base_addr;
assign base_addr = {addr, {$clog2(BYTE_NUM){1'b0}}};

// Write operation handling
always @(posedge clk) begin
    if (we) begin
        case(width_mode)
            2'b00: begin // 64-bit mode
                for (i = 0; i < 8; i = i + 1) begin
                    mem[base_addr + i] <= din[63-i*8 -: 8];
                end
            end
            2'b01: begin // 32-bit mode
                for (i = 0; i < 4; i = i + 1) begin
                    mem[base_addr + i] <= din[31-i*8 -: 8];
                end
            end
            2'b10: begin // 16-bit mode
                for (i = 0; i < 2; i = i + 1) begin
                    mem[base_addr + i] <= din[15-i*8 -: 8];
                end
            end
            2'b11: begin // 8-bit mode
                mem[base_addr] <= din[7:0];
            end
        endcase
    end
end

// Read operation handling
always @(posedge clk) begin
    read_data = 0; // Default value
    
    case(width_mode)
        2'b00: begin // 64-bit mode
            for (i = 0; i < 8; i = i + 1) begin
                read_data[63-i*8 -: 8] = mem[base_addr + i];
            end
        end
        2'b01: begin // 32-bit mode
            for (i = 0; i < 4; i = i + 1) begin
                read_data[31-i*8 -: 8] = mem[base_addr + i];
            end
        end
        2'b10: begin // 16-bit mode
            for (i = 0; i < 2; i = i + 1) begin
                read_data[15-i*8 -: 8] = mem[base_addr + i];
            end
        end
        2'b11: begin // 8-bit mode
            read_data[7:0] = mem[base_addr];
        end
    endcase
end

assign dout = read_data;

endmodule