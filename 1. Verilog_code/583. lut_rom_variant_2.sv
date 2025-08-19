//SystemVerilog
module lut_rom (
    input clk,
    input rst_n,
    input [3:0] addr,
    input req,
    output reg ack,
    output reg [7:0] data
);

    reg [7:0] rom_data;
    reg req_reg;
    
    // ROM lookup logic
    always @(*) begin
        case (addr)
            4'h0: rom_data = 8'hA1;
            4'h1: rom_data = 8'hB2;
            4'h2: rom_data = 8'hC3;
            4'h3: rom_data = 8'hD4;
            4'h4: rom_data = 8'hE5;
            4'h5: rom_data = 8'hF6;
            4'h6: rom_data = 8'h07;
            4'h7: rom_data = 8'h18;
            default: rom_data = 8'h00;
        endcase
    end

    // Request-acknowledge handshake logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ack <= 1'b0;
            data <= 8'h00;
            req_reg <= 1'b0;
        end else begin
            req_reg <= req;
            
            if (req && !req_reg) begin
                data <= rom_data;
                ack <= 1'b1;
            end else if (!req) begin
                ack <= 1'b0;
            end
        end
    end

endmodule