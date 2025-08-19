//SystemVerilog
module hybrid_rom (
    input clk,
    input valid,
    output reg ready,
    input [3:0] addr,
    input [7:0] din,
    output reg [7:0] data
);
    reg [7:0] rom [0:7];
    reg [7:0] ram [8:15];
    wire is_rom_addr;
    wire is_ram_addr;
    reg [1:0] state;
    reg [7:0] next_data;
    reg next_ready;

    localparam IDLE = 2'b00;
    localparam READ_ROM = 2'b01;
    localparam READ_RAM = 2'b10;
    localparam WRITE_RAM = 2'b11;

    initial begin
        rom[0] = 8'hEE; 
        rom[1] = 8'hFF;
        state = IDLE;
        ready = 1'b0;
    end

    assign is_rom_addr = ~addr[3];
    assign is_ram_addr = addr[3];

    always @(*) begin
        case(state)
            IDLE: begin
                next_ready = 1'b1;
                next_data = data;
            end
            READ_ROM: begin
                next_ready = 1'b1;
                next_data = rom[addr[2:0]];
            end
            READ_RAM: begin
                next_ready = 1'b1;
                next_data = ram[addr[2:0]];
            end
            WRITE_RAM: begin
                next_ready = 1'b1;
                next_data = data;
            end
            default: begin
                next_ready = 1'b0;
                next_data = data;
            end
        endcase
    end

    always @(posedge clk) begin
        case(state)
            IDLE: begin
                if (valid) begin
                    if (is_rom_addr) begin
                        state <= READ_ROM;
                    end else if (is_ram_addr) begin
                        state <= READ_RAM;
                    end
                end
            end
            READ_ROM: begin
                state <= IDLE;
            end
            READ_RAM: begin
                state <= IDLE;
            end
            WRITE_RAM: begin
                state <= IDLE;
            end
        endcase

        data <= next_data;
        ready <= next_ready;

        if (state == WRITE_RAM) begin
            ram[addr[2:0]] <= din;
        end
    end
endmodule