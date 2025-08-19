module decoded_addr_mux #(
    parameter WIDTH = 16
)(
    input [WIDTH-1:0] data_array [0:3],
    input [1:0] addr,
    output [WIDTH-1:0] selected_data
);
    reg [3:0] decoded;
    
    always @(*) begin
        decoded = 4'b0000;
        decoded[addr] = 1'b1;
    end
    
    assign selected_data = decoded[0] ? data_array[0] :
                           decoded[1] ? data_array[1] :
                           decoded[2] ? data_array[2] :
                           data_array[3];
endmodule