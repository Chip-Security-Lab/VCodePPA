//SystemVerilog
module hybrid_rom (
    input clk,
    input req,
    input [3:0] addr,
    input [7:0] din,
    output reg ack,
    output reg [7:0] data
);
    reg [7:0] rom [0:7];
    reg [7:0] ram [8:15];
    wire is_rom_access;
    wire is_ram_access;
    reg req_reg;
    reg we_reg;

    initial begin
        rom[0] = 8'hEE; rom[1] = 8'hFF;
    end

    assign is_rom_access = ~addr[3];
    assign is_ram_access = addr[3];

    always @(posedge clk) begin
        req_reg <= req;
        we_reg <= req_reg;
        
        if(req_reg) begin
            case({is_rom_access, is_ram_access, we_reg})
                3'b100: data <= rom[addr[2:0]];
                3'b011: ram[addr[3:0]] <= din;
                3'b010: data <= ram[addr[3:0]];
                default: data <= data;
            endcase
            ack <= 1'b1;
        end else begin
            ack <= 1'b0;
        end
    end
endmodule