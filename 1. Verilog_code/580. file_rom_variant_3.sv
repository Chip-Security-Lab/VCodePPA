//SystemVerilog
module file_rom (
    input clk,
    input rst_n,
    input [3:0] addr,
    input valid,
    output reg ready,
    output reg [7:0] data
);
    reg [7:0] rom [0:15];
    reg [7:0] data_reg;
    reg valid_reg;
    reg [1:0] state;

    localparam IDLE = 2'b00;
    localparam READ = 2'b01;
    localparam WAIT = 2'b10;

    initial begin
        $readmemh("rom_data.hex", rom);
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            ready <= 1'b0;
            data <= 8'h0;
            data_reg <= 8'h0;
        end else begin
            case (state)
                IDLE: begin
                    ready <= 1'b1;
                    if (valid) begin
                        data_reg <= rom[addr];
                        state <= READ;
                    end
                end
                READ: begin
                    ready <= 1'b0;
                    data <= data_reg;
                    state <= WAIT;
                end
                WAIT: begin
                    if (!valid) begin
                        state <= IDLE;
                    end
                end
            endcase
        end
    end
endmodule