module pipelined_mux (
    input wire clk,               // System clock
    input wire [1:0] address,     // Selection address
    input wire [15:0] data_0, data_1, data_2, data_3, // Data inputs
    output reg [15:0] result      // Registered result
);
    reg [15:0] selected_data;     // Pipeline register
    
    always @(*) begin
        case(address)
            2'b00: selected_data = data_0;
            2'b01: selected_data = data_1;
            2'b10: selected_data = data_2;
            2'b11: selected_data = data_3;
        endcase
    end
    
    always @(posedge clk) begin
        result <= selected_data;  // Output pipeline stage
    end
endmodule