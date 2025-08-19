//SystemVerilog
module sync_4input_mux (
    input wire clk,                    // Clock input
    input wire [3:0] data_inputs,      // 4 single-bit inputs  
    input wire [1:0] addr,             // Address selection
    output reg mux_output              // Registered output
);
    always @(posedge clk) begin
        if (addr == 2'b00) begin
            mux_output <= data_inputs[0];
        end else if (addr == 2'b01) begin
            mux_output <= data_inputs[1];
        end else if (addr == 2'b10) begin
            mux_output <= data_inputs[2];
        end else begin // addr == 2'b11
            mux_output <= data_inputs[3];
        end
    end
endmodule