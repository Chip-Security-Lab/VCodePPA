//SystemVerilog
module demux_with_default (
    input wire data_in,                  // Input data
    input wire [2:0] sel_addr,           // Selection address
    output reg [6:0] outputs,            // Normal outputs
    output reg default_out               // Default output for invalid addresses
);
    always @(*) begin
        outputs = 7'b0;
        default_out = 1'b0;
        if (sel_addr < 3'd7) begin
            outputs = data_in << sel_addr;
        end else begin
            default_out = data_in;
        end
    end
endmodule