//SystemVerilog
module rom_based_mult (
    input [3:0] addr_a,
    input [3:0] addr_b,
    output reg [7:0] product
);

    always @(*) begin
        if (addr_a == 4'h0) begin
            product = 8'h00;
        end else begin
            case (addr_a)
                4'h1: product = {4'h0, addr_b};
                4'h2: product = {addr_b, 1'b0};
                4'h3: product = {4'h0, addr_b} + {addr_b, 1'b0};
                4'h4: product = {addr_b, 2'b00};
                4'h5: product = {4'h0, addr_b} + {addr_b, 2'b00};
                4'h6: product = {addr_b, 1'b0} + {addr_b, 2'b00};
                4'h7: product = {4'h0, addr_b} + {addr_b, 1'b0} + {addr_b, 2'b00};
                4'h8: product = {addr_b, 3'b000};
                4'h9: product = {4'h0, addr_b} + {addr_b, 3'b000};
                4'hA: product = {addr_b, 1'b0} + {addr_b, 3'b000};
                4'hB: product = {4'h0, addr_b} + {addr_b, 1'b0} + {addr_b, 3'b000};
                4'hC: product = {addr_b, 2'b00} + {addr_b, 3'b000};
                4'hD: product = {4'h0, addr_b} + {addr_b, 2'b00} + {addr_b, 3'b000};
                4'hE: product = {addr_b, 1'b0} + {addr_b, 2'b00} + {addr_b, 3'b000};
                default: product = {4'h0, addr_b} + {addr_b, 1'b0} + {addr_b, 2'b00} + {addr_b, 3'b000};
            endcase
        end
    end
endmodule