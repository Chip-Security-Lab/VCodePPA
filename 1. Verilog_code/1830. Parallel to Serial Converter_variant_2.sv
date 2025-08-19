//SystemVerilog
module parallel2serial #(parameter DATA_WIDTH = 8) (
    input  wire                  clk,
    input  wire                  rst,
    input  wire                  valid_in,
    input  wire [DATA_WIDTH-1:0] parallel_data,
    output wire                  ready,
    output reg                   serial_out,
    output wire                  valid_out
);
    reg [DATA_WIDTH-1:0] shift_reg;
    reg [$clog2(DATA_WIDTH):0] bit_count;
    reg busy;
    
    wire load_data = valid_in && ready;
    wire shift_en = bit_count > 0;
    wire last_bit = bit_count == 1;
    
    assign ready = ~busy;
    assign valid_out = shift_en;
    
    always @(posedge clk) begin
        if (rst) begin
            shift_reg <= 0;
            bit_count <= 0;
            serial_out <= 0;
            busy <= 0;
        end else if (load_data) begin
            shift_reg <= parallel_data;
            bit_count <= DATA_WIDTH;
            busy <= 1;
        end else if (shift_en) begin
            serial_out <= shift_reg[DATA_WIDTH-1];
            shift_reg <= {shift_reg[DATA_WIDTH-2:0], 1'b0};
            bit_count <= bit_count - 1;
            busy <= ~last_bit;
        end
    end
endmodule