module PriorityRecovery #(parameter WIDTH=8, SOURCES=4) (
    input clk,
    input [SOURCES-1:0] valid,
    input [WIDTH*SOURCES-1:0] data_bus,
    output reg [WIDTH-1:0] selected_data
);
    always @(posedge clk) begin
        casex (valid)
            4'b1xxx: selected_data <= data_bus[WIDTH*3 +: WIDTH];
            4'b01xx: selected_data <= data_bus[WIDTH*2 +: WIDTH];
            4'b001x: selected_data <= data_bus[WIDTH*1 +: WIDTH];
            4'b0001: selected_data <= data_bus[WIDTH*0 +: WIDTH];
            default: selected_data <= 0;
        endcase
    end
endmodule
