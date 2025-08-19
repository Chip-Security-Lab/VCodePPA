module sync_4input_mux (
    input wire clk,                // Clock input
    input wire [3:0] data_inputs,  // 4 single-bit inputs  
    input wire [1:0] addr,         // Address selection
    output reg mux_output          // Registered output
);
    always @(posedge clk) begin
        case(addr)
            2'b00: mux_output <= data_inputs[0];
            2'b01: mux_output <= data_inputs[1];
            2'b10: mux_output <= data_inputs[2];
            2'b11: mux_output <= data_inputs[3];
        endcase
    end
endmodule