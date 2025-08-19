module parallel_to_serial #(
    parameter DATA_WIDTH = 8
)(
    input wire clock, reset, load,
    input wire [DATA_WIDTH-1:0] parallel_data,
    output wire serial_out,
    output wire tx_done
);
    reg [DATA_WIDTH-1:0] shift_reg;
    reg [$clog2(DATA_WIDTH)-1:0] bit_counter;
    
    always @(posedge clock) begin
        if (reset) begin
            shift_reg <= 0;
            bit_counter <= DATA_WIDTH - 1;
        end else if (load) begin
            shift_reg <= parallel_data;
            bit_counter <= 0;
        end else if (bit_counter < DATA_WIDTH) begin
            shift_reg <= {shift_reg[DATA_WIDTH-2:0], 1'b0};
            bit_counter <= bit_counter + 1'b1;
        end
    end
    
    assign serial_out = shift_reg[DATA_WIDTH-1];
    assign tx_done = (bit_counter == DATA_WIDTH);
endmodule