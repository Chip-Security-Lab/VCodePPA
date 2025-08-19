//SystemVerilog
module error_detect_decoder (
    input [3:0] addr,
    output reg [7:0] select,
    output reg error
);

    // Decode address to select signal
    always @(*) begin
        case (addr)
            4'h0: select = 8'h01;
            4'h1: select = 8'h02;
            4'h2: select = 8'h04;
            4'h3: select = 8'h08;
            4'h4: select = 8'h10;
            4'h5: select = 8'h20;
            4'h6: select = 8'h40;
            4'h7: select = 8'h80;
            default: select = 8'h00;
        endcase
    end

    // Generate error signal for invalid addresses
    always @(*) begin
        error = (addr > 4'h7);
    end

endmodule