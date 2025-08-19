//SystemVerilog
module sync_1to8_demux (
    input wire clock,                   // System clock
    input wire data,                    // Input data
    input wire [2:0] address,           // 3-bit address
    output reg [7:0] outputs            // 8 registered outputs
);
    reg [2:0] address_reg;
    reg data_reg;

    always @(posedge clock) begin
        address_reg <= address;
        data_reg <= data;
    end

    always @(posedge clock) begin
        outputs <= 8'b0;
        if (data_reg && (address_reg < 3'd8)) begin
            outputs[address_reg] <= 1'b1;
        end
    end

endmodule