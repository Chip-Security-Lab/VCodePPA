//SystemVerilog
module decoder_2to4 #(
    parameter WIDTH = 2
)(
    input [WIDTH-1:0] addr,
    output reg [3:0] decoded
);
    // Decode logic split into two always blocks for better timing
    always @(*) begin
        case(addr)
            2'b00: decoded = 4'b0001;
            2'b01: decoded = 4'b0010;
            2'b10: decoded = 4'b0100;
            2'b11: decoded = 4'b1000;
            default: decoded = 4'b0000;
        endcase
    end
endmodule

module data_selector #(
    parameter WIDTH = 16
)(
    input [WIDTH-1:0] data_array [0:3],
    input [3:0] decoded,
    output [WIDTH-1:0] selected_data
);
    // Split selection logic into parallel paths
    wire [WIDTH-1:0] data0, data1, data2, data3;
    
    assign data0 = decoded[0] ? data_array[0] : {WIDTH{1'b0}};
    assign data1 = decoded[1] ? data_array[1] : {WIDTH{1'b0}};
    assign data2 = decoded[2] ? data_array[2] : {WIDTH{1'b0}};
    assign data3 = decoded[3] ? data_array[3] : {WIDTH{1'b0}};
    
    assign selected_data = data0 | data1 | data2 | data3;
endmodule

module decoded_addr_mux #(
    parameter WIDTH = 16
)(
    input [WIDTH-1:0] data_array [0:3],
    input [1:0] addr,
    output [WIDTH-1:0] selected_data
);
    wire [3:0] decoded;
    
    decoder_2to4 #(
        .WIDTH(2)
    ) decoder_inst (
        .addr(addr),
        .decoded(decoded)
    );
    
    data_selector #(
        .WIDTH(WIDTH)
    ) selector_inst (
        .data_array(data_array),
        .decoded(decoded),
        .selected_data(selected_data)
    );
endmodule