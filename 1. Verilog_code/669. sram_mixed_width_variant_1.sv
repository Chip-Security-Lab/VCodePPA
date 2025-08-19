//SystemVerilog
module sram_mixed_width #(
    parameter MAX_WIDTH = 64,
    parameter AW = 5
)(
    input clk,
    input [1:0] width_mode,
    input we,
    input [AW-1:0] addr,
    input [MAX_WIDTH-1:0] din,
    output [MAX_WIDTH-1:0] dout
);

localparam BYTE_NUM = MAX_WIDTH/8;
reg [7:0] mem [0:(1<<AW)*BYTE_NUM-1];
reg [MAX_WIDTH-1:0] read_data_reg;

// Address generation logic
wire [AW+$clog2(BYTE_NUM)-1:0] base_addr;
assign base_addr = {addr, {$clog2(BYTE_NUM){1'b0}}};

// Write data generation
wire [7:0] write_data [0:BYTE_NUM-1];
generate
    genvar i;
    for (i = 0; i < BYTE_NUM; i = i + 1) begin : write_data_gen
        assign write_data[i] = din[i*8 +: 8];
    end
endgenerate

// Write operation
always @(posedge clk) begin
    if (we) begin
        case(width_mode)
            2'b00: begin // 64-bit mode
                for (int i = 0; i < 8; i = i + 1)
                    mem[base_addr + i] <= write_data[i];
            end
            2'b01: begin // 32-bit mode
                for (int i = 0; i < 4; i = i + 1)
                    mem[base_addr + i] <= write_data[i];
            end
            2'b10: begin // 16-bit mode
                for (int i = 0; i < 2; i = i + 1)
                    mem[base_addr + i] <= write_data[i];
            end
            2'b11: begin // 8-bit mode
                mem[base_addr] <= write_data[0];
            end
        endcase
    end
end

// Read data generation
wire [MAX_WIDTH-1:0] read_data_comb;
generate
    for (i = 0; i < BYTE_NUM; i = i + 1) begin : read_data_gen
        assign read_data_comb[i*8 +: 8] = mem[base_addr + i];
    end
endgenerate

// Read operation
always @(posedge clk) begin
    read_data_reg <= read_data_comb;
end

// Output assignment
assign dout = read_data_reg;

endmodule