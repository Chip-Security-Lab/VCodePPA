//SystemVerilog
module data_driven_shifter #(parameter WIDTH = 8) (
    input wire clk, rst,
    input wire data_valid,
    input wire serial_in,
    output wire [WIDTH-1:0] parallel_out
);
    reg [WIDTH-1:0] shift_data;
    reg [WIDTH-1:0] shift_data_pipe;
    reg [1:0] state;
    reg [1:0] state_pipe;
    wire shift_en;
    
    // Control logic
    assign shift_en = data_valid & ~rst;
    
    // Pipeline stage 1
    always @(posedge clk) begin
        if (rst) begin
            shift_data_pipe <= 0;
            state_pipe <= 2'b00;
        end else if (shift_en) begin
            shift_data_pipe <= {shift_data[WIDTH-2:0], serial_in};
            state_pipe <= 2'b01;
        end else begin
            shift_data_pipe <= shift_data;
            state_pipe <= state;
        end
    end
    
    // Pipeline stage 2
    always @(posedge clk) begin
        shift_data <= shift_data_pipe;
        state <= state_pipe;
    end
    
    assign parallel_out = shift_data;
endmodule