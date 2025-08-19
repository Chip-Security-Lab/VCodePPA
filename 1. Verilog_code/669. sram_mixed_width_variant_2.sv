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
reg [MAX_WIDTH-1:0] read_data_p1, read_data_p2;
reg [AW+$clog2(BYTE_NUM)-1:0] base_addr_p1;
reg [1:0] width_mode_p1;
integer i;

// Address generation logic for byte-addressable memory
wire [AW+$clog2(BYTE_NUM)-1:0] base_addr;
assign base_addr = {addr, {$clog2(BYTE_NUM){1'b0}}};

// Pipeline stage 1: Address and control signal registration
always @(posedge clk) begin
    base_addr_p1 <= base_addr;
    width_mode_p1 <= width_mode;
end

// Write operation handling
always @(posedge clk) begin
    if (we) begin
        case(width_mode)
            2'b00: begin
                for (i = 0; i < 8; i = i + 1) begin
                    mem[base_addr + i] <= din[63-i*8 -: 8];
                end
            end
            2'b01: begin
                for (i = 0; i < 4; i = i + 1) begin
                    mem[base_addr + i] <= din[31-i*8 -: 8];
                end
            end
            2'b10: begin
                for (i = 0; i < 2; i = i + 1) begin
                    mem[base_addr + i] <= din[15-i*8 -: 8];
                end
            end
            2'b11: begin
                mem[base_addr] <= din[7:0];
            end
        endcase
    end
end

// Read operation handling - Pipeline stage 1
always @(posedge clk) begin
    read_data_p1 = 0;
    
    case(width_mode_p1)
        2'b00: begin
            for (i = 0; i < 4; i = i + 1) begin
                read_data_p1[63-i*8 -: 8] = mem[base_addr_p1 + i];
            end
        end
        2'b01: begin
            for (i = 0; i < 2; i = i + 1) begin
                read_data_p1[31-i*8 -: 8] = mem[base_addr_p1 + i];
            end
        end
        2'b10: begin
            read_data_p1[15:0] = mem[base_addr_p1];
        end
        2'b11: begin
            read_data_p1[7:0] = mem[base_addr_p1];
        end
    endcase
end

// Read operation handling - Pipeline stage 2
always @(posedge clk) begin
    read_data_p2 = 0;
    
    case(width_mode_p1)
        2'b00: begin
            for (i = 4; i < 8; i = i + 1) begin
                read_data_p2[63-i*8 -: 8] = mem[base_addr_p1 + i];
            end
        end
        2'b01: begin
            for (i = 2; i < 4; i = i + 1) begin
                read_data_p2[31-i*8 -: 8] = mem[base_addr_p1 + i];
            end
        end
        2'b10: begin
            read_data_p2[15:8] = mem[base_addr_p1 + 1];
        end
        2'b11: begin
            read_data_p2[7:0] = read_data_p1[7:0];
        end
    endcase
end

assign dout = (width_mode_p1 == 2'b00) ? {read_data_p2, read_data_p1} :
              (width_mode_p1 == 2'b01) ? {read_data_p2[15:0], read_data_p1[31:0]} :
              (width_mode_p1 == 2'b10) ? {read_data_p2[7:0], read_data_p1[15:0]} :
              read_data_p1[7:0];

endmodule