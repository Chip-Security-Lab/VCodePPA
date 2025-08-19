//SystemVerilog
module sync_single_port_ram_with_byte_enable #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 8
)(
    input wire clk,
    input wire rst,
    input wire we,
    input wire [ADDR_WIDTH-1:0] addr,
    input wire [DATA_WIDTH-1:0] din,
    input wire [DATA_WIDTH/8-1:0] byte_en,
    output reg [DATA_WIDTH-1:0] dout
);

    reg [DATA_WIDTH-1:0] ram [(2**ADDR_WIDTH)-1:0];
    reg [1:0] state;
    localparam IDLE = 2'b00;
    localparam WRITE = 2'b01;
    localparam READ = 2'b10;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= IDLE;
            dout <= 0;
        end else begin
            case (state)
                IDLE: begin
                    if (we) begin
                        state <= WRITE;
                    end else begin
                        state <= READ;
                    end
                end
                WRITE: begin
                    for (int i = 0; i < DATA_WIDTH / 8; i = i + 1) begin
                        if (byte_en[i]) begin
                            ram[addr][i*8 +: 8] <= din[i*8 +: 8];
                        end
                    end
                    state <= READ;
                end
                READ: begin
                    dout <= ram[addr];
                    state <= IDLE;
                end
                default: state <= IDLE;
            endcase
        end
    end
endmodule